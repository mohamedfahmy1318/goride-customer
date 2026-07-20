# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

The **GoRide Customer (rider) app** — a Flutter (GetX + Provider, *not* BLoC despite what pubspec suggests — see Gotchas) app for riders on a Mauritania-focused ride-hailing platform. It has no REST backend of its own: it talks directly to **Firebase** (Auth, App Check, Firestore, Storage, Cloud Messaging, Remote Config, Analytics, Crashlytics) and to a handful of **callable Cloud Functions**. Package/appId `cloud.goride.customer`, Flutter SDK `>=3.4.0`, currently `v4.0.9+24`. Firebase project `goride-a9d8f`.

### This is one of three coupled projects sharing one Firestore backend

This repo is opened alongside the **Laravel dashboard** (`/Users/ge/Herd/goride`) and the **driver app** (`/Users/ge/Developer/goride-driver`). All three integrate only through shared **Firestore collections, FCM payloads, and callable Cloud Functions** — there is no API contract. **A change to a status string, Firestore field name, notification-payload key, or a mirrored constant here silently breaks the other apps and the Cloud Functions.** The dashboard repo's `CLAUDE.md` is the canonical map of the cross-project invariants; read it before touching anything on the shared surface, and grep the same identifier across all four codebases (three apps + the deployed `Firebase Cloud Functions/`) before changing it.

## Commands

```bash
flutter pub get
flutter run
flutter analyze
flutter test                          # only test/widget_test.dart (essentially unused)
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
```

