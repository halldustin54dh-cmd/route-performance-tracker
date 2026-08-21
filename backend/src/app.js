import crypto from 'node:crypto';
import express from 'express';
import helmet from 'helmet';

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

function extractJson(text) {
  const trimmed = String(text || '').trim();
  try { return JSON.parse(trimmed); } catch (_) {}
  const start = trimmed.indexOf('{');
  const end = trimmed.lastIndexOf('}');
  if (start < 0 || end <= start) throw new Error('Model did not return JSON');
  return JSON.parse(trimmed.slice(start, end + 1));
}

function clampScore(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(5, Math.round(n)));
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

export function createApp({
  openai,
  clientToken,
  model = 'gpt-5.4-mini',
  rateLimitPerMinute = 12,
  trustProxy = false,
} = {}) {
  if (!openai) throw new Error('openai client is required');
  if (!clientToken || clientToken.length < 32) {
    throw new Error('clientToken must be at least 32 characters');
  }

  const app = express();
  const buckets = new Map();
  const windowMs = 60_000;

  app.disable('x-powered-by');
  if (trustProxy) app.set('trust proxy', 1);
  app.use(helmet());
  app.use(express.json({ limit: '28mb', strict: true }));

  function authorize(req, res, next) {
    const header = req.get('authorization') || '';
    const supplied = header.startsWith('Bearer ') ? header.slice(7) : '';
    if (!safeEqual(supplied, clientToken)) return res.status(401).json({ error: 'unauthorized' });
    next();
  }

  function rateLimit(req, res, next) {
    const key = req.ip || 'unknown';
    const now = Date.now();
    const current = buckets.get(key);
    if (!current || now - current.startedAt >= windowMs) {
      buckets.set(key, { startedAt: now, count: 1 });
      return next();
    }
    if (current.count >= rateLimitPerMinute) {
      res.set('Retry-After', '60');
      return res.status(429).json({ error: 'rate_limited' });
    }
    current.count += 1;
    next();
  }

  app.get('/healthz', (_req, res) => {
    res.set('Cache-Control', 'no-store');
    res.json({ ok: true });
  });

  app.post('/v1/route-vision', authorize, rateLimit, async (req, res) => {
    try {
      const images = Array.isArray(req.body?.images) ? req.body.images : [];
      const ocrText = typeof req.body?.ocrText === 'string' ? req.body.ocrText.slice(0, 12_000) : '';
      if (images.length < 1 || images.length > 6 || !images.every(validateImage)) {
        return res.status(400).json({ error: 'invalid_images' });
      }

      const content = [{ type: 'input_text', text: buildPrompt(ocrText) }];
      for (const image of images) {
        content.push({
          type: 'input_image',
          image_url: `data:${image.mimeType};base64,${image.base64}`,
          detail: 'high',
        });
      }

      const response = await openai.responses.create({
        model,
        input: [{ role: 'user', content }],
        max_output_tokens: 900,
        store: false,
      });

      const normalized = normalize(extractJson(response.output_text));
      res.set('Cache-Control', 'no-store');
      return res.json(normalized);
    } catch (error) {
      console.error('route-vision failure', {
        name: error?.name,
        status: error?.status,
        requestId: error?.request_id,
      });
      return res.status(502).json({ error: 'vision_provider_error' });
    }
  });

  app.use((_req, res) => res.status(404).json({ error: 'not_found' }));
  return app;
}
