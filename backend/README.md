# Secure Route Vision Backend

This service keeps the OpenAI API key off the Android device and exposes one narrow endpoint for route-map analysis.

## What it does

- Accepts 1–6 JPEG/PNG/WebP route screenshots.
- Requires a separate bearer token for the client app.
- Applies request-size and per-IP rate limits.
- Sends images to the OpenAI Responses API with `store: false`.
- Returns normalized route characteristics only. It does not return raw model output.
- Never logs image bytes or OCR text.

## Environment

Copy `.env.example` and set values in your hosting provider's secret manager. Never commit actual values.

`OPENAI_API_KEY` is server-only.

`ROUTE_VISION_CLIENT_TOKEN` should be a random value of at least 32 characters. For a private beta this is an abuse-control layer. A production public release should replace/augment it with platform attestation such as Firebase App Check + Play Integrity because any long-lived token shipped in an APK can eventually be extracted.

## Run locally

```bash
cd backend
npm install
OPENAI_API_KEY=... ROUTE_VISION_CLIENT_TOKEN=... npm start
```

Health check: `GET /healthz`

Vision endpoint: `POST /v1/route-vision`

## Container deployment

The included Dockerfile works on Cloud Run, Fly.io, Railway, Render, ECS, or another container host. Configure both secrets in the host, expose port 8080, and require HTTPS at the edge.

For Google Cloud Run, a typical deployment is:

```bash
gcloud run deploy route-vision \
  --source backend \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets OPENAI_API_KEY=route-openai-key:latest,ROUTE_VISION_CLIENT_TOKEN=route-vision-client-token:latest
```

The endpoint itself still requires its bearer token even when the Cloud Run service is network-public.

## Build the Flutter app

Pass the backend URL and the private-beta client token at build time:

```bash
flutter build apk --debug \
  --dart-define=ROUTE_VISION_BASE_URL=https://YOUR-BACKEND.example.com \
  --dart-define=ROUTE_VISION_CLIENT_TOKEN=YOUR_CLIENT_TOKEN
```

Do not pass `OPENAI_API_KEY` to Flutter.

## Data handling

Route images are processed in memory and are not written to backend disk by this service. The Flutter app still keeps the user's selected screenshots locally as route evidence, as before.
