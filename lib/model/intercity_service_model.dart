import 'package:customer/model/admin_commission.dart';
import 'package:customer/model/language_name.dart';

class IntercityServiceModel {
  String? image;
  bool? enable;
  String? meterStart; // فتح العداد
  String? kmCharge;
  String? perMinuteCharge;
  bool? enableMinuteCharge;
  bool? enableHoldingCharge;
  String? holdingMinute;
  String? holdingMinuteCharge;
  List<LanguageName>? name;
  bool? offerRate;
  String? id;
  AdminCommission? adminCommission;

  IntercityServiceModel({
    this.image,
    this.enable,
    this.meterStart,
    this.kmCharge,
    this.perMinuteCharge,
    this.enableMinuteCharge,
    this.enableHoldingCharge,
    this.holdingMinute,
    this.holdingMinuteCharge,
    this.name,
    this.offerRate,
    this.id,
    this.adminCommission,
  });

  IntercityServiceModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    enable = json['enable'];
    meterStart = json['meterStart']?.toString() ?? '0.0';
    kmCharge = json['kmCharge'];
    perMinuteCharge = json['perMinuteCharge']?.toString() ?? '0';
    enableMinuteCharge = json['enableMinuteCharge'] ?? false;
    enableHoldingCharge = json['enableHoldingCharge'] ?? false;
    holdingMinute = json['holdingMinute']?.toString() ?? '0';
    holdingMinuteCharge = json['holdingMinuteCharge']?.toString() ?? '0';
    if (json['name'] != null) {
      name = <LanguageName>[];
      json['name'].forEach((v) {
        name!.add(LanguageName.fromJson(v));
      });
    }
    adminCommission = json['adminCommission'] != null
        ? AdminCommission.fromJson(json['adminCommission'])
        : AdminCommission(isEnabled: true, amount: "", type: "");

    offerRate = json['offerRate'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['image'] = image;
    data['enable'] = enable;
    data['meterStart'] = meterStart;
    data['kmCharge'] = kmCharge;
    data['perMinuteCharge'] = perMinuteCharge;
    data['enableMinuteCharge'] = enableMinuteCharge;
    data['enableHoldingCharge'] = enableHoldingCharge;
    data['holdingMinute'] = holdingMinute;
    data['holdingMinuteCharge'] = holdingMinuteCharge;
    if (name != null) {
      data['name'] = name!.map((v) => v.toJson()).toList();
    }
    data['offerRate'] = offerRate;
    data['id'] = id;
    if (adminCommission != null) {
      data['adminCommission'] = adminCommission!.toJson();
    }
    return data;
  }
}
