# RevenueCat subscriptions

DualisCheckUp purchases subscriptions through RevenueCat's Flutter SDK. Apple or Google collects production payments. The NestJS API verifies RevenueCat's `premium` entitlement before granting access. Test Store supports development before store accounts are available.

## Create the development catalog

1. Create a RevenueCat account and project. Open its Test Store under Apps & providers.
2. Create an entitlement with identifier `premium`.
3. Create recurring monthly and/or annual products in Test Store and attach them to `premium`.
4. Create an offering, mark it as the current offering, and add the products as monthly/annual packages. The app displays the prices and periods returned by the store. Do not configure a trial unless the store product supports it.
5. Copy the Test Store public SDK key from Project settings > API keys. The Flutter app accepts this key only in nonrelease builds.
6. Create a secret REST API key with permission to read subscriber information through RevenueCat's v1 API. Keep it on the backend.

No Apple Developer or Google Play account is needed for this Test Store catalog. The code does not provision a RevenueCat project or products automatically.

## Configure the development backend

Add these values to the backend's private environment file or secret manager:

```dotenv
REVENUECAT_SECRET_API_KEY=
REVENUECAT_WEBHOOK_AUTHORIZATION=
REVENUECAT_ENTITLEMENT_ID=premium
REVENUECAT_ALLOW_SANDBOX=true
```

Use a randomly generated authorization value for the webhook, such as `Bearer ` followed by a long random token. Configure the exact same value in RevenueCat. The public SDK key and secret REST API key are different credentials. Do not put either server credential in Dart defines, Git, screenshots, or chat.

The backend loads `.env.local` before `.env`. Drizzle's CLI loads `.env`; pass the intended `DATABASE_URL` explicitly when using another environment. Check that it points to the development database before migrating.

```sh
cd backend
npm ci
npm run db:migrate
npm run start:dev
```

Migration `0029_revenuecat_subscriptions.sql` creates the backend-owned subscription table with forced row-level security. Direct writes from Supabase's `anon` and `authenticated` roles are revoked. The migration grants access to the existing `dualis_app` role when present. If your backend uses another restricted role, grant that role the required table permissions during deployment. Each operation sets the authenticated owner with `DatabaseService.withRls()`.

## Configure webhooks

In RevenueCat > Integrations > Webhooks, register:

```text
https://YOUR-DEVELOPMENT-API/v1/billing/webhooks/revenuecat
```

Set Authorization to the exact `REVENUECAT_WEBHOOK_AUTHORIZATION` value. Select sandbox events for development. Use a separate production webhook with production events only. RevenueCat must be able to reach the HTTPS endpoint: a local `localhost` address is not reachable from its servers.

Start with the dashboard's TEST event, then complete a Test Store purchase. TEST checks webhook authentication without granting Premium. Purchase, renewal, cancellation, expiration, refund and transfer events cause the backend to re-read current subscriber state from RevenueCat. Failed verification returns an error so RevenueCat can retry. Duplicates and delayed events re-read current state rather than trusting the event's entitlement fields. Transfers reconcile both accounts.

Webhook availability depends on the RevenueCat plan. The authenticated status/sync endpoints also reconcile access, so an unavailable webhook does not require trusting client purchase claims.

## Run Flutter

Use the public Test Store SDK key in a private, gitignored JSON file outside the repository:

```json
{
  "REVENUECAT_TEST_STORE_API_KEY": "YOUR_TEST_STORE_PUBLIC_SDK_KEY"
}
```

Launch with:

```sh
cd mobile
flutter pub get
flutter run --dart-define-from-file=/absolute/path/to/revenuecat-dev.json
```

Configure the existing API base URL for the target device as needed. Sign into a verified DualisCheckUp account, open the Premium plan from Settings or a Premium promotion, select a package, and buy. RevenueCat receives the authenticated internal account UUID, never the selected family-profile ID. The app does not send email, name, journal content, or health attributes to RevenueCat.

After purchase or restoration, the app asks the backend to reconcile access. The SDK's local entitlement alone does not unlock Premium. If the purchase succeeds while verification is unavailable, retry verification rather than purchasing again.

