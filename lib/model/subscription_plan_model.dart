import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/constant/constant.dart';

class SubscriptionPlanModel {
  Timestamp? createdAt;
  String? description;
  String? descriptionAr;
  String? expiryDay;
  String? id;
  bool? isEnable;
  String? bookingLimit;
  String? name;
  String? nameAr;
  String? price;
  String? place;
  String? image;
  String? type;
  List<String>? planPoints;
  List<String>? planPointsAr;

  SubscriptionPlanModel(
      {this.createdAt,
      this.description,
      this.descriptionAr,
      this.expiryDay,
      this.id,
      this.isEnable,
      this.bookingLimit,
      this.name,
      this.nameAr,
      this.price,
      this.place,
      this.image,
      this.type,
      this.planPoints,
      this.planPointsAr});

  /// Returns the localized name based on current app language
  String get localizedName {
    try {
      final code = Constant.getLanguage().code ?? 'en';
      if (code == 'ar' && nameAr != null && nameAr!.isNotEmpty) {
        return nameAr!;
      }
    } catch (_) {}
    return name ?? '';
  }

  /// Returns the localized description based on current app language
  String get localizedDescription {
    try {
      final code = Constant.getLanguage().code ?? 'en';
      if (code == 'ar' && descriptionAr != null && descriptionAr!.isNotEmpty) {
        return descriptionAr!;
      }
    } catch (_) {}
    return description ?? '';
  }

  /// Returns the localized plan points based on current app language
  List<String> get localizedPlanPoints {
    try {
      final code = Constant.getLanguage().code ?? 'en';
      if (code == 'ar' && planPointsAr != null && planPointsAr!.isNotEmpty) {
        return planPointsAr!;
      }
    } catch (_) {}
    return planPoints ?? [];
  }

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      createdAt: json['createdAt'],
      description: json['description'],
      descriptionAr: json['description_ar'],
      expiryDay: json['expiryDay'],
      id: json['id'],
      isEnable: json['isEnable'],
      bookingLimit: json['bookingLimit'],
      name: json['name'],
      nameAr: json['name_ar'],
      price: json['price'],
      place: json['place'],
      image: json['image'],
      type: json['type'],
      planPoints: json['plan_points'] == null
          ? []
          : List<String>.from(json['plan_points']),
      planPointsAr: json['plan_points_ar'] == null
          ? []
          : List<String>.from(json['plan_points_ar']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'description': description,
      'description_ar': descriptionAr,
      'expiryDay': expiryDay.toString(),
      'id': id,
      'isEnable': isEnable,
      'bookingLimit': bookingLimit.toString(),
      'name': name,
      'name_ar': nameAr,
      'price': price.toString(),
      'place': place.toString(),
      'image': image.toString(),
      'type': type,
      'plan_points': planPoints,
      'plan_points_ar': planPointsAr,
    };
  }
}
