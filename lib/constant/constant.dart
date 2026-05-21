// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/show_toast_dialog.dart';
import 'package:customer/model/ChatVideoContainer.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/airport_model.dart';
import 'package:customer/model/conversation_model.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/currency_model.dart';
import 'package:customer/model/language_description.dart';
import 'package:customer/model/language_model.dart';
import 'package:customer/model/language_name.dart';
import 'package:customer/model/language_privacy_policy.dart';
import 'package:customer/model/language_terms_condition.dart';
import 'package:customer/model/language_title.dart';
import 'package:customer/model/map_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/themes/app_colors.dart';
import 'package:customer/utils/Preferences.dart';
import 'package:customer/utils/url_launcher_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Constant {
  static const String phoneLoginType = "phone";
  static const String googleLoginType = "google";
  static const String appleLoginType = "apple";
  static String mapAPIKey = "";
  static String senderId = '';
  static String jsonNotificationFileURL = '';
  static String radius = "10";
  static String distanceType = "";
  static CurrencyModel? currencyModel;
  static AdminCommission? adminCommission;
  static String? referralAmount = "0";
  static String? supportURL = "";
  static const commissionSubscriptionID = "J0RwvxCWhZzQQD7Kc2Ll";

  static List<LanguageTermsCondition> termsAndConditions = [];
  static List<LanguagePrivacyPolicy> privacyPolicy = [];
  static String appVersion = "";

  static String mapType = "google";
  static String selectedMapType = 'osm';
  static String driverLocationUpdate = "10";
  static String regionCode = "MR";
  static String regionCountry = "Mauritania";
  static int totalHoldingCharges = 0;

  static const String ridePlaced = "Ride Placed";
  static const String rideActive = "Ride Active";
  static const String rideDriverArrived = "Driver Arrived";
  static const String rideInProgress = "Ride InProgress";
  static const String rideComplete = "Ride Completed";
  static const String rideCanceled = "Ride Canceled";
  static const String rideHold = "Ride Hold";
  static const String rideHoldAccepted = "Ride Hold Accepted";

  static const globalUrl =
      "https://goride.sisا ف الفاير استور مع اني بحطwebapp.com/";

  /// Legacy Firebase Storage URL for the user placeholder image. Kept as a
  /// string for backward compatibility with any external caller, but DO NOT
  /// use it — the object is missing in `goride-a9d8f` (404s). Use
  /// [safeImageUrl] + [buildUserAvatar] / [placeholderWidget] instead.
  @Deprecated('Missing in Firebase Storage; use buildUserAvatar() instead')
  static const userPlaceHolder =
      "https://firebasestorage.googleapis.com/v0/b/goride-a9d8f.firebasestorage.app/o/placeholderImages%2Fuser-placeholder.jpeg?alt=media";

  /// Returns a safe image URL. Null / empty / the literal string "null" all
  /// collapse to an empty string so callers never attempt a network request
  /// for a placeholder that isn't there. The broken Firebase Storage URL
  /// used to be returned here — every missing-avatar render 404'd against
  /// Storage and spammed Crashlytics. Pair with CachedNetworkImage's
  /// `errorWidget` (or the [buildUserAvatar] helper) to get a local
  /// placeholder without any network call.
  static String safeImageUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') {
      return '';
    }
    return url;
  }

  /// Local placeholder widget for user profile images. Pure Flutter, no
  /// network. Size adapts to the [height]/[width] passed in, and renders
  /// a circular avatar when the two match.
  ///
  /// If you drop `assets/images/user_placeholder.png` into the project, you
  /// can swap the Icon below for `Image.asset` with an `errorBuilder` that
  /// falls back to the Icon — that keeps this helper crash-safe even if the
  /// asset is ever missing from the bundle.
  static Widget placeholderWidget({
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: height == width ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Icon(
        Icons.person,
        size: (height ?? 50) * 0.6,
        color: Colors.grey[600],
      ),
    );
  }

  /// One-stop user avatar. Short-circuits to [placeholderWidget] when the
  /// URL is missing — NO network call, no 404 spam. Otherwise renders a
  /// [CachedNetworkImage] whose `errorWidget` is also [placeholderWidget],
  /// so any transient HTTP failure (including the legacy 404 placeholder
  /// URL that still lives on some user docs) degrades gracefully.
  ///
  /// Use this instead of hand-rolling CachedNetworkImage + safeImageUrl at
  /// every call site.
  static Widget buildUserAvatar({
    String? url,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    final resolved = safeImageUrl(url);
    if (resolved.isEmpty) {
      return placeholderWidget(height: height, width: width, fit: fit);
    }
    return CachedNetworkImage(
      imageUrl: resolved,
      height: height,
      width: width,
      fit: fit,
      placeholder: (_, __) =>
          placeholderWidget(height: height, width: width, fit: fit),
      errorWidget: (_, __, ___) =>
          placeholderWidget(height: height, width: width, fit: fit),
    );
  }

  static Position? currentLocation;
  static String? country;
  static String? city;
  static List<TaxModel>? taxList;
  static List<AriPortModel>? airaPortList;

  static Widget loader() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.darkModePrimary),
    );
  }

  static String localizationName(List<LanguageName>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .name!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .name!;
    } else {
      return name.firstWhere((element) => element.type == "en").name.toString();
    }
  }

  static String localizationDescription(List<LanguageDescription>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .description!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .description!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .description
          .toString();
    }
  }

  static String localizationTitle(List<LanguageTitle>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .title!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .title!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .title
          .toString();
    }
  }

  static String localizationPrivacyPolicy(List<LanguagePrivacyPolicy>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .privacyPolicy!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .privacyPolicy!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .privacyPolicy
          .toString();
    }
  }

  static String localizationTermsCondition(List<LanguageTermsCondition>? name) {
    if (name!
        .firstWhere((element) => element.type == Constant.getLanguage().code)
        .termsAndConditions!
        .isNotEmpty) {
      return name
          .firstWhere((element) => element.type == Constant.getLanguage().code)
          .termsAndConditions!;
    } else {
      return name
          .firstWhere((element) => element.type == "en")
          .termsAndConditions
          .toString();
    }
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    await UrlLauncherUtils.launchPhoneCall(phoneNumber);
  }

  static Future<void> openWhatsApp(String phoneNumber) async {
    await UrlLauncherUtils.launchWhatsApp(phoneNumber);
  }

  static bool? validateEmail(String? value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(value ?? '')) {
      return false;
    } else {
      return true;
    }
  }

  static bool isPointInPolygon(LatLng point, List<GeoPoint> polygon) {
    int crossings = 0;
    for (int i = 0; i < polygon.length; i++) {
      int next = (i + 1) % polygon.length;
      if (polygon[i].latitude <= point.latitude &&
              polygon[next].latitude > point.latitude ||
          polygon[i].latitude > point.latitude &&
              polygon[next].latitude <= point.latitude) {
        double edgeLong = polygon[next].longitude - polygon[i].longitude;
        double edgeLat = polygon[next].latitude - polygon[i].latitude;
        double interpol = (point.latitude - polygon[i].latitude) / edgeLat;
        if (point.longitude < polygon[i].longitude + interpol * edgeLong) {
          crossings++;
        }
      }
    }
    log("=====isPointInPolygon=${(crossings % 2 != 0)}");
    return (crossings % 2 != 0);
  }

  static Future<MapModel?> getDurationDistance(
    LatLng departureLatLong,
    LatLng destinationLatLong,
  ) async {
    String url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
    http.Response restaurantToCustomerTime = await http.get(
      Uri.parse(
        '$url?units=metric&origins=${departureLatLong.latitude},'
        '${departureLatLong.longitude}&destinations=${destinationLatLong.latitude},${destinationLatLong.longitude}&key=${Constant.mapAPIKey}',
      ),
    );

    log(restaurantToCustomerTime.body.toString());
    MapModel mapModel = MapModel.fromJson(
      jsonDecode(restaurantToCustomerTime.body),
    );

    if (mapModel.status == 'OK' &&
        mapModel.rows!.first.elements!.first.status == "OK") {
      return mapModel;
    } else {
      final elementStatus =
          mapModel.rows?.first.elements?.first.status ?? mapModel.status;
      ShowToastDialog.showToast(mapModel.errorMessage ??
          (elementStatus == "ZERO_RESULTS"
              ? "No driving route found between these locations.".tr
              : "Could not calculate distance. Please try again.".tr));
    }
    return null;
  }

  static Future<Map<String, dynamic>> getDurationOsmDistance(
    LatLng departureLatLong,
    LatLng destinationLatLong,
  ) async {
    String url = 'https://router.project-osrm.org/route/v1/driving';
    String coordinates =
        '${departureLatLong.longitude},${departureLatLong.latitude};${destinationLatLong.longitude},${destinationLatLong.latitude}';

    http.Response response = await http.get(
      Uri.parse('$url/$coordinates?overview=false&steps=false'),
    );

    return jsonDecode(response.body);
  }

  static double amountCalculate(String amount, String distance) {
    double finalAmount = 0.0;
    log("------->");
    log(amount);
    log(distance);
    finalAmount = double.parse(amount) * double.parse(distance);
    return finalAmount;
  }

  static String getUuid() {
    return const Uuid().v4();
  }

  String formatTimestamp(Timestamp? timestamp) {
    var format = DateFormat('dd-MM-yyyy hh:mm aa'); // <- use skeleton here
    return format.format(timestamp!.toDate());
  }

  static String dateAndTimeFormatTimestamp(Timestamp? timestamp) {
    var format = DateFormat('dd MMM yyyy hh:mm aa'); // <- use skeleton here
    return format.format(timestamp!.toDate());
  }

  static String dateFormatTimestamp(Timestamp? timestamp) {
    var format = DateFormat('dd MMM yyyy'); // <- use skeleton here
    return format.format(timestamp!.toDate());
  }

  double calculateTax({String? amount, TaxModel? taxModel}) {
    double taxAmount = 0.0;
    if (taxModel != null && taxModel.enable == true) {
      if (taxModel.type == "fix") {
        taxAmount = double.parse(taxModel.tax.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(taxModel.tax!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  static String amountShow({required String? amount}) {
    if (Constant.currencyModel!.symbolAtRight == true) {
      return "${double.parse(amount.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)} ${Constant.currencyModel!.symbol.toString()}";
    } else {
      return "${Constant.currencyModel!.symbol.toString()} ${double.parse(amount.toString()).toStringAsFixed(Constant.currencyModel!.decimalDigits!)}";
    }
  }

  static double calculateOrderAdminCommission({
    String? amount,
    AdminCommission? adminCommission,
  }) {
    double taxAmount = 0.0;
    if (adminCommission != null) {
      if (adminCommission.type == "fix") {
        taxAmount = double.parse(adminCommission.amount.toString());
      } else {
        taxAmount = (double.parse(amount.toString()) *
                double.parse(adminCommission.amount!.toString())) /
            100;
      }
    }
    return taxAmount;
  }

  /// Returns the absolute discount amount (never negative, never greater than
  /// [subTotal]) implied by a coupon applied to a subtotal. Shared by the
  /// booking sheet preview, the placement-time persistence, and any receipt
  /// screens that re-derive from OrderModel — single source of truth.
  static double calculateCouponDiscount({
    required double subTotal,
    required CouponModel coupon,
  }) {
    if (coupon.enable != true) return 0;
    final double raw = double.tryParse(coupon.amount?.toString() ?? '0') ?? 0;
    if (raw <= 0) return 0;
    final double discount = coupon.type == 'fix' ? raw : (subTotal * raw) / 100;
    if (discount.isNaN || discount.isInfinite) return 0;
    // Cap at subtotal so the final payable never goes negative.
    return discount.clamp(0, subTotal).toDouble();
  }

  static String calculateReview({
    required String? reviewCount,
    required String? reviewSum,
  }) {
    if (reviewCount == "0.0" && reviewSum == "0.0") {
      return "0.0";
    }
    return (double.parse(reviewSum.toString()) /
            double.parse(reviewCount.toString()))
        .toStringAsFixed(Constant.currencyModel!.decimalDigits!);
  }

  static bool IsNegative(double number) {
    return number < 0;
  }

  static LanguageModel getLanguage() {
    final String user = Preferences.getString(Preferences.languageCodeKey);
    if (user.isEmpty) {
      return LanguageModel(code: "en", name: "English", isDefault: true);
    }
    try {
      Map<String, dynamic> userMap = jsonDecode(user);
      return LanguageModel.fromJson(userMap);
    } catch (e) {
      return LanguageModel(code: "en", name: "English", isDefault: true);
    }
  }

  static String getReferralCode() {
    var rng = math.Random();
    return (rng.nextInt(900000) + 100000).toString();
  }

  bool hasValidUrl(String value) {
    String pattern =
        r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
    RegExp regExp = RegExp(pattern);
    if (value.isEmpty) {
      return false;
    } else if (!regExp.hasMatch(value)) {
      return false;
    }
    return true;
  }

  static Future<String> uploadUserImageToFireStorage(
    File image,
    String filePath,
    String fileName,
  ) async {
    Reference upload = FirebaseStorage.instance.ref().child(
          '$filePath/$fileName',
        );
    UploadTask uploadTask = upload.putFile(image);
    var downloadUrl = await (await uploadTask.whenComplete(
      () {},
    ))
        .ref
        .getDownloadURL();
    return downloadUrl.toString();
  }

  Future<Url> uploadChatImageToFireStorage(File image) async {
    ShowToastDialog.showLoader('Uploading image...');
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child(
          '/chat/images/$uniqueID.png',
        );
    UploadTask uploadTask = upload.putFile(image);
    var storageRef = (await uploadTask.whenComplete(() {})).ref;
    var downloadUrl = await storageRef.getDownloadURL();
    var metaData = await storageRef.getMetadata();
    ShowToastDialog.closeLoader();
    return Url(
      mime: metaData.contentType ?? 'image',
      url: downloadUrl.toString(),
    );
  }

  Future<ChatVideoContainer?> uploadChatVideoToFireStorage(File video) async {
    try {
      ShowToastDialog.showLoader("Uploading video...");
      final String uniqueID = const Uuid().v4();
      final Reference videoRef = FirebaseStorage.instance.ref(
        'videos/$uniqueID.mp4',
      );
      final UploadTask uploadTask = videoRef.putFile(
        video,
        SettableMetadata(contentType: 'video/mp4'),
      );
      await uploadTask;
      final String videoUrl = await videoRef.getDownloadURL();
      ShowToastDialog.showLoader("Generating thumbnail...");
      final Uint8List thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        maxWidth: 200,
        quality: 75,
      );

      if (thumbnailBytes.isEmpty) {
        throw Exception("Failed to generate thumbnail.");
      }

      final String thumbnailID = const Uuid().v4();
      final Reference thumbnailRef = FirebaseStorage.instance.ref(
        'thumbnails/$thumbnailID.jpg',
      );
      final UploadTask thumbnailUploadTask = thumbnailRef.putData(
        thumbnailBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      await thumbnailUploadTask;
      final String thumbnailUrl = await thumbnailRef.getDownloadURL();
      var metaData = await thumbnailRef.getMetadata();
      ShowToastDialog.closeLoader();

      return ChatVideoContainer(
        videoUrl: Url(
          url: videoUrl.toString(),
          mime: metaData.contentType ?? 'video',
          videoThumbnail: thumbnailUrl,
        ),
        thumbnailUrl: thumbnailUrl,
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Error: ${e.toString()}");
      return null;
    }
  }

  Future<String> uploadVideoThumbnailToFireStorage(File file) async {
    var uniqueID = const Uuid().v4();
    Reference upload = FirebaseStorage.instance.ref().child(
          '/thumbnails/$uniqueID.png',
        );
    UploadTask uploadTask = upload.putFile(file);
    var downloadUrl = await (await uploadTask.whenComplete(
      () {},
    ))
        .ref
        .getDownloadURL();
    return downloadUrl.toString();
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!
        .buffer
        .asUint8List();
  }
}
