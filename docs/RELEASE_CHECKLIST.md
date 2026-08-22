# Route Performance Tracker 1.0 release checklist

## Product behavior
- [ ] Free core route workflow works while signed out and offline.
- [ ] Signed-in Free account receives no more than 3 successful AI analyses per calendar month.
- [ ] Fourth Free AI request is blocked with a clear upgrade message.
- [ ] Active Pro entitlement bypasses the monthly Free quota while normal abuse/rate protection remains.
- [ ] Advanced analytics are Pro-only; Free still has useful basic analytics.
- [ ] Cloud backup and cloud restore require Pro.
- [ ] Evidence image files are clearly described as local-only until Storage sync is implemented.

## Accounts and connectivity
- [ ] Sign up.
- [ ] Sign in with password.
- [ ] Sign out without deleting local routes.
- [ ] Sign back in and confirm local routes remain.
- [ ] Sign-in link flow.
- [ ] Start/continue route without internet.
- [ ] Cloud action with no internet fails without deleting/changing local data.
- [ ] Retry cloud action after internet returns.
- [ ] Restore cloud routes on a clean device without creating duplicates on repeated restore.

## Routes and real-world regression
- [ ] Screenshot import with 1 image.
- [ ] Screenshot import with multiple images.
- [ ] OCR extraction: stops, locations, packages, multi-location stops.
- [ ] AI map analysis: spread, rurality, clustering, backtracking, access.
- [ ] Route fields require sensible values and missing optional data does not invent metrics.
- [ ] First-stop time is distinct from setup/loadout time.
- [ ] Checkpoints update pace and forecast.
- [ ] Delays adjust performance metrics appropriately.
- [ ] Evidence persists locally.
- [ ] Finish route and open History.
- [ ] 7-day basic analytics.
- [ ] Pro 30-day/all-time analytics.

## Subscriptions
- [ ] Monthly product: `route_tracker_pro_monthly`, target $6.99 US.
- [ ] Annual product: `route_tracker_pro_yearly`, target $66.99 US.
- [ ] Purchase starts in Google Play.
- [ ] Server verifies purchase token.
- [ ] Entitlement becomes active only after server verification.
- [ ] Restore purchase re-verifies and restores Pro.
- [ ] Expired/inactive subscription does not retain Pro.

## Backend
- [ ] Vercel health: vision configured.
- [ ] Vercel health: subscriptions configured.
- [ ] Supabase RLS/security review clean.
- [ ] OpenAI key remains server-only.
- [ ] Supabase service-role key remains server-only.
- [ ] Google Play service-account credential remains server-only.

## Store/release
- [ ] Final app icon.
- [ ] Phone screenshots/store graphics.
- [ ] Privacy policy published at stable URL.
- [ ] Terms published at stable URL.
- [ ] Support/privacy contact populated.
- [ ] Data deletion instructions published.
- [ ] Data Safety form matches actual behavior.
- [ ] Upload keystore backed up securely.
- [ ] Signed release AAB generated.
- [ ] Closed-test listing completed.
- [ ] AAB uploaded to Closed testing.
- [ ] Tester opt-in link verified.
- [ ] At least 12 qualifying testers remain opted in for required period.
