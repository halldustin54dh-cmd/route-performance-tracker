# Security release notes

- OpenAI credentials remain server-side.
- Mobile AI requests require both an app-build client credential and a signed-in Supabase account session.
- Free AI usage is metered server-side by account/month; active Pro entitlement bypasses the Free monthly quota while request-rate protection remains.
- Supabase Row Level Security protects user route and entitlement reads.
- Clients cannot grant themselves Pro entitlement.
- Google Play purchases are intended to be verified server-side before Pro is acknowledged in the app.
- Supabase service-role and Google Play service-account credentials must remain server-only.
- Cloud route backup/restore is gated by verified Pro entitlement.
- Original evidence photo bytes are not included in cloud route backup in the current release.
