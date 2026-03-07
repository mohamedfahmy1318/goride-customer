import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/language_title.dart';

class ServiceModel {
  String? image;
  bool? enable;
  bool? offerRate;
  bool? intercityType;
  String? id;
  // New pricing fields
  String? meterStart; // فتح العداد - fixed start fare
  String? kmCharge; // سعر الكيلو
  String? perMinuteCharge; // سعر الدقيقة
  bool? enableMinuteCharge; // toggle minute-based charging
  // Holding charge (driver waiting)
  bool? enableHoldingCharge;
  String? holdingMinute;
  String? holdingMinuteCharge;
  // Legacy fields (kept for backward compat with old orders)
  bool? isAcNonAc;
  String? acCharge;
  String? nonAcCharge;
  String? basicFare;
  String? basicFareCharge;
  String? endNightTime;
  String? startNightTime;
  String? nightCharge;

  List<LanguageTitle>? title;
  AdminCommission? adminCommission;
  int position = 0;

  ServiceModel({
    this.image,
    this.enable,
    this.intercityType,
    this.offerRate,
    this.id,
    this.meterStart,
    this.kmCharge,
    this.perMinuteCharge,
    this.enableMinuteCharge,
    this.enableHoldingCharge,
    this.holdingMinute,
    this.holdingMinuteCharge,
    this.isAcNonAc,
    this.acCharge,
    this.nonAcCharge,
    this.basicFare,
    this.basicFareCharge,
    this.endNightTime,
    this.startNightTime,
    this.nightCharge,
    this.title,
    this.adminCommission,
    this.position = 0,
  });

  ServiceModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    enable = json['enable'];
    offerRate = json['offerRate'];
    id = json['id'];
    position = int.tryParse(json['position']?.toString() ?? '0') ?? 0;
    // New pricing: meterStart falls back to basicFareCharge for old data
    meterStart = json['meterStart']?.toString() ??
        json['basicFareCharge']?.toString() ??
        '0.0';
    kmCharge = json['kmCharge']?.toString() ?? '0.0';
    perMinuteCharge = json['perMinuteCharge']?.toString() ?? '0';
    enableMinuteCharge = json['enableMinuteCharge'] ?? true;
    enableHoldingCharge = json['enableHoldingCharge'] ?? true;
    holdingMinute = json['holdingMinute']?.toString() ?? '0.0';
    holdingMinuteCharge = json['holdingMinuteCharge']?.toString() ?? '0.0';
    // Legacy fields
    acCharge = json['acCharge']?.toString() ?? '0.0';
    nonAcCharge = json['nonAcCharge']?.toString() ?? '0.0';
    basicFare = json['basicFare']?.toString() ?? '0.0';
    basicFareCharge = json['basicFareCharge']?.toString() ?? '0.0';
    endNightTime = json['endNightTime'];
    startNightTime = json['startNightTime'];
    nightCharge = json['nightCharge']?.toString() ?? '0.0';
    intercityType = json['intercityType'];
    isAcNonAc = json['isAcNonAc'];
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : AdminCommission(isEnabled: true, amount: "", type: "");
    if (json['title'] != null) {
      title = <LanguageTitle>[];
      json['title'].forEach((v) {
        title!.add(LanguageTitle.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['image'] = image;
    data['enable'] = enable;
    data['offerRate'] = offerRate;
    data['id'] = id;
    data['position'] = position;
    data['meterStart'] = meterStart;
    data['kmCharge'] = kmCharge;
    data['perMinuteCharge'] = perMinuteCharge;
    data['enableMinuteCharge'] = enableMinuteCharge;
    data['enableHoldingCharge'] = enableHoldingCharge;
    data['holdingMinute'] = holdingMinute;
    data['holdingMinuteCharge'] = holdingMinuteCharge;
    data['intercityType'] = intercityType;
    // Legacy fields (still written for any old code reading them)
    data['acCharge'] = acCharge;
    data['nonAcCharge'] = nonAcCharge;
    data['basicFare'] = basicFare;
    data['basicFareCharge'] = basicFareCharge;
    data['endNightTime'] = endNightTime;
    data['startNightTime'] = startNightTime;
    data['nightCharge'] = nightCharge;
    data['isAcNonAc'] = isAcNonAc;
    if (title != null) {
      data['title'] = title!.map((v) => v.toJson()).toList();
    }
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    return data;
  }
}
