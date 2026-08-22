import crypto from 'node:crypto';
import OpenAI from 'openai';
import { createClient } from '@supabase/supabase-js';

const buckets = globalThis.__routeVisionBuckets ?? new Map();
globalThis.__routeVisionBuckets = buckets;

function safeEqual(a, b) {
  const left = Buffer.from(a || '');
  const right = Buffer.from(b || '');
  return left.length === right.length && crypto.timingSafeEqual(left, right);
}

function validateImage(image) {
  if (!image || typeof image !== 'object') return false;
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(image.mimeType)) return false;
  if (typeof image.base64 !== 'string' || image.base64.length < 32) return false;
  if (image.base64.length > 8_500_000) return false;
  return true;
}

function clampScore(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(5, Math.round(n)));
}

function extractJson(text) {
  const trimmed = String(text || '').trim();
  try { return JSON.parse(trimmed); } catch (_) {}
  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start < 0 || end <= start) throw new Error('Model did not return JSON');
  return JSON.parse(trimmed.slice(start, end + 1));
}

function normalize(result) {
  return {
    routeSpread: clampScore(result.routeSpread),
    rurality: clampScore(result.rurality),
    clustering: clampScore(result.clustering),
    backtrackingRisk: clampScore(result.backtrackingRisk),
    accessComplexity: clampScore(result.accessComplexity),
    estimatedAverageDriveMinutes: Number.isFinite(Number(result.estimatedAverageDriveMinutes))
      ? Math.max(0, Math.min(30, Number(result.estimatedAverageDriveMinutes)))
      : null,
    likelyRouteType: typeof result.likelyRouteType === 'string' ? result.likelyRouteType.slice(0, 80) : 'Mixed',
    summary: typeof result.summary === 'string' ? result.summary.slice(0, 900) : '',
    confidence: Math.max(0, Math.min(1, Number(result.confidence) || 0)),
    signals: Array.isArray(result.signals)
      ? result.signals.filter((x) => typeof x === 'string').slice(0, 8).map((x) => x.slice(0, 180))
      : [],
  };
}

function buildPrompt(ocrText) {
  return `Analyze delivery-route screenshots as operational evidence. Focus on what is visually supported by the maps and route overview, not on guessing hidden addresses. Return ONLY one JSON object with these keys: routeSpread (0-5), rurality (0-5), clustering (0-5), backtrackingRisk (0-5), accessComplexity (0-5), estimatedAverageDriveMinutes (number or null), likelyRouteType (string), summary (string), confidence (0-1), signals (array of short strings).\n\nScoring anchors: routeSpread 0=tight compact cluster, 5=very geographically dispersed; rurality 0=dense urban/suburban, 5=strong rural/long-road pattern; clustering 0=scattered, 5=strong dense clusters; backtrackingRisk 0=route appears sequential, 5=obvious crossing/revisiting pattern; accessComplexity reflects visible apartments/business campuses/gated or dense multi-stop structures. Do not infer exact distances unless clearly visible. State uncertainty in confidence. OCR text may help identify route context but map geometry should drive geographic scores.\n\nOCR text:\n${ocrText}`;
}

function clientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) return forwarded.split(',')[0].trim();
  return req.socket?.remoteAddress || 'unknown';
}

function allowRequest(key, limit) {
  const now = Date.now();
  const windowMs = 60_000;
  const current = buckets.get(key);
  if (!current || now - current.startedAt >= windowMs) {
    buckets.set(key, { startedAt: now, count: 1 });
    return true;
  }
  if (current.count >= limit) return false;
  current.count += 1;
  return true;
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  let supabase;
  let user;
  let quota;
  try {
    const openaiKey = requiredEnv('OPENAI_API_KEY');
    const clientToken = requiredEnv('ROUTE_VISION_CLIENT_TOKEN');
    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const serviceRoleKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');

    const appToken = req.headers['x-rpt-client-token'] || '';
    if (!safeEqual(String(appToken), clientToken)) return res.status(401).json({ error: 'app_unauthorized' });

    const authHeader = req.headers.authorization || '';
    const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    if (!accessToken) return res.status(401).json({ error: 'account_required' });

    supabase = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: userData, error: userError } = await supabase.auth.getUser(accessToken);
    user = userData?.user;
    if (userError || !user) return res.status(401).json({ error: 'account_unauthorized' });

    const limit = Math.max(1, Number(process.env.RATE_LIMIT_PER_MINUTE || 12));
    if (!allowRequest(`${user.id}:${clientIp(req)}`, limit)) {
      res.setHeader('Retry-After', '60');
      return res.status(429).json({ error: 'rate_limited' });
    }

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const images = Array.isArray(body.images) ? body.images : [];
    const ocrText = typeof body.ocrText === 'string' ? body.ocrText.slice(0, 12_000) : '';
    if (images.length < 1 || images.length > 3 || !images.every(validateImage)) {
      return res.status(400).json({ error: 'invalid_images' });
    }

    const quotaResult = await supabase.rpc('consume_ai_analysis', { p_user_id: user.id });
    if (quotaResult.error) throw quotaResult.error;
    quota = quotaResult.data;
    if (!quota?.allowed) {
      return res.status(402).json({ error: 'free_ai_limit_reached', tier: 'free', used: Number(quota?.used || 3), limit: 3 });
    }

    const content = [{ type: 'input_text', text: buildPrompt(ocrText) }];
    for (const image of images) {
      content.push({ type: 'input_image', image_url: `data:${image.mimeType};base64,${image.base64}`, detail: 'high' });
    }

    const openai = new OpenAI({ apiKey: openaiKey });
    const response = await openai.responses.create({
      model: process.env.OPENAI_VISION_MODEL || 'gpt-5.4-mini',
      input: [{ role: 'user', content }],
      max_output_tokens: 900,
      store: false,
    });

    const normalized = normalize(extractJson(response.output_text));
    return res.status(200).json({
      ...normalized,
      usage: {
        tier: quota.tier || 'free',
        used: Number(quota.used || 0),
        limit: quota.limit == null ? null : Number(quota.limit),
      },
    });
  } catch (error) {
    if (supabase && user?.id && quota?.tier === 'free' && quota?.allowed) {
      try {
        await supabase.rpc('refund_ai_analysis', { p_user_id: user.id });
      } catch (_) {
        console.error('route-vision quota refund failed');
      }
    }
    console.error('route-vision failure', { name: error?.name, status: error?.status, requestId: error?.request_id });
    return res.status(503).json({ error: 'vision_not_configured_or_unavailable' });
  }
}
