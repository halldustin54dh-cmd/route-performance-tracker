export default function handler(_req, res) {
  const visionConfigured = Boolean(
    process.env.OPENAI_API_KEY &&
    process.env.ROUTE_VISION_CLIENT_TOKEN &&
    process.env.ROUTE_VISION_CLIENT_TOKEN.length >= 32
  );

  const subscriptionsConfigured = Boolean(
    process.env.SUPABASE_URL &&
    process.env.SUPABASE_SERVICE_ROLE_KEY &&
    process.env.ANDROID_PACKAGE_NAME &&
    process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
  );

  res.setHeader('Cache-Control', 'no-store');
  return res.status(200).json({
    ok: true,
    service: 'route-performance-tracker-backend',
    visionConfigured,
    subscriptionsConfigured,
  });
}
