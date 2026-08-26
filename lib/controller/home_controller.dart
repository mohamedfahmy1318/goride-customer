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
import 'package:customer/model/place_picker_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/user_model.dart';
import 'package:customer/model/zone_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/services/location_resolver.dart';
import 'package:customer/utils/address_formatter.dart';
import 'package:customer/utils/fire_store_utils.dart';
import 'package:customer/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  Rx<ResolvedAddress> sourceAddress = ResolvedAddress.empty.obs;
  Rx<ResolvedAddress> destinationAddress = ResolvedAddress.empty.obs;
  RxBool isLocatingUser = false.obs;
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

  /// Resolves the rider's pickup: an accuracy-checked GPS fix plus a
  /// two-line address (venue/street + neighbourhood, city). Both come from
  /// [LocationResolver], the same pipeline the place picker uses, so the
  /// pickup we ship to the driver reads identically wherever it is shown.
  Future<void> getLocation({bool forceFresh = false}) async {
    isLocatingUser.value = true;
    try {
      final position =
          await LocationResolver.currentPosition(forceFresh: forceFresh);

      final address = await LocationResolver.resolve(
        position.latitude,
        position.longitude,
      );

      sourceAddress.value = address;
      currentLocation.value = address.display;
      sourceLocationLAtLng.value = LocationLatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      sourceLocationController.value.text = address.display;
    } on LocationUnavailable catch (e) {
      ShowToastDialog.showToast(
        _locationErrorMessage(e.reason),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      log('getLocation failed: $e');
      ShowToastDialog.showToast(
        "Couldn't determine your location. Please try again.".tr,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLocatingUser.value = false;
    }
  }

  String _locationErrorMessage(String reason) {
    switch (reason) {
      case 'service_off':
        return 'Please turn on location services to book a ride.'.tr;
      case 'denied_forever':
        return 'Location permission is blocked. Enable it from your device settings.'
            .tr;
      case 'denied':
        return 'Location permission is required to set your pickup point.'.tr;
      default:
        return "Couldn't determine your location. Please try again.".tr;
    }
  }

  /// Applies a point the rider chose on the map / from search as the pickup.
  /// Riders correct GPS drift this way — the same escape hatch Uber and
  /// Careem give when the pin lands on the wrong side of the street.
  Future<void> applySourcePlace(PlaceDetailsModel details) async {
    final location = details.result?.geometry?.location;
    if (location?.lat == null || location?.lng == null) return;
    sourceAddress.value = _addressFromPlace(details);
    sourceLocationController.value.text = sourceAddress.value.display;
    currentLocation.value = sourceAddress.value.display;
    sourceLocationLAtLng.value =
        LocationLatLng(latitude: location!.lat, longitude: location.lng);
    if (destinationLocationLAtLng.value.latitude != null) {
      await calculateDurationAndDistance();
    }
    calculateAmount();
  }

  Future<void> applyDestinationPlace(PlaceDetailsModel details) async {
    final location = details.result?.geometry?.location;
    if (location?.lat == null || location?.lng == null) return;
    destinationAddress.value = _addressFromPlace(details);
    destinationLocationController.value.text = destinationAddress.value.display;
    destinationLocationLAtLng.value =
        LocationLatLng(latitude: location!.lat, longitude: location.lng);
    await calculateDurationAndDistance();
    calculateAmount();
  }

  /// The picker carries the venue name in `result.name` and the placing line
  /// in `result.vicinity`; older/OSM pickers only fill `formattedAddress`, so
  /// fall back to splitting that.
  ResolvedAddress _addressFromPlace(PlaceDetailsModel details) {
    final result = details.result;
    final name = (result?.name ?? '').trim();
    final vicinity = (result?.vicinity ?? '').trim();
    if (name.isNotEmpty) {
      return ResolvedAddress(
        title: name,
        subtitle: AddressFormatter.clean(vicinity),
        components: result?.addressComponents ?? const [],
      );
    }
    final formatted = (result?.formattedAddress ?? '').trim();
    final parts = formatted
        .split(RegExp(r'[,،]'))
        .map((p) => p.trim())
        .where((p) => !AddressFormatter.isNoise(p))
        .toList();
    if (parts.isEmpty) {
      return ResolvedAddress(title: formatted);
    }
    return ResolvedAddress(
      title: parts.first,
      subtitle: parts.skip(1).take(2).join('، '),
      components: result?.addressComponents ?? const [],
    );
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

      // Reuse the token cached this session (seeded by getToken()/onTokenRefresh)
      // instead of issuing a fresh FCM registration on every HomeController
      // rebuild — that churn is part of the TOO_MANY_REGISTRATIONS leak. Only
      // fall back to a live getToken() if we have nothing cached yet.
      String? token = Constant.fcmToken ?? await NotificationService.getToken();
      final profile =
          await FireStoreUtils.getUserProfile(FireStoreUtils.getCurrentUid());
      if (profile != null) {
        userModel.value = profile;
        if (token != null && token.isNotEmpty) {
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

  /// Tax locked into the quote using the same saved tax snapshot as booking.
  double get quotedTaxAmount {
    final double subTotal = double.tryParse(amount.value) ?? 0;
    final taxable =
        (subTotal - discountAmount.value).clamp(0, double.infinity).toDouble();
    var taxTotal = 0.0;
    for (final tax in Constant.taxList ?? []) {
      if (tax.enable == false) continue;
      taxTotal +=
          Constant().calculateTax(amount: taxable.toString(), taxModel: tax);
    }
    return taxTotal;
  }

  /// Computed: what the customer actually pays (subtotal − discount + tax).
  /// this at placement time and via Obx in the breakdown widget.
  double get finalPayable {
    final double subTotal = double.tryParse(amount.value) ?? 0;
    final discounted =
        (subTotal - discountAmount.value).clamp(0, double.infinity).toDouble();
    return discounted + quotedTaxAmount;
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
