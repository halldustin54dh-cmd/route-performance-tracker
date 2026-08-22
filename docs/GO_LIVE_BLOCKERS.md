# External go-live blockers

These items cannot be completed solely from repository/backend access and require owner-controlled credentials or Google Play Console actions.

1. Create/configure Google Play subscription products:
   - `route_tracker_pro_monthly` — target US price $6.99/month
   - `route_tracker_pro_yearly` — target US price $66.99/year
2. Obtain and store the Supabase service-role key in Vercel as `SUPABASE_SERVICE_ROLE_KEY`.
3. Configure `SUPABASE_URL` and final `ANDROID_PACKAGE_NAME` in Vercel.
4. Create a Google Play API service account with purchase-verification access and store its JSON in Vercel as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.
5. Generate and securely back up the Android upload keystore; add its encoded bytes/credentials to GitHub Actions secrets.
6. Publish the final privacy policy, terms, support contact, and data-deletion instructions at stable public URLs.
7. Complete Play Console app-content/Data Safety declarations using final production behavior.
8. Upload the signed release AAB to Closed testing and publish the test release.
9. Recruit/maintain the required closed testers for Google's required testing period.

Everything else should be treated as repository/app/backend work and automated or tested before these handoff steps.
