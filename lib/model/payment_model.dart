class PaymentModel {
  Wallet? bankily;
  Wallet? cash;

  PaymentModel({this.bankily, this.cash});

  PaymentModel.fromJson(Map<String, dynamic> json) {
    bankily = json['bankily'] != null
        ? Wallet.fromJson(json['bankily'])
        : Wallet(enable: true, name: 'Bankily');
    cash = json['cash'] != null ? Wallet.fromJson(json['cash']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (bankily != null) {
      data['bankily'] = bankily!.toJson();
    }
    if (cash != null) {
      data['cash'] = cash!.toJson();
    }
    return data;
  }
}

class Wallet {
  bool? enable;
  String? name;

  Wallet({this.enable, this.name});

  Wallet.fromJson(Map<String, dynamic> json) {
    enable = json['enable'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['enable'] = enable;
    data['name'] = name;
    return data;
  }
}