## HTTP contract

`GET /v1/billing/subscription` reads/reconciles the signed-in account. `POST /v1/billing/sync` requests reconciliation after purchase or restoration. Both require an access-token Bearer header, ignore family-profile selection, and accept no user ID or Premium claim from the client.

```json
{
  "isPremium": true,
  "entitlementId": "premium",
  "expiresAt": "2026-12-04T12:00:00.000Z",
  "managementUrl": null,
  "environment": "sandbox",
  "verifiedAt": "2026-11-04T12:00:00.000Z"
}
```

An absent entitlement returns `isPremium: false`. `expiresAt: null` is reserved for an entitlement with no expiration when Premium is active. The API verifies transaction environment, paid period and any store grace period. Cancelling automatic renewal preserves paid access until expiry. Refunds and transfers follow RevenueCat's current entitlement state.

Status is cached for up to five minutes. Client syncs reuse active status for at most five seconds; inactive status is rechecked immediately. Webhooks always re-read. These bounds limit provider requests and mean a refund/transfer can take up to five minutes to affect cached API access if its webhook has not arrived. Sensitive paid mutations recheck the server entitlement. Existing records remain readable, removable and exportable after a subscription ends.

## Move to Apple and Google

1. Create the real subscription products in App Store Connect and Google Play Console and connect both stores to RevenueCat.
2. Attach the real products to the same `premium` entitlement and current offering. Keep development and production configurations separate.
3. Provide `REVENUECAT_APPLE_API_KEY` and `REVENUECAT_GOOGLE_API_KEY` as platform-specific public SDK keys. Remove the Test Store key from release configuration.
4. Set `NODE_ENV=production` and `REVENUECAT_ALLOW_SANDBOX=false` on the production API. Production rejects sandbox transactions for ordinary accounts even if this flag is accidentally set to true.
5. Configure production webhook credentials, HTTPS URL and event filters. Apply the reviewed database migration through the normal deployment process.
6. For TestFlight, Play license testing and store review, create dedicated DualisCheckUp test accounts and set `REVENUECAT_SANDBOX_USER_IDS` to their exact internal UUIDs on the backend (comma-separated). Only these accounts can use sandbox entitlements in production. Empty, malformed and wildcard entries do not grant access. Use real Apple/Google SDK keys in these release builds, never a Test Store key. Remove review accounts from the allowlist when they are no longer needed.
7. Complete store agreements, banking, tax information and subscription disclosures. Run each store's sandbox tests before submission.

The legacy `PREMIUM_FEATURES` define is restricted to internal nonrelease testing and does not authorize paid server operations. Omit it when testing billing, so purchase verification is exercised.

Deleting a DualisCheckUp account does not cancel store billing. Cancel in the original store as well. Restore behavior must be selected in RevenueCat before launch: choose whether purchases can transfer to another authenticated account, and test both the original and destination account. This integration does not merge DualisCheckUp accounts or their wellness records.

Before enabling production processing, confirm RevenueCat's processing agreement, retention/deletion procedures, processing locations and applicable international-transfer mechanism. The privacy text discloses subscription metadata processing and does not claim these contractual steps have already been completed.

## Verify the integration

```sh
npm --prefix backend test
npm --prefix backend run build
cd mobile
flutter analyze
flutter test test/features/billing
```

On a development device test successful purchase, cancellation of the payment sheet, failed purchase, restore on the same account, no purchase to restore, logout during verification, account switch, subscription expiry, refund and transfer. Confirm Free access returns and urgent help stays available. Repeat with Apple and Google sandbox accounts before production. Automated tests mock RevenueCat and do not prove that your dashboard keys/catalog/webhook are configured.

References: [Flutter SDK](https://www.revenuecat.com/docs/getting-started/installation/flutter), [Test Store](https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store), [webhooks](https://www.revenuecat.com/docs/integrations/webhooks), [restore behavior](https://www.revenuecat.com/docs/projects/restore-behavior).
