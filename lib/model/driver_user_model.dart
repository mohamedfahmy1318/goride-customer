import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/model/driver_rules_model.dart';
import 'package:customer/model/language_name.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/subscription_plan_model.dart';

class DriverUserModel {
  String? phoneNumber;
  String? loginType;
  String? countryCode;
  String? profilePic;
  bool? documentVerification;
  String? fullName;
  bool? isOnline;
  String? id;
  String? serviceId;
  String? fcmToken;
  String? email;
  VehicleInformation? vehicleInformation;
  String? reviewsCount;
  String? reviewsSum;
  String? walletAmount;
  LocationLatLng? location;
  double? rotation;
  Positions? position;
  Timestamp? createdAt;
  List<dynamic>? zoneIds;
  String? subscriptionTotalOrders;
  String? subscriptionPlanId;
  Timestamp? subscriptionExpiryDate;
  SubscriptionPlanModel? subscriptionPlan;

  // حقول جديدة
  String? identityNumber; // رقم الهوية
  String? identityImage; // صورة الهوية
  String? licenseImage; // صورة الرخصة
  bool? isApproved; // الموافقة على فتح الحساب من الإدارة
  Timestamp? approvedAt; // تاريخ الموافقة
  String? language;

  DriverUserModel(
      {this.phoneNumber,
      this.loginType,
      this.countryCode,
      this.profilePic,
      this.documentVerification,
      this.fullName,
      this.isOnline,
      this.id,
      this.serviceId,
      this.fcmToken,
      this.email,
      this.location,
      this.vehicleInformation,
      this.reviewsCount,
      this.reviewsSum,
      this.rotation,
      this.position,
      this.walletAmount,
      this.createdAt,
      this.zoneIds,
      this.subscriptionTotalOrders,
      this.subscriptionPlanId,
      this.subscriptionExpiryDate,
      this.subscriptionPlan,
      this.identityNumber,
      this.identityImage,
      this.licenseImage,
      this.isApproved,
      this.approvedAt,
      this.language});

  DriverUserModel.fromJson(Map<String, dynamic> json) {
    phoneNumber = json['phoneNumber'];
    loginType = json['loginType'];
    countryCode = json['countryCode'];
    profilePic = json['profilePic'] ?? '';
    documentVerification = json['documentVerification'];
    fullName = json['fullName'];
    isOnline = json['isOnline'];
    id = json['id'];
    serviceId = json['serviceId'];
    fcmToken = json['fcmToken'];
    email = json['email'];
    vehicleInformation = json['vehicleInformation'] != null
        ? VehicleInformation.fromJson(json['vehicleInformation'])
        : null;
    reviewsCount = json['reviewsCount'] ?? '0.0';
    reviewsSum = json['reviewsSum'] ?? '0.0';
    rotation = json['rotation'] != null
        ? double.parse(json['rotation'].toString())
        : 0.0;
    walletAmount = json['walletAmount'] ?? "0.0";
    location = json['location'] != null
        ? LocationLatLng.fromJson(json['location'])
        : null;
    position =
        json['position'] != null ? Positions.fromJson(json['position']) : null;
    createdAt = json['createdAt'];
    zoneIds = json['zoneIds'];
    subscriptionTotalOrders = json['subscriptionTotalOrders'];
    subscriptionPlanId = json['subscriptionPlanId'];
    subscriptionExpiryDate = json['subscriptionExpiryDate'];
    subscriptionPlan = json['subscription_plan'] != null
        ? SubscriptionPlanModel.fromJson(json['subscription_plan'])
        : null;
    // حقول جديدة
    identityNumber = json['identityNumber'];
    identityImage = json['identityImage'];
    licenseImage = json['licenseImage'];
    isApproved = json['isApproved'] ?? false;
    approvedAt = json['approvedAt'];
    language = json['language'] ?? 'ar';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phoneNumber'] = phoneNumber;
    data['loginType'] = loginType;
    data['countryCode'] = countryCode;
    data['profilePic'] = profilePic;
    data['documentVerification'] = documentVerification;
    data['fullName'] = fullName;
    data['isOnline'] = isOnline;
    data['id'] = id;
    data['serviceId'] = serviceId;
    data['fcmToken'] = fcmToken;
    data['email'] = email;
    data['rotation'] = rotation;
    data['createdAt'] = createdAt;
    if (vehicleInformation != null) {
      data['vehicleInformation'] = vehicleInformation!.toJson();
    }
    if (location != null) {
      data['location'] = location!.toJson();
    }
    data['reviewsCount'] = reviewsCount;
    data['reviewsSum'] = reviewsSum;
    data['walletAmount'] = walletAmount;
    data['zoneIds'] = zoneIds;
    if (position != null) {
      data['position'] = position!.toJson();
    }
    data['subscriptionTotalOrders'] = subscriptionTotalOrders;
    data['subscriptionPlanId'] = subscriptionPlanId;
    data['subscriptionExpiryDate'] = subscriptionExpiryDate;
    data['subscription_plan'] = subscriptionPlan?.toJson();
    // حقول جديدة
    data['identityNumber'] = identityNumber;
    data['identityImage'] = identityImage;
    data['licenseImage'] = licenseImage;
    data['isApproved'] = isApproved;
    data['approvedAt'] = approvedAt;
    data['language'] = language;
    return data;
  }
}

