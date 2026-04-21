import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/contact_model.dart';
import 'package:customer/model/coupon_model.dart';
import 'package:customer/model/driver_user_model.dart';
import 'package:customer/model/order/location_lat_lng.dart';
import 'package:customer/model/order/positions.dart';
import 'package:customer/model/service_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:customer/model/zone_model.dart';

class OrderModel {
  String? sourceLocationName;
  String? destinationLocationName;
  String? paymentType;
  LocationLatLng? sourceLocationLAtLng;
  LocationLatLng? destinationLocationLAtLng;
  String? id;
  String? serviceId;
  String? userId;
  String? offerRate;
  String? finalRate;
  String? distance;
  String? distanceType;
  String? status;
  String? driverId;
  String? duration;
  String? otp;
  String? totalHoldingCharges;
  String? acNonAcCharges;
  String? rideHoldTimeMinutes;
  List<dynamic>? acceptedDriverId;
  List<dynamic>? rejectedDriverId;
  List<dynamic>? notifiedDriverIds;
  Positions? position;
  Timestamp? createdDate;
  Timestamp? updateDate;
  Timestamp? acceptHoldTime;
  bool? paymentStatus;
  bool? isAcSelected;
  List<TaxModel>? taxList;
  ContactModel? someOneElse;
  CouponModel? coupon;
  ServiceModel? service;
  AdminCommission? adminCommission;
  ZoneModel? zone;
  String? zoneId;
  String? dispatchMode;
  Map<String, dynamic>? dispatchConfig;
  VehicleInformation? vehicleInformation;
  bool? destinationless;
  bool? isAdminCreated;
  String? actualDistance;
  String? actualDuration;
  Timestamp? rideStartTime;
  String? totalFare;
  String? adminCommissionAmount;
  String? driverEarnings;
  String? discountAmount;
  String? finalPayableAmount;

  OrderModel(
      {this.position,
      this.serviceId,
      this.paymentType,
      this.sourceLocationName,
      this.destinationLocationName,
      this.sourceLocationLAtLng,
      this.destinationLocationLAtLng,
      this.id,
      this.userId,
      this.distance,
      this.distanceType,
      this.status,
      this.driverId,
      this.duration,
      this.otp,
      this.totalHoldingCharges,
      this.acNonAcCharges,
      this.rideHoldTimeMinutes,
      this.notifiedDriverIds,
      this.offerRate,
      this.finalRate,
      this.paymentStatus,
      this.isAcSelected,
      this.createdDate,
      this.updateDate,
      this.acceptHoldTime,
      this.taxList,
      this.coupon,
      this.someOneElse,
      this.service,
      this.adminCommission,
      this.zone,
      this.vehicleInformation,
      this.zoneId,
      this.dispatchMode,
      this.dispatchConfig,
      this.destinationless,
      this.isAdminCreated,
      this.actualDistance,
      this.actualDuration,
      this.rideStartTime,
      this.totalFare,
      this.adminCommissionAmount,
      this.driverEarnings,
      this.discountAmount,
      this.finalPayableAmount});

