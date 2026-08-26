import 'package:customer/model/order_model.dart';
import 'package:customer/model/tax_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('customer fare snapshot does not double-add tax', () {
    final order = OrderModel(
      totalFare: '100',
      finalPayableAmount: '112',
      fareIncludesTax: true,
      taxList: [TaxModel(type: 'percentage', tax: '12', enable: true)],
    );

    expect(order.customerPayableFare, 112);
    expect(order.customerPayableFareText, '112.00');
  });
}