class VehicleInformation {
  List<LanguageName>? vehicleType;
  String? vehicleTypeId;
  Timestamp? registrationDate;
  String? vehicleColor;
  String? vehicleNumber;
  String? acPerKmRate;
  String? nonAcPerKmRate;
  String? perKmRate;
  String? seats;
  List<DriverRulesModel>? driverRules;

  // حقول جديدة للسيارة
  String? plateImageFront; // صورة اللوحة الأمامية
  String? plateImageBack; // صورة اللوحة الخلفية
  String? registrationImage; // صورة الاستمارة
  String? insuranceImage; // صورة التأمين
  String? authorizationImage; // صورة التفويض

  VehicleInformation(
      {this.vehicleType,
      this.vehicleTypeId,
      this.registrationDate,
      this.vehicleColor,
      this.vehicleNumber,
      this.acPerKmRate,
      this.nonAcPerKmRate,
      this.perKmRate,
      this.seats,
      this.driverRules,
      this.plateImageFront,
      this.plateImageBack,
      this.registrationImage,
      this.insuranceImage,
      this.authorizationImage});

  VehicleInformation.fromJson(Map<String, dynamic> json) {
    if (json['vehicleType'] != null) {
      vehicleType = <LanguageName>[];
      json['vehicleType'].forEach((v) {
        vehicleType!.add(LanguageName.fromJson(v));
      });
    }
    vehicleTypeId = json['vehicleTypeId'];
    registrationDate = json['registrationDate'];
    vehicleColor = json['vehicleColor'];
    vehicleNumber = json['vehicleNumber'];
    acPerKmRate = json['acPerKmRate'];
    nonAcPerKmRate = json['nonAcPerKmRate'];
    perKmRate = json['perKmRate'];
    seats = json['seats'];
    if (json['driverRules'] != null) {
      driverRules = <DriverRulesModel>[];
      json['driverRules'].forEach((v) {
        driverRules!.add(DriverRulesModel.fromJson(v));
      });
    }
    // حقول جديدة
    plateImageFront = json['plateImageFront'];
    plateImageBack = json['plateImageBack'];
    registrationImage = json['registrationImage'];
    insuranceImage = json['insuranceImage'];
    authorizationImage = json['authorizationImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (vehicleType != null) {
      data['vehicleType'] = vehicleType!.map((v) => v.toJson()).toList();
    }
    data['vehicleTypeId'] = vehicleTypeId;
    data['registrationDate'] = registrationDate;
    data['vehicleColor'] = vehicleColor;
    data['vehicleNumber'] = vehicleNumber;
    data['acPerKmRate'] = acPerKmRate;
    data['nonAcPerKmRate'] = nonAcPerKmRate;
    data['perKmRate'] = perKmRate;
    data['seats'] = seats;
    if (driverRules != null) {
      data['driverRules'] = driverRules!.map((v) => v.toJson()).toList();
    }
    // حقول جديدة
    data['plateImageFront'] = plateImageFront;
    data['plateImageBack'] = plateImageBack;
    data['registrationImage'] = registrationImage;
    data['insuranceImage'] = insuranceImage;
    data['authorizationImage'] = authorizationImage;
    return data;
  }
}
