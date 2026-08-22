# Google Play Console setup checklist

## App
- App name: Route Performance Tracker
- Permanent Android package/application ID: **`com.routeperformancetracker.app`**
- Track: Closed testing for the first required external test.

The package ID is now locked by the build pipeline. Do not create the Play app under a different package name.

## Subscriptions
Create two subscription products, each with one auto-renewing base plan. Activate the base plan after configuring price/availability.

### Monthly Pro
- Product ID: `route_tracker_pro_monthly`
- Base-plan cadence: monthly auto-renewing
- Target US price: **$6.99/month**

### Annual Pro
- Product ID: `route_tracker_pro_yearly`
- Base-plan cadence: yearly auto-renewing
- Target US price: **$66.99/year**
- This is approximately 20% less than twelve monthly payments, not 50% off.

Google Play remains the source of truth for localized pricing, taxes, renewal terms, and billing conditions.

## Server verification
The backend requires these Vercel environment variables for Google Play verification:
- `SUPABASE_URL` = `https://iapncurupddfhlgvvxrn.supabase.co`
- `SUPABASE_SERVICE_ROLE_KEY` = private Supabase server credential
- `ANDROID_PACKAGE_NAME` = `com.routeperformancetracker.app`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` = private Google Play API service-account JSON

The Google service account must have the Play Console/API permissions required to read and acknowledge subscription purchases for this app. Never put the service-account JSON or Supabase service-role key in the mobile app or GitHub source.

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
7. Confirm server verification creates an active Pro entitlement and acknowledges the purchase.
8. Confirm Pro features unlock.
9. Restore purchases on a clean/reinstalled build.
10. Test cancellation, expiration, grace, and other available lifecycle states using Play test controls.
