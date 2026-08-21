export default function handler(_req, res) {
  const configured = Boolean(
    process.env.OPENAI_API_KEY &&
    process.env.ROUTE_VISION_CLIENT_TOKEN &&
    process.env.ROUTE_VISION_CLIENT_TOKEN.length >= 32
  );

  res.setHeader('Cache-Control', 'no-store');
  return res.status(200).json({
    ok: true,
    service: 'route-vision',
    visionConfigured: configured,
  });
}
