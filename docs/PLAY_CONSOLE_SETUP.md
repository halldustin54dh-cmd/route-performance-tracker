# Google Play Console setup checklist

## App
- App name: Route Performance Tracker
- Package/application ID: use the generated Android application ID consistently for every build and Play configuration.
- Track: Closed testing for the first required external test.

## Subscriptions
Create two subscription products:

### Monthly Pro
- Product ID: `route_tracker_pro_monthly`
- Target US price: **$6.99/month**

### Annual Pro
- Product ID: `route_tracker_pro_yearly`
- Target US price: **$66.99/year**
- This is approximately 20% less than twelve monthly payments, not 50% off.

Google Play remains the source of truth for localized pricing and billing terms.

## Server verification
The backend requires these Vercel environment variables for Google Play verification:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ANDROID_PACKAGE_NAME`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

The Google service account must have the Play Console/API permissions required to read subscription purchase status for this app. Never put the service-account JSON or Supabase service-role key in the mobile app or GitHub source.

## Release signing
The GitHub release workflow expects these repository secrets:
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`
- `ROUTE_VISION_CLIENT_TOKEN`

Keep a separate secure backup of the upload keystore and its credentials. Do not rely on GitHub as the only copy.

## Test flow before closed-test recruitment
1. Upload signed AAB to Closed testing.
2. Add license testers/test accounts.
3. Confirm app installs from Google Play, not only by APK sideload.
4. Create/sign into an account.
5. Verify Free AI quota behavior.
6. Complete a Google Play test purchase.
7. Confirm server verification creates an active Pro entitlement.
8. Confirm Pro features unlock.
9. Restore purchases on a clean/reinstalled build.
10. Test cancellation/expiration/grace behavior when available through test subscription controls.
