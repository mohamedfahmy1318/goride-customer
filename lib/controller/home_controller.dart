import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/collection_name.dart';
import 'package:customer/constant/constant.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/controller/dash_board_controller.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/banner_model.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:customer/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:osm_nominatim/osm_nominatim.dart';

class HomeController extends GetxController {
  DashBoardController dashboardController = Get.put(DashBoardController());

  Rx<TextEditingController> sourceLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> destinationLocationController =
      TextEditingController().obs;
  Rx<TextEditingController> offerYourRateController =
      TextEditingController().obs;
  Rx<ServiceModel> selectedType = ServiceModel().obs;

  Rx<LocationLatLng> sourceLocationLAtLng = LocationLatLng().obs;
  Rx<LocationLatLng> destinationLocationLAtLng = LocationLatLng().obs;

  RxString currentLocation = "".obs;
  RxBool isLoading = true.obs;
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList bannerList = <BannerModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  Rx<ZoneModel> selectedZone = ZoneModel().obs;
  Rx<UserModel> userModel = UserModel().obs;
  RxBool isAcSelected = false.obs;
  RxBool isBookingInProgress = false.obs;
  RxDouble extraDistance = 0.0.obs;
  static Timer? _rideExpirationTimer;
  static String _activeOrderId = '';
  RxString activeOrderId = ''.obs;
  final PageController pageController =
      PageController(viewportFraction: 0.96, keepPage: true);
  Timer? _bannerAutoScrollTimer;
  static const Duration _bannerAutoScrollInterval = Duration(seconds: 10);

  var colors = [
    AppColors.serviceColor1,
    AppColors.serviceColor2,
    AppColors.serviceColor3,
  ];

  String? startNightTime;
  String? endNightTime;
  DateTime startNightTimeString = DateTime.now();
  DateTime endNightTimeString = DateTime.now();

  @override
  void onInit() {
    getLocation();
    getServiceType();
    getZoneAndUserData();
    // Keep the coupon discount in sync with the live fare — if the customer
    // switches service or distance shifts, a percentage coupon's absolute
    // value moves with it, and a fare below the min-bill auto-drops the
    // coupon (see _recalculateDiscount).
    ever<String>(amount, (_) => _recalculateDiscount());
    super.onInit();
  }

