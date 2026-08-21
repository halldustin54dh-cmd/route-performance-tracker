# Route Performance Tracker monetization architecture

## Accounts and cloud data

Use Supabase Auth for email/password and magic-link sign-in. Supabase Postgres stores cloud-backed user profile and route records. The app remains local-first and queues sync work when offline.

Required build-time values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

These values are public client configuration. Row Level Security protects user data.

## Entitlements

The app never decides Pro status solely from a local purchase callback. Purchases are represented as server-verified entitlements with:

- user id
- provider (`google_play`, `app_store`, `manual_beta`)
- product id
- status
- started at
- expires at
- last verified at

## Mobile billing

Android uses Google Play Billing through Flutter's `in_app_purchase` package. Planned products:

- `route_tracker_pro_monthly`
- `route_tracker_pro_yearly`

Apple uses StoreKit through the same Flutter purchase abstraction when the iOS target is added.

For store-distributed builds, digital subscriptions are purchased using the platform billing system. The backend verifies store receipts/tokens before granting Pro.

## Pro feature gates

Initial Pro feature set:

- secure route-map AI vision analysis
- cloud backup and multi-device sync
- advanced historical analytics
- export/reporting enhancements
- future automated route comparison tools

Core local route tracking remains usable without Pro.

## Security

No OpenAI, Supabase service-role, Google Play service-account, or App Store server keys belong in the APK.
