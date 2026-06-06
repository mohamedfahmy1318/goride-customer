# CLAUDE.md — GoRide Customer App

This file guides Claude Code in the GoRide **customer/rider** Flutter app. It is one of three coupled projects sharing a single Firebase backend (`goride-a9d8f`). See the dashboard repo's CLAUDE.md (`/Users/ge/Herd/goride/CLAUDE.md`) for the cross-project picture and shared contracts you must not drift.

## Stack
- Flutter, Dart `>=3.4.0 <4.0.0`. App version `4.0.7+22`. iOS bundle `cloud.gorid.customer`.
- **State: GetX** (`get ^4.7.2`) primary; **Provider** only for `DarkThemeProvider`. `flutter_bloc`, `get_it`, `equatable` are declared but **unused** — do not adopt them; match the GetX patterns.
- Firebase: core/auth/firestore/functions/messaging/storage/database/remote_config/crashlytics/analytics + **app_check** (`playIntegrity`/`deviceCheck`).
- Maps/geo: `google_maps_flutter`, OSM (`flutter_osm_plugin`, `osm_nominatim`), `geocoding`, polylines. **GeoFlutterFire is vendored** at `lib/widget/geoflutterfire/` (not a pub dep). `geolocator` is used in `fire_store_utils.dart` but **not declared in pubspec** (transitive — fragile).
- Payment: `lib/payment/bankily/` — eBankily B-PAY (Mauritania) via Cloud Functions callables. `bankily_config.dart` is hardcoded `isProduction = false` (test mode).

## Entry point & structure
`lib/main.dart` order: Firebase init → App Check activate → Crashlytics handlers → `FirestoreSetupRunner.runOnce()` (one-time seed of MR payment methods) → `Preferences.initPref()` → `ConnectivityService` → `runApp`. Root `GetMaterialApp`, **forced light theme**, locales ar/en/fr, `home: SplashScreen`. Splash chooses OnBoarding/Login/Dashboard.

`lib/` layout (GetX MVC-ish, no repository layer — controllers call `FireStoreUtils` static methods directly):
- `controller/` (26 GetX controllers) · `model/` (~38 models) · `ui/` (feature-grouped screens) · `utils/` (`fire_store_utils.dart` is a ~1500-line god-object: settings, orders, wallet, storage, images) · `services/` (force-update, connectivity, analytics, social sign-in, localization) · `constant/` (`constant.dart`, `collection_name.dart`, `send_notification.dart`) · `payment/bankily/` · `widget/` (+ vendored `geoflutterfire/`) · `themes/` · `lang/` · `generated/`.

## Navigation
No named-route table. Imperative GetX: `Get.to(() => Screen())`, `Get.offAll(...)`; args via `Get.to(..., arguments: {...})` + `Get.arguments`.

## Data layer — read this before touching booking/payment
- **Dispatch is server-side. The customer app does NOT discover drivers or send ride FCM.** Booking (`ui/home_screens/home_screen.dart` `_proceedWithBooking`, ~1685–1807) builds an `OrderModel` client-side (uuid id, geohash `position`, `status="Ride Placed"`, `dispatchMode='smart_escalation'`, `notifiedDriverIds=[]`, random 6-digit `otp`, fare/commission/coupon math) and writes it via `FireStoreUtils.setOrder` (plain `set`, or a transaction that also increments coupon `usedCount`). The deployed Cloud Function `monitorOrderRideRequests` does all driver matching/notification from there.
- **Zone lookup is a client-side polygon test** (`Constant.isPointInPolygon` over `controller.zoneList`). No zone match → "Services unavailable", no order written.
- **ORPHANED / dead code (do not revive without coordination):** `FireStoreUtils.sendOrderData` / `sendOrderDataFuture` (old client-side nearby-driver geo query) and `home_controller.startRideExpirationTimer` (client auto-cancel) **have no live callers** — dispatch and auto-cancel are now server-side (CF + Laravel sweep). The timer's doc-comment ("6 min") is also wrong; default is `autoCancelMinutes = 3`.
- **Settlement is written client-side** (`controller/payment_order_controller.dart`): on completion the customer app credits the driver wallet (gross fare + tax) and **debits admin commission from the driver wallet** — but **only if `driverUserModel.subscriptionPlan.id == Constant.commissionSubscriptionID`** (`"J0RwvxCWhZzQQD7Kc2Ll"`) **and** `orderModel.commissionDebitedAt == null`. ⚠️ The driver app no longer gates commission on this plan — see cross-project risk in the dashboard CLAUDE.md before changing commission logic.
- Cloud Functions callable used: `sendNotification` (via `constant/send_notification.dart`) — only for payment/chat/intercity events, never city dispatch. Bankily callables for pay + status.
- FCM `type` keys consumed (`utils/notification_service.dart`): `chat`, `city_order_complete`, `intercity_order_complete`, `admin_chat`, `city_order_payment_complete`. Subscribes to topic `goRide_customer`.
- `walletAmount` is stored/parsed as a **String** everywhere — handle defensively.

## Models
`lib/model/order_model.dart` (`OrderModel`) is the central cross-app contract: status, `dispatchMode`, `dispatchConfig`, `notifiedDriverIds`, `position` (geoPoint+geohash), fare breakdown (`totalFare`, `adminCommissionAmount`, `driverEarnings`, `discountAmount`, `finalPayableAmount`), **`commissionDebitedAt`**, coupon, taxList, `isAdminCreated`, metered fields. Also `UserModel`, `DriverUserModel`, `ZoneModel`, `CouponModel`.

## Auth
Firebase **Phone Auth** (`login_controller.dart` → `verifyPhoneNumber` → `otp_controller` → `signInWithCredential`). Google + Apple sign-in services. Session via `FireStoreUtils.isLogin()` / `getCurrentUid()`.

## Config
No `.env`. Runtime config comes from Firestore `settings/*` docs (`FireStoreUtils.getSettings()`). Google Maps key from `settings/globalKey.googleMapKey` with a committed hardcoded fallback. Force-update via Remote Config (`services/force_update_service.dart`) — gate key is the **generic** `force_update_enabled` + `force_update_customer_version` (note: not `force_update_customer_enabled`). `firebase_options.dart` has committed API keys (standard for FlutterFire mobile). Status strings/region/commission id live in `constant/constant.dart`; `_maxDispatchRadiusKm = 15.0` cap in `fire_store_utils.dart`.

## Build / run / test
```bash
flutter pub get
flutter run
flutter analyze
flutter test            # only a stub widget_test.dart exists — no real coverage
flutter build apk       # or: flutter build ipa
```
No CI in this repo.

## Conventions
File names mostly `snake_case.dart` (some stray PascalCase: `Preferences.dart`, `Styles.dart`; a typo file `global_setting_conroller.dart`). i18n via `.tr`, but many strings are hardcoded Arabic literals — inconsistent. Errors: `try/catch` + `log()` (dart:developer) + `ShowToastDialog`; Crashlytics for fatals. Lints: stock `flutter_lints`, no custom rules.

## Known fragile spots
Orphaned dispatch/auto-cancel code (above); `globalUrl` constant in `constant.dart` is **corrupted with Arabic text mid-URL**; three root `*.rules` files (`firestore.rules` is the active one per `firebase.json`; the other two are stale); unused `bloc`/`get_it` deps; Bankily stuck in test mode; client-side money writes (`walletAmount` as String).