  OrderModel.fromJson(Map<String, dynamic> json) {
    serviceId = json['serviceId'];
    sourceLocationName = json['sourceLocationName'];
    paymentType = json['paymentType'];
    destinationLocationName = json['destinationLocationName'];
    sourceLocationLAtLng = json['sourceLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['sourceLocationLAtLng'])
        : null;
    destinationLocationLAtLng = json['destinationLocationLAtLng'] != null
        ? LocationLatLng.fromJson(json['destinationLocationLAtLng'])
        : null;
    coupon =
        json['coupon'] != null ? CouponModel.fromJson(json['coupon']) : null;
    someOneElse = json['someOneElse'] != null
        ? ContactModel.fromJson(json['someOneElse'])
        : null;
    vehicleInformation = json['vehicleInformation'] != null
        ? VehicleInformation.fromJson(json['vehicleInformation'])
        : null;
    id = json['id'];
    userId = json['userId'];
    offerRate = json['offerRate'];
    finalRate = json['finalRate'] ?? '0.0';
    distance = json['distance'];
    distanceType = json['distanceType'];
    status = json['status'];
    driverId = json['driverId'];
    duration = json['duration'];
    otp = json['otp'];
    totalHoldingCharges = json['totalHoldingCharges'] ?? "0.0";
    acNonAcCharges = json['acNonAcCharges'];
    rideHoldTimeMinutes = json['rideHoldTimeMinutes'];
    createdDate = json['createdDate'];
    updateDate = json['updateDate'];
    acceptHoldTime = json['acceptHoldTime'];
    acceptedDriverId = json['acceptedDriverId'];
    rejectedDriverId = json['rejectedDriverId'];
    notifiedDriverIds = json['notifiedDriverIds'];
    paymentStatus = json['paymentStatus'];
    isAcSelected = json['isAcSelected'];
    destinationless = json['destinationless'] ?? false;
    isAdminCreated = json['isAdminCreated'] ?? false;
    dispatchMode = json['dispatchMode'];
    dispatchConfig = json['dispatchConfig'] != null
        ? Map<String, dynamic>.from(json['dispatchConfig'])
        : null;
    actualDistance = json['actualDistance'];
    actualDuration = json['actualDuration'];
    rideStartTime = json['rideStartTime'];
    totalFare = json['totalFare']?.toString();
    adminCommissionAmount = json['adminCommissionAmount']?.toString();
    driverEarnings = json['driverEarnings']?.toString();
    discountAmount = json['discountAmount']?.toString();
    finalPayableAmount = json['finalPayableAmount']?.toString();
    position =
        json['position'] != null ? Positions.fromJson(json['position']) : null;
    service =
        json['service'] != null ? ServiceModel.fromJson(json['service']) : null;
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : null;
    zone = json['zone'] != null ? ZoneModel.fromJson(json['zone']) : null;
    zoneId = json['zoneId'];
    if (json['taxList'] != null) {
      taxList = <TaxModel>[];
      json['taxList'].forEach((v) {
        taxList!.add(TaxModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['serviceId'] = serviceId;
    data['sourceLocationName'] = sourceLocationName;
    data['destinationLocationName'] = destinationLocationName;
    if (sourceLocationLAtLng != null) {
      data['sourceLocationLAtLng'] = sourceLocationLAtLng!.toJson();
    }
    if (coupon != null) {
      data['coupon'] = coupon!.toJson();
    }
    if (vehicleInformation != null) {
      data['vehicleInformation'] = vehicleInformation!.toJson();
    }
    if (someOneElse != null) {
      data['someOneElse'] = someOneElse!.toJson();
    }
    if (destinationLocationLAtLng != null) {
      data['destinationLocationLAtLng'] = destinationLocationLAtLng!.toJson();
    }
    if (service != null) {
      data['service'] = service!.toJson();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    if (zone != null) {
      data['zone'] = zone!.toJson();
    }
    data['zoneId'] = zoneId;
    data['id'] = id;
    data['userId'] = userId;
    data['paymentType'] = paymentType;
    data['offerRate'] = offerRate;
    data['finalRate'] = finalRate;
    data['distance'] = distance;
    data['distanceType'] = distanceType;
    data['status'] = status;
    data['driverId'] = driverId;
    data['duration'] = duration;
    data['otp'] = otp;
    data['totalHoldingCharges'] = totalHoldingCharges;
    data['acNonAcCharges'] = acNonAcCharges;
    data['rideHoldTimeMinutes'] = rideHoldTimeMinutes;
    data['createdDate'] = createdDate;
    data['updateDate'] = updateDate;
    data['acceptHoldTime'] = acceptHoldTime;
    data['acceptedDriverId'] = acceptedDriverId;
    data['rejectedDriverId'] = rejectedDriverId;
    data['notifiedDriverIds'] = notifiedDriverIds;
    data['paymentStatus'] = paymentStatus;
    data['isAcSelected'] = isAcSelected;
    data['destinationless'] = destinationless ?? false;
    data['isAdminCreated'] = isAdminCreated ?? false;
    data['dispatchMode'] = dispatchMode;
    if (dispatchConfig != null) {
      data['dispatchConfig'] = dispatchConfig;
    }
    if (actualDistance != null) data['actualDistance'] = actualDistance;
    if (actualDuration != null) data['actualDuration'] = actualDuration;
    if (rideStartTime != null) data['rideStartTime'] = rideStartTime;
    if (totalFare != null) data['totalFare'] = totalFare;
    if (adminCommissionAmount != null) {
      data['adminCommissionAmount'] = adminCommissionAmount;
    }
    if (driverEarnings != null) data['driverEarnings'] = driverEarnings;
    if (discountAmount != null) data['discountAmount'] = discountAmount;
    if (finalPayableAmount != null) {
      data['finalPayableAmount'] = finalPayableAmount;
    }
    if (taxList != null) {
      data['taxList'] = taxList!.map((v) => v.toJson()).toList();
    }
    if (position != null) {
      data['position'] = position!.toJson();
    }
    return data;
  }
}