  Future<void> getLocation() async {
    try {
      Constant.currentLocation = await Utils.getCurrentLocation();

      if (Constant.currentLocation == null) {
        return;
      }

      // Try geocoding to get address from coordinates
      String address = '';
      bool geocoded = false;

      // Method 1: Google geocoding (native platform)
      if (Constant.selectedMapType == 'google') {
        try {
          List<Placemark> placeMarks = await placemarkFromCoordinates(
            Constant.currentLocation!.latitude,
            Constant.currentLocation!.longitude,
          );
          if (placeMarks.isNotEmpty) {
            Constant.country = placeMarks.first.country;
            Constant.city = placeMarks.first.locality;
            // Build parts list — `placemark.name` is often a Plus Code (Open
            // Location Code) when there's no friendly street/business name on
            // iOS/Android. Drop those before joining; the rest of the chain
            // still goes through `_cleanAddress` as a second line of defense.
            final pm = placeMarks.first;
            final String rawName = (pm.name ?? '').trim();
            final bool nameIsPlusCode =
                RegExp(r'^[A-Z0-9]{2,}\+[A-Z0-9]{2,}').hasMatch(rawName);
            final parts = <String>[
              if (!nameIsPlusCode) rawName,
              (pm.subLocality ?? '').trim(),
              (pm.locality ?? '').trim(),
              (pm.administrativeArea ?? '').trim(),
              (pm.postalCode ?? '').trim(),
              (pm.country ?? '').trim(),
            ].where((p) => p.isNotEmpty).toList();
            address = _cleanAddress(parts.join(', '));
            geocoded = true;
          }
        } catch (_) {}
      }

      // Method 2: Nominatim fallback (or primary if OSM selected)
      if (!geocoded) {
        try {
          Place place = await Nominatim.reverseSearch(
            lat: Constant.currentLocation!.latitude,
            lon: Constant.currentLocation!.longitude,
            zoom: 14,
            addressDetails: true,
            extraTags: true,
            nameDetails: true,
          );
          address = _cleanAddress(place.displayName.toString());
          Constant.country = place.address?['country'] ?? '';
          Constant.city = place.address?['city'] ?? '';
          geocoded = true;
        } catch (_) {}
      }

      // Method 3: Use raw coordinates if all geocoding fails
      if (!geocoded) {
        address =
            '${Constant.currentLocation!.latitude.toStringAsFixed(4)}, ${Constant.currentLocation!.longitude.toStringAsFixed(4)}';
      }

      currentLocation.value = address;

      // Always set source location from current location
      sourceLocationLAtLng.value = LocationLatLng(
        latitude: Constant.currentLocation!.latitude,
        longitude: Constant.currentLocation!.longitude,
      );
      sourceLocationController.value.text = currentLocation.value;
    } catch (e) {
      ShowToastDialog.showToast(
        "Location access permission is currently unavailable. You're unable to retrieve any location data. Please grant permission from your device settings.",
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Drop Plus-Code-looking parts and highly-numeric segments from an
  /// address string, then collapse consecutive duplicates. Used after
  /// reverse geocoding to keep the customer-facing source address (and the
  /// `sourceLocationName` we ship to drivers) free of strings like
  /// `322R+6P2` that the native geocoder emits when there is no friendly
  /// street/business name.
  String _cleanAddress(String address) {
    if (address.isEmpty) return address;
    final parts = address
        .split(RegExp(r'[,،]'))
        .map((p) => p.trim())
        .where((p) {
          if (p.isEmpty) return false;
          if (RegExp(r'[A-Z0-9]{2,}\+[A-Z0-9]{2,}').hasMatch(p)) return false;
          final digits = RegExp(r'\d').allMatches(p).length;
          if (digits > 0 && digits / p.length >= 0.5) return false;
          return true;
        })
        .toList();
    final dedup = <String>[];
    for (final p in parts) {
      if (dedup.isEmpty || dedup.last != p) dedup.add(p);
    }
    return dedup.isEmpty ? address : dedup.join(', ');
  }

  getServiceType() async {
    try {
      final services = await FireStoreUtils.getService();
      List<ServiceModel> sortedList = List.from(services);
      sortedList.sort((a, b) => a.position.compareTo(b.position));
      serviceList.value = sortedList;
      if (serviceList.isNotEmpty) selectedType.value = serviceList.first;

      final banners = await FireStoreUtils.getBanner();
      bannerList.value = banners;
      _startBannerAutoScroll();

      final taxes = await FireStoreUtils().getTaxList();
      if (taxes != null) Constant.taxList = taxes;

      final airports = await FireStoreUtils().getAirports();
      if (airports != null) Constant.airaPortList = airports;

      String? token = await NotificationService.getToken();
      final profile =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (profile != null) {
        userModel.value = profile;
        if (token != null) {
          userModel.value.fcmToken = token;
          FireStoreUtils.updateUser(userModel.value);
        }
      } else {
        // Log but don't keep the screen loading indefinitely
        log('HomeController.getServiceType: user profile is null');
      }
    } catch (e, s) {
      log('Error in getServiceType: $e');
      log(s.toString());
    } finally {
      isLoading.value = false;
    }
  }

  RxString duration = "".obs;
  RxString distance = "".obs;
  RxString amount = "".obs;
  RxDouble totalAmount = 0.0.obs;

  // ── Promo / coupon state ────────────────────────────────────────────────
  // The booking sheet binds its input + breakdown to these. Company-absorbs
  // model: the discount reduces what the customer pays but does NOT touch
  // the driver's earnings — commission is still computed on the gross fare
  // at placement time (see _proceedWithBooking in home_screen.dart).
  final Rxn<CouponModel> appliedCoupon = Rxn<CouponModel>();
  final RxDouble discountAmount = 0.0.obs;
  final RxBool isApplyingCoupon = false.obs;
  final TextEditingController promoCodeController = TextEditingController();

  /// Computed: what the customer actually pays (subtotal − discount). Read
  /// this at placement time and via Obx in the breakdown widget.
  double get finalPayable {
    final double subTotal = double.tryParse(amount.value) ?? 0;
    return (subTotal - discountAmount.value)
        .clamp(0, double.infinity)
        .toDouble();
  }

  /// Recompute the discount against the current [amount]. Called when the
  /// customer picks a different service or distance changes while a coupon
  /// is already applied — the discount magnitude may shift (percentage
  /// coupons) or the min-bill floor may now be unmet.
  void _recalculateDiscount() {
    final coupon = appliedCoupon.value;
    if (coupon == null) {
      discountAmount.value = 0;
      return;
    }
    final double subTotal = double.tryParse(amount.value) ?? 0;
    final double minBill =
        double.tryParse(coupon.minBillAmount?.toString() ?? '0') ?? 0;
    if (subTotal < minBill) {
      // Auto-drop the coupon when the fare falls below the minimum — the
      // user will see the breakdown row disappear and can re-apply later.
      appliedCoupon.value = null;
      discountAmount.value = 0;
      promoCodeController.clear();
      ShowToastDialog.showToast(
          "Coupon removed: fare is below the minimum bill amount".tr);
      return;
    }
    discountAmount.value = Constant.calculateCouponDiscount(
      subTotal: subTotal,
      coupon: coupon,
    );
  }

  /// Validate + apply a promo code. Surfaces errors via ShowToastDialog and
  /// returns true on success so the caller can dismiss the input keyboard.
  Future<bool> applyPromoCode(String code) async {
    if (isApplyingCoupon.value) return false;
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      ShowToastDialog.showToast("Please enter a promo code".tr);
      return false;
    }
    if (appliedCoupon.value?.code == normalized) {
      ShowToastDialog.showToast("Promo code already applied".tr);
      return true;
    }
    final double subTotal = double.tryParse(amount.value) ?? 0;
    if (subTotal <= 0) {
      ShowToastDialog.showToast(
          "Select a destination before applying a promo code".tr);
      return false;
    }

    isApplyingCoupon.value = true;
    try {
      final coupon = await FireStoreUtils.getCouponByCode(normalized);
      if (coupon == null) {
        ShowToastDialog.showToast("Invalid or expired promo code".tr);
        return false;
      }

      // Usage-limit check is advisory here — the Firestore transaction in
      // FireStoreUtils.setOrder re-checks atomically at placement so we can
      // never over-redeem even under concurrent bookings.
      if (coupon.usageLimit != null &&
          coupon.usageLimit! > 0 &&
          (coupon.usedCount ?? 0) >= coupon.usageLimit!) {
        ShowToastDialog.showToast(
            "This promo code has reached its usage limit".tr);
        return false;
      }

      final double minBill =
          double.tryParse(coupon.minBillAmount?.toString() ?? '0') ?? 0;
      if (subTotal < minBill) {
        ShowToastDialog.showToast(
            "${"Minimum bill for this coupon is".tr} ${Constant.amountShow(amount: minBill.toStringAsFixed(2))}");
        return false;
      }

      final double discount = Constant.calculateCouponDiscount(
        subTotal: subTotal,
        coupon: coupon,
      );
      if (discount <= 0) {
        ShowToastDialog.showToast("Promo code could not be applied".tr);
        return false;
      }

      appliedCoupon.value = coupon;
      discountAmount.value = discount;
      ShowToastDialog.showToast(
          "${"Discount applied".tr}: ${Constant.amountShow(amount: discount.toStringAsFixed(2))}");
      return true;
    } catch (e) {
      log('applyPromoCode error: $e');
      ShowToastDialog.showToast("Something went wrong, please try again".tr);
      return false;
    } finally {
      isApplyingCoupon.value = false;
    }
  }

  /// Drop the currently-applied coupon and reset the breakdown.
  void clearPromoCode() {
    appliedCoupon.value = null;
    discountAmount.value = 0;
    promoCodeController.clear();
  }

  DateTime currentTime = DateTime.now();
  DateTime currentDate = DateTime.now();

  double convertToMinutes(String duration) {
    double durationValue = 0.0;

    try {
      final RegExp hoursRegex = RegExp(r"(\d+)\s*hour");
      final RegExp minutesRegex = RegExp(r"(\d+)\s*min");

      final Match? hoursMatch = hoursRegex.firstMatch(duration);
      if (hoursMatch != null) {
        int hours = int.parse(hoursMatch.group(1)!.trim());
        durationValue += hours * 60;
      }

      final Match? minutesMatch = minutesRegex.firstMatch(duration);
      if (minutesMatch != null) {
        int minutes = int.parse(minutesMatch.group(1)!.trim());
        durationValue += minutes;
      }
    } catch (e) {
      log("Exception: $e");
      throw FormatException("Invalid duration format: $duration");
    }

    return durationValue;
  }

  calculateDurationAndDistance() async {
    if (Constant.selectedMapType == 'osm') {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait");
        await Constant.getDurationOsmDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          if (value != {} && value.isNotEmpty) {
            int hours = value['routes'].first['duration'] ~/ 3600;
            int minutes =
                ((value['routes'].first['duration'] % 3600) / 60).round();
            duration.value =
                '$hours ${'hours'.tr} $minutes ${'minutes'.tr}'.trim();
            if (Constant.distanceType == "Km") {
              distance.value =
                  (value['routes'].first['distance'] / 1000).toString();
            } else {
              distance.value =
                  (value['routes'].first['distance'] / 1609.34).toString();
            }
          }
          update();
        });
      }
      ShowToastDialog.closeLoader();
    } else {
      if (sourceLocationLAtLng.value.latitude != null &&
          destinationLocationLAtLng.value.latitude != null) {
        ShowToastDialog.showLoader("Please wait");
        await Constant.getDurationDistance(
                LatLng(sourceLocationLAtLng.value.latitude!,
                    sourceLocationLAtLng.value.longitude!),
                LatLng(destinationLocationLAtLng.value.latitude!,
                    destinationLocationLAtLng.value.longitude!))
            .then((value) {
          final element = (value?.rows?.isNotEmpty == true &&
                  value!.rows!.first.elements?.isNotEmpty == true)
              ? value.rows!.first.elements!.first
              : null;
          final hasRoute = element?.duration?.text != null &&
              element?.distance?.value != null;
          if (hasRoute) {
            duration.value = element!.duration!.text.toString();
            log("duration :: 00 :: ${duration.value}");
            if (Constant.distanceType == "Km") {
              distance.value =
                  (element.distance!.value!.toInt() / 1000).toString();
            } else {
              distance.value =
                  (element.distance!.value!.toInt() / 1609.34).toString();
            }
          } else {
            duration.value = "0";
            distance.value = "0";
            ShowToastDialog.showToast("Path not found".tr);
          }
          update();
        });
        ShowToastDialog.closeLoader();
      }
    }
  }

  calculateAmount() async {
    log('🔢 calculateAmount called: distance="${distance.value}", selectedType.id=${selectedType.value.id}, kmCharge=${selectedType.value.kmCharge}, meterStart=${selectedType.value.meterStart}');
    // Guard: don't calculate if distance or service data not ready yet
    if (distance.value.isEmpty ||
        (double.tryParse(distance.value) ?? 0.0) <= 0.0) {
      log('⚠️ calculateAmount: distance empty or zero, skipping');
      amount.value = "";
      update();
      return;
    }
    if (selectedType.value.id == null || selectedType.value.kmCharge == null) {
      log('⚠️ calculateAmount: selectedType not ready (id=${selectedType.value.id}, kmCharge=${selectedType.value.kmCharge})');
      amount.value = "";
      update();
      return;
    }
    try {
      // New formula: meterStart + (distance × kmCharge) + (optional: minutes × perMinuteCharge)
      double distanceVal = double.tryParse(distance.value) ?? 0.0;
      double meterStartVal =
          double.tryParse(selectedType.value.meterStart ?? '0') ?? 0.0;
      double kmChargeVal =
          double.tryParse(selectedType.value.kmCharge ?? '0') ?? 0.0;
      double perMinuteChargeVal =
          double.tryParse(selectedType.value.perMinuteCharge ?? '0') ?? 0.0;
      bool enableMinuteCharge = selectedType.value.enableMinuteCharge ?? true;

      double durationValueInMinutes = convertToMinutes(duration.value);

      double kmAmount = distanceVal * kmChargeVal;
      double minuteAmount = enableMinuteCharge
          ? (durationValueInMinutes * perMinuteChargeVal)
          : 0.0;

      totalAmount.value = meterStartVal + kmAmount + minuteAmount;
      amount.value = totalAmount.value
          .toStringAsFixed(Constant.currencyModel!.decimalDigits!);

      offerYourRateController.value.text = amount.value;
      log('✅ calculateAmount result: amount=${amount.value}, meterStart=$meterStartVal, kmAmount=$kmAmount, minuteAmount=$minuteAmount');
    } catch (e) {
      log('❌ calculateAmount error: $e');
    }
    update();
  }

  RxList airPortList = <AriPortModel>[].obs;

  getZoneAndUserData() async {
    await FireStoreUtils().getZone().then((value) {
      if (value != null) {
        zoneList.value = value;
      }
    });

    await getUser();
  }

  getUser() async {
    await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid())
        .then((value) {
      if (value != null) {
        userModel.value = value;
      }
    });
  }

  Rx<AriPortModel> selectedAirPort = AriPortModel().obs;

  /// Start the ride-request expiration timer. Duration comes from
  /// `Constant.autoCancelMinutes`, which is loaded from
  /// `settings/globalValue.autoCancelMinutes` — Cloud Functions reads the
  /// SAME field, so client and server stay in lockstep. If the field is
  /// missing or invalid, falls back to the in-code default (6 min).
  void startRideExpirationTimer(String orderId) {
    cancelRideExpirationTimer();
    _activeOrderId = orderId;
    activeOrderId.value = orderId;
    _rideExpirationTimer =
        Timer(Duration(minutes: Constant.autoCancelMinutes), () async {
      try {
        // Re-fetch the order to check if a driver accepted
        DocumentSnapshot orderDoc = await FirebaseFirestore.instance
            .collection(CollectionName.orders)
            .doc(orderId)
            .get();
        if (orderDoc.exists) {
          Map<String, dynamic> data = orderDoc.data() as Map<String, dynamic>;
          if (data['status'] == Constant.ridePlaced) {
            // No driver accepted — cancel the ride
            await FirebaseFirestore.instance
                .collection(CollectionName.orders)
                .doc(orderId)
                .update({
              'status': Constant.rideCanceled,
              'canceledBy': 'system',
              'cancelReason': 'no_driver_found',
              'cancelDate': Timestamp.now(),
            });
            _activeOrderId = '';
            activeOrderId.value = '';
            ShowToastDialog.showToast("No driver found".tr);
          }
        }
      } catch (e) {
        log("Ride expiration timer error: $e");
      } finally {
        _rideExpirationTimer = null;
      }
    });
  }

  /// Cancel the ride expiration timer
  void cancelRideExpirationTimer() {
    _rideExpirationTimer?.cancel();
    _rideExpirationTimer = null;
    _activeOrderId = '';
    activeOrderId.value = '';
  }

  void _startBannerAutoScroll() {
    _bannerAutoScrollTimer?.cancel();

    if (bannerList.length <= 1) {
      return;
    }

    _bannerAutoScrollTimer = Timer.periodic(_bannerAutoScrollInterval, (_) {
      if (!pageController.hasClients || bannerList.isEmpty) {
        return;
      }

      final int currentPage =
          (pageController.page ?? pageController.initialPage.toDouble())
              .round();
      final int nextPage = (currentPage + 1) % bannerList.length;

      pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void onClose() {
    // Keep expiration timer alive even if HomeScreen is disposed after booking.
    activeOrderId.value = _activeOrderId;
    _bannerAutoScrollTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