There is **no CI workflow in this repo** and effectively **no test suite** — verify changes by reasoning through the flows below and, where possible, on a device. (The driver repo's CI, Flutter 3.27.4 / Java 17, is the reference toolchain for the platform.)

## The rider's core journey (how a ride works, start to finish)

The customer app is fundamentally a **Firestore-snapshot-driven** client: it *writes* an order and then *watches* it change. It writes only three statuses (`Ride Placed`, `Ride Canceled`, `Ride Hold`); every forward transition (`Ride Active` → `Driver Arrived` → `Ride InProgress` → `Ride Completed`) is written by the **driver app / Cloud Functions**, and the rider UI reacts through `.snapshots()` listeners. Status strings are constants in [lib/constant/constant.dart](lib/constant/constant.dart).

- **Home & booking** ([lib/ui/home_screens/home_screen.dart](lib/ui/home_screens/home_screen.dart), `HomeController`) — reverse-geocodes the device GPS for pickup, loads the service/vehicle catalogue + banners + airports, place-search for destination (Google Places or OSM/Nominatim), computes distance/duration (Google Distance Matrix or OSRM) and fare (`meterStart + km×kmCharge + minutes×perMinute`), optional promo code. Booking builds an `OrderModel` and writes `orders/{id}` with `status = "Ride Placed"`, `paymentType = "Cash"`, `paymentStatus = false`, a **geohash `position`** (what drivers query against), polygon-matched `zoneId`/`zone`, `dispatchMode = 'smart_escalation'`, `notifiedDriverIds = []`, and a generated `otp`. A parallel **metered/destinationless** path sets `destinationless = true`, `offerRate = "0"`, no destination — fare settles at completion from GPS distance.
- **Order lifecycle** ([lib/ui/orders/order_screen.dart](lib/ui/orders/order_screen.dart)) — three `StreamBuilder` tabs (Active / Completed / Canceled). The Active tab's live query on `orders` *is* the rider's view of ride progress; the card re-renders as the driver advances status (Searching → driver assigned shows chat/call/WhatsApp → arrived/active shows Track Driver → completed shows Review). There is no separate matching screen for city rides.
- **Live driver tracking** ([lib/controller/live_tracking_controller.dart](lib/controller/live_tracking_controller.dart)) — opens **two** streams: on `orders/{id}` and on **`driver_users/{driverId}`**. The moving car marker reads `driver_users.location` + `.rotation`, with a freshness guard against `driver_users.position.updatedAt` (`Constant.positionStaleAfterMinutes`, default 5) that keeps the last-known marker instead of drawing off a stale fix. The polyline target switches by phase: driver→pickup before `Ride InProgress`, driver→destination during. **Reads the driver's Firestore doc, not RTDB** (the `driver_location` collection constant is unused).
- **Hold timer** ([lib/ui/hold_timer/](lib/ui/hold_timer/)) — mid-trip waiting charge. Rider taps HOLD (`status = Ride Hold`); driver accepts (`Ride Hold Accepted` + `acceptHoldTime`); `HoldTimerWidget` ticks per second and accrues `intervals × chargePerInterval` (optional night multiplier) into `totalHoldingCharges`.
- **Intercity / outstation / parcel** ([lib/ui/interCity/](lib/ui/interCity/), [lib/ui/intercityOrders/](lib/ui/intercityOrders/), writes `orders_intercity`) — passenger rides *and* **parcel/freight sending** (`parcelWeight`/`parcelDimension`/photos), city-to-city with a scheduled `whenDates`/`whenTime`. After posting, the rider lands on `InterCityAcceptOrderScreen` (a "searching…" spinner that auto-pops when a driver is assigned). **The "offer rate" field is `Visibility(visible:false)`** — the rider cannot edit it, `offerRate` is always the app-computed price, there is no bidding, and `order_bids` is unused.
- **Cancellation** — rider cancel sets `Ride Canceled` + sends the driver a `city_order_canceled` FCM. The **3-minute auto-cancel** of unaccepted requests is server-authoritative (Cloud Functions); the client-side `startRideExpirationTimer` in `HomeController` mirrors the setting but is **dead code — never invoked** (see Gotchas).

## Dispatch & the data layer

- **`lib/utils/fire_store_utils.dart` (~1475 lines) is the single Firestore gateway** — settings hydration into `Constant`, order CRUD, nearby-driver queries, wallet/referral writes, reviews, chat, SOS. Collection-name constants: [lib/constant/collection_name.dart](lib/constant/collection_name.dart) (many are declared-but-unused — see Gotchas).
- **The order write is the dispatch trigger**, and authoritative matching runs **server-side** in the deployed Cloud Function `monitorOrderRideRequests`. The customer app *also* contains a client-side nearby-driver query (`sendOrderData` / `sendOrderDataFuture`, GeoFlutterFire `.within(field:'position')` over `driver_users` filtered by `serviceId` + `zoneIds arrayContains zoneId` + `isOnline`, with client-side eligibility filters that drop `isBanned`, non-empty `currentOrderId`, negative `walletAmount`, and stale positions) — treat the **server function as the source of truth**; the client query is a secondary/legacy path.
- **Dispatch radius** — `FireStoreUtils._maxDispatchRadiusKm = 3.0` is a hard **ceiling**. `resolvedCityDispatchRadiusKm()` reads `settings/globalValue.radius` (default `"4"`) and clamps it **down** to `[0.1, 3.0]`, so the admin-configured 4 km is silently capped at 3. Mirror across driver app, CF `dispatch_eligibility.js`, and `AdminRideService`.
- **`setOrder`** is a plain write, **except when a coupon is attached** — then it's a Firestore transaction that atomically writes the order and `FieldValue.increment`s the coupon's `usedCount` while enforcing `usageLimit`/`enable`/`isDeleted`.
- **Auto-cancel window** — `Constant.autoCancelMinutes` (default 3), hydrated from `settings/globalValue`; keep in lockstep with CF `AUTO_CANCEL_AFTER_MS` and the dashboard.

## Payments — cash-only in production

- **Live payment is cash, hard-pinned.** Both booking paths set `paymentType = "Cash"` / `paymentStatus = false` ([home_screen.dart](lib/ui/home_screens/home_screen.dart)); at ride end `PaymentOrderScreen` shows a single "confirm cash" CTA. There is **no wallet-pay or Bankily option at booking**.
- **Commission/wallet settlement is server-side.** The client-side commission debit is **fully removed** — `debitCommission` is gone, `commissionSubscriptionID` is declared but unreferenced, and `commissionDebitedAt` survives only as an `OrderModel` field (a server-side idempotency guard the client never reads/writes). The Cloud Function `settleDriverCommissionOnCompletion` debits commission on the completion transition. Completion controllers only *compute fares for display* now.
- **`lib/payment/bankily/` is a complete but DORMANT module** — a Mauritanian mobile-money (eBankily "B-PAY") integration backed by the `bankilyPayment` / `bankilyCheckTransaction` callables (singleton service + `setState`, **not** GetX). **Nothing in the app navigates to it** — no caller anywhere, so Bankily pay and the wallet **top-up** flow (which lives only inside the Bankily screen) are unreachable.
- **Wallet** (`users.walletAmount`, a stringified number) is in practice **credited only by referrals** and is not spendable on a ride and not top-up-able through the UI.
- **`FirestoreSetupRunner.runOnce()`** ([lib/utils/firestore_setup_runner.dart](lib/utils/firestore_setup_runner.dart), called from `main.dart` on every cold start) idempotently seeds `settings/payment` (Bankily/Sedad/Click) + `_schema` marker docs, guarded by a `settings/_setup_completed` sentinel. Unusual: the *client* provisions config docs. The seeded `settings/payment` is currently written-but-not-consumed. `lib/utils/setup_payment_methods.dart` is an older, uncalled duplicate targeting a different (`goRide`) Firebase app.
- **No other gateways.** All template gateways (Stripe/Razorpay/PayPal/Braintree/etc.) were stripped from `lib/`; Sedad & Click exist as seeded config names only, no client code.

## Startup, auth & config

`main()` order is non-standard: Firebase init → **`FirebaseAppCheck.activate` (Play Integrity / DeviceCheck) immediately** → Crashlytics as fatal-error sink → `FirestoreSetupRunner.runOnce()` → `Preferences.initPref()` → `GlobalSettingController` starts loading as the `GetMaterialApp.home` builder, in parallel with the splash.

- **Routing** ([lib/controller/splash_controller.dart](lib/controller/splash_controller.dart)) — waits `max(3s, settingsLoaded)` (polls up to 10s) → `ForceUpdateService.init()` + `checkForUpdate()`; **if a force-update is required it returns early and never routes** (`Get.offAll` would wipe the non-dismissible dialog). Then: onboarding not finished → `OnBoardingScreen`; else `FireStoreUtils.isLogin()` (Firebase user **and** `users/{uid}` doc exist) → `DashBoardScreen` else `LoginScreen`.
- **Auth** ([lib/ui/auth_screen/](lib/ui/auth_screen/)) — phone OTP (Firebase Phone Auth), Google, Apple (`login`/`google`/`apple`). Because **App Check is active**, Android phone-auth verification is satisfied by Play Integrity rather than reCAPTCHA (reCAPTCHA only via the debug dart-define). Like the driver app, `LoginController` does heavy **abuse-quota hardening** — per-country digit-length validation *before* calling Firebase, a 60s cooldown on `too-many-requests`, and mapping of `captcha-check-failed`/`app-not-authorized` errors — because each rejected attempt burns the device's abuse budget. Debug escape hatches: `FORCE_RECAPTCHA_FOR_DEBUG`, `DISABLE_APP_VERIFICATION_FOR_TESTING`. Country picker is limited to **EG / MR**. **OTP is verified in `otp_screen.dart` UI**, not a controller.
- **Global settings** are loaded by `FireStoreUtils.getSettings()` from `settings/*` docs into static `Constant` fields (map key, radius, distance type, region MR/Mauritania, `autoCancelMinutes`, `positionStaleAfterMinutes`, a live `settings/adminCommission` listener, referral, contact). Currency falls back to hardcoded **MRU / أوقية**.
- **Force update** ([lib/services/force_update_service.dart](lib/services/force_update_service.dart)) reads the **generic** `force_update_enabled` (NOT `force_update_customer_enabled`) plus `force_update_customer_version` and soft `latest_customer_version`. Because `force_update_enabled` is shared, flipping it force-updates the customer and driver apps together. Fail-open on RC errors.

## Notifications

- **Android channel id `goRide-customer`** (hyphen; also the manifest FCM default channel). **Topic subscribed `goRide_customer`** (underscore; guarded by a persisted `Preferences.fcmTopicSubscribedKey` so it subscribes once, with `TOO_MANY_REGISTRATIONS` retry). Don't conflate the two spellings, or the package id `cloud.goride.customer`, or the manifest namespace `com.goride.customer` — this app uses several near-identical "goRide" identifiers.
- **Push is used sparingly.** `driver assigned / arrived / started / completed` do **not** arrive as in-app push — the UI reacts to the order's Firestore stream. Push (`onMessageOpenedApp`) routes only `type`: `chat` → `ChatScreens`, `city_order_complete` → `PaymentOrderScreen`, `intercity_order_complete` → intercity payment, `admin_chat` → `AdminChatScreen`. Payload keys used: **`type`, `orderId`, `customerId`, `driverId`**.
- **Outbound sends** go through the `sendNotification` HTTPS callable ([lib/constant/send_notification.dart](lib/constant/send_notification.dart)) — which addresses *driver* channels (`goRide-driver` / `ride_request_alert_v3`) when the rider notifies a driver. The callable does server-side bilingual (Arabic/other) selection from the recipient's `language` field.

## Feature map

Post-login shell is a **hamburger drawer** ([lib/ui/dashboard_screen.dart](lib/ui/dashboard_screen.dart), `DashBoardController.selectedDrawerIndex`) — no bottom nav. Default landing = Home (index 0). Drawer: 0 Home · 1 InterCity · 2 city orders · 3 intercity orders · 4 Settings · 5 Referral · 6 Inbox · 7 Profile · 8 Contact Us · 9 FAQ · 10 Admin Support · 11 Log out.

- **Coupons** ([lib/ui/coupon_screen/](lib/ui/coupon_screen/)) — "Redeem Coupon"; only the manual text-field **Apply** path is live (the coupon-list item tap is commented out). Applied from the payment screen; `couponAmount` subtracts from the fare (a **company-absorbs** discount — driver earnings/commission stay pegged to the gross fare).
- **Referral** ([lib/ui/referral_screen/](lib/ui/referral_screen/)) — share your code via the native share sheet. Redemption happens at **signup** (`information_screen.dart` writes `referralBy`); the **credit is real** — after a paid ride, `updateReferralAmount` transactionally increments the inviter's `users.walletAmount` and logs a `wallet_transaction`.
- **Review** ([lib/ui/review/](lib/ui/review/)) — rider rates the **driver** (stars + comment), recomputes the driver's `reviewsSum`/`reviewsCount`, guards double-rating; handles city + intercity.
- **Chat — two distinct channels:** per-ride **rider↔driver** ([lib/ui/chat_screen/](lib/ui/chat_screen/), `chat/{orderId}`, text/image/video, App-Store-compliant EULA + report + block, FCM-backed) vs. a single per-user **rider↔admin** support thread ([lib/ui/admin_chat/](lib/ui/admin_chat/), **collection `client_admin_chat`**, text-only, no media/block).
- **SOS — wired.** On active rides, writes a `SosModel {status:"Initiated"}` to `sos` (minimal alert, order-id only) for an operator to action.
- **Informational** — FAQ, Contact Us (`+22222245004` / WhatsApp), Terms/Privacy (HTML, reached from the login screen only). Profile (name + photo; phone/email read-only). Settings (language / support / delete-account; **no theme toggle**).

## Cross-project invariants mirrored here

- **Ride status strings** ([constant.dart](lib/constant/constant.dart)): `Ride Placed`, `Ride Active`, `Driver Arrived`, `Ride InProgress` (no space), `Ride Completed`, `Ride Canceled`, `Ride Hold`, `Ride Hold Accepted`.
- **Notification payload keys**: `type` (`city_order` / `intercity_order` / `city_order_canceled` / `*_complete` / `chat` / `admin_chat`), `orderId`, `customerId`, `driverId`.
- **Dispatch radius** `_maxDispatchRadiusKm = 3.0`; **auto-cancel** `autoCancelMinutes = 3`; **`positionStaleAfterMinutes`** (driver-location freshness). All mirrored in the driver app, Cloud Functions, and `AdminRideService`.
- **`commissionSubscriptionID = "J0RwvxCWhZzQQD7Kc2Ll"`** — declared but unreferenced here (residual scaffolding).

## Cross-cutting

- **Localization** — Arabic / English / French, static GetX `Translations` maps in [lib/lang/](lib/lang/). Arabic is the practical default; RTL derives from `langCode == 'ar'`. Much UI copy is Arabic-only literals. The user's language is persisted to Firestore for server-side notification-language selection.
- **Theme is light-only; dark mode is dead code** — `main.dart` hardcodes light with no `darkTheme`/`themeMode`, and `DarkThemeProvider.getThem()` always returns `false`. Settings has no theme toggle.
- **Analytics/Crashlytics** are wired globally (`FirebaseAnalyticsObserver`, `FlutterError.onError`).

## Gotchas & footguns

- **⚠️ Committed secrets.** `Firebase Import Export Collections/` contains **committed Firebase admin service-account JSON** (`goride-a9d8f-firebase-adminsdk-*.json`, `credentials.json`) — a full admin key in git history. Treat it as compromised and flag to maintainers; do not rely on it or add more. The **Google Maps API key** `AIzaSyAb3p2UEDZuLOPokFUTwpHEkpORrayXig0` is hardcoded in `AndroidManifest.xml` and repeated as a Firestore fallback in `fire_store_utils.dart`.
- **`firestore.rules` is stale/aspirational.** Three rules files exist (`firestore.rules`, `firestore_rules_simple.rules`, `firestore_rules_updated.rules`); `firebase.json` points to `firestore.rules` but `FIRESTORE_COMPATIBILITY_REPORT.md` says deploy `firestore_rules_updated.rules`. The deployed rules gate order-create on `status == 'pending'` and reference `'accepted'`/`'rideActive'` — statuses the app **never writes** (it writes `Ride Placed` etc.). If enforced verbatim, booking would fail — a strong sign production runs looser rules than any file here. Don't treat these files as ground truth.
- **The bundled `Firebase Cloud Functions/` is a working-copy mirror, possibly stale.** The **deployed** functions (in the dashboard repo / project `goride-a9d8f`) are the source of truth. `Firebase Import Export Collections/` and `Firebase Indexing/` are one-off dev tooling, not live infra.
- **Vestigial pubspec deps.** `flutter_bloc`, `dio`, `get_it`, `equatable`, and `translator` are declared but **never imported** in `lib/` — the app is GetX-only, uses `cloud_functions`/`cloud_firestore` directly, and has no runtime translation. Don't infer architecture from the manifest.
- **Dead/vestigial code to not be misled by:** the entire `lib/payment/bankily/` module (no caller), the wallet top-up flow, `HomeController.startRideExpirationTimer` (auto-cancel, never invoked), the order `otp` field (generated but never shown — "OTP removed, show ride status instead"), `AboutUsScreen` (built but never routed to), and the intercity offer-rate field (hidden).
- **Latent collections/models** — `collection_name.dart` declares `scheduled_rides`, `favorite_locations`, `ride_history`, `order_bids`, `driver_location`, `support_tickets`, `notifications`, `cms_pages`, `vehicle_brand/model`, `payment_methods`, `cancellation_reasons` — **none are referenced**; they're schema placeholders (scheduled rides, saved locations, and ride history are NOT wired into any UI). Models `subscription_plan_model`, `freight_vehicle`, `driver_rules_model` are likewise unused.
- **Filename typo:** the global-config controller is `global_setting_conroller.dart` (missing "t"). Same typo exists in the driver app.
- **`FIRESTORE_COMPATIBILITY_REPORT.md`** (Arabic) documents the driver-eligibility field rename to `isApproved` + `documentVerification` and the collection access tiers — useful when reasoning about the rules.
