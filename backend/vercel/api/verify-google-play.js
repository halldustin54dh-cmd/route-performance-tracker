import { createClient } from '@supabase/supabase-js';
import { GoogleAuth } from 'google-auth-library';
import { isEntitledSubscription } from '../../src/subscription_state.js';

const allowedProducts = new Set(['route_tracker_pro_monthly', 'route_tracker_pro_yearly']);

function bearer(req) {
  const value = req.headers.authorization || '';
  return value.startsWith('Bearer ') ? value.slice(7) : '';
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing ${name}`);
  return value;
}

async function markInactive(supabase, userId, productId, providerStatus) {
  const now = new Date().toISOString();
  const { error } = await supabase.from('entitlements').upsert({
    user_id: userId,
    tier: 'free',
    provider: 'google_play',
    product_id: productId,
    status: providerStatus || 'inactive',
    expires_at: now,
    last_verified_at: now,
    updated_at: now,
  });
  if (error) throw error;
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'method_not_allowed' });
  }

  try {
    const supabaseUrl = requiredEnv('SUPABASE_URL');
    const serviceKey = requiredEnv('SUPABASE_SERVICE_ROLE_KEY');
    const packageName = requiredEnv('ANDROID_PACKAGE_NAME');
    const serviceAccount = JSON.parse(requiredEnv('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON'));

    const token = bearer(req);
    if (!token) return res.status(401).json({ error: 'unauthorized' });

    const supabase = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    const user = userData?.user;
    if (userError || !user) return res.status(401).json({ error: 'unauthorized' });

    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const purchaseToken = typeof body.purchaseToken === 'string' ? body.purchaseToken : '';
    const productId = typeof body.productId === 'string' ? body.productId : '';
    if (!purchaseToken || !allowedProducts.has(productId)) return res.status(400).json({ error: 'invalid_purchase' });

    const auth = new GoogleAuth({ credentials: serviceAccount, scopes: ['https://www.googleapis.com/auth/androidpublisher'] });
    const client = await auth.getClient();
    const access = await client.getAccessToken();
    if (!access?.token) throw new Error('Could not obtain Google access token');

    const verifyUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
    const verifyResponse = await fetch(verifyUrl, { headers: { Authorization: `Bearer ${access.token}` } });
    if (!verifyResponse.ok) {
      console.error('Google Play verification failed', { status: verifyResponse.status });
      return res.status(400).json({ error: 'purchase_not_verified' });
    }

    const purchase = await verifyResponse.json();
    const lineItems = Array.isArray(purchase.lineItems) ? purchase.lineItems : [];
    const matched = lineItems.find((item) => item.productId === productId);
    const state = purchase.subscriptionState;

    if (!isEntitledSubscription(state, matched)) {
      await markInactive(supabase, user.id, productId, state || 'inactive');
      return res.status(400).json({ error: 'subscription_inactive', state: state || 'unknown' });
    }

    if (purchase.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING') {
      const ackUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/subscriptions/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
      const ackResponse = await fetch(ackUrl, {
        method: 'POST',
        headers: { Authorization: `Bearer ${access.token}`, 'Content-Type': 'application/json' },
        body: '{}',
      });
      if (!ackResponse.ok) {
        console.error('Google Play acknowledgement failed', { status: ackResponse.status });
        return res.status(502).json({ error: 'purchase_acknowledgement_failed' });
      }
    }

    const expiresAt = matched.expiryTime || null;
    const now = new Date().toISOString();
    const { error: upsertError } = await supabase.from('entitlements').upsert({
      user_id: user.id,
      tier: 'pro',
      provider: 'google_play',
      product_id: productId,
      status: 'active',
      started_at: purchase.startTime || now,
      expires_at: expiresAt,
      last_verified_at: now,
      updated_at: now,
    });
    if (upsertError) throw upsertError;

    return res.status(200).json({
      ok: true,
      tier: 'pro',
      productId,
      expiresAt,
      state,
      willRenew: matched.autoRenewingPlan?.autoRenewEnabled === true,
    });
  } catch (error) {
    console.error('purchase verification failure', { name: error?.name, message: error?.message });
    return res.status(503).json({ error: 'verification_not_configured_or_unavailable' });
  }
}
