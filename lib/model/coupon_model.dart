import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/model/language_title.dart';

class CouponModel {
  List<LanguageTitle>? title;
  String? amount;
  String? code;
  bool? enable;
  String? id;
  Timestamp? validity;
  String? type;
  String? minBillAmount;
  int? usageLimit;
  int? usedCount;
  bool? isPublic;
  bool? isDeleted;

  CouponModel({
    this.title,
    this.amount,
    this.code,
    this.enable,
    this.id,
    this.validity,
    this.type,
    this.minBillAmount,
    this.usageLimit,
    this.usedCount,
    this.isPublic,
    this.isDeleted,
  });

  CouponModel.fromJson(Map<String, dynamic> json) {
    amount = json['amount']?.toString();
    code = json['code'];
    enable = json['enable'];
    id = json['id'];
    validity = json['validity'];
    type = json['type'];
    // New fields — nullable on docs predating the Laravel-backed persistence.
    minBillAmount = json['minBillAmount']?.toString();
    final rawUsageLimit = json['usageLimit'];
    usageLimit = rawUsageLimit is int
        ? rawUsageLimit
        : int.tryParse(rawUsageLimit?.toString() ?? '');
    final rawUsedCount = json['usedCount'];
    usedCount = rawUsedCount is int
        ? rawUsedCount
        : int.tryParse(rawUsedCount?.toString() ?? '') ?? 0;
    isPublic = json['isPublic'];
    isDeleted = json['isDeleted'];
    if (json['title'] != null) {
      title = <LanguageTitle>[];
      json['title'].forEach((v) {
        title!.add(LanguageTitle.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (title != null) {
      data['title'] = title!.map((v) => v.toJson()).toList();
    }
    data['amount'] = amount;
    data['code'] = code;
    data['enable'] = enable;
    data['id'] = id;
    data['validity'] = validity;
    data['type'] = type;
    if (minBillAmount != null) data['minBillAmount'] = minBillAmount;
    if (usageLimit != null) data['usageLimit'] = usageLimit;
    if (usedCount != null) data['usedCount'] = usedCount;
    if (isPublic != null) data['isPublic'] = isPublic;
    if (isDeleted != null) data['isDeleted'] = isDeleted;
    return data;
  }
}
