import 'package:customer/model/place_picker_model.dart';
import 'package:customer/services/location_resolver.dart';
import 'package:customer/utils/address_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

AddressComponents c(String name, List<String> types) =>
    AddressComponents(longName: name, shortName: name, types: types);

void main() {
  group('AddressFormatter', () {
    final components = [
      c('12', ['street_number']),
      c('شارع جمال عبد الناصر', ['route']),
      c('تفرغ زينة', ['sublocality_level_1', 'sublocality']),
      c('نواكشوط', ['locality']),
      c('10000', ['postal_code']),
      c('موريتانيا', ['country']),
    ];

    test('title is the street with its number, not a postal or plus code', () {
      expect(AddressFormatter.titleFromComponents(components),
          'شارع جمال عبد الناصر 12');
    });

    test('subtitle places the title without repeating it', () {
      final title = AddressFormatter.titleFromComponents(components);
      expect(AddressFormatter.subtitleFromComponents(components, title),
          'تفرغ زينة، نواكشوط');
    });

    test('a neighbourhood title is not echoed in its own subtitle', () {
      final coarse = [
        c('تفرغ زينة', ['sublocality_level_1']),
        c('نواكشوط', ['locality']),
      ];
      final title = AddressFormatter.titleFromComponents(coarse);
      expect(title, 'تفرغ زينة');
      expect(AddressFormatter.subtitleFromComponents(coarse, title), 'نواكشوط');
    });

    test('a point of interest wins over the street it sits on', () {
      final withPoi = [
        c('مستشفى الشيخ زايد', ['point_of_interest', 'establishment']),
        ...components,
      ];
      expect(
          AddressFormatter.titleFromComponents(withPoi), 'مستشفى الشيخ زايد');
    });

    test('isNoise rejects plus codes, the country and bare numbers only', () {
      expect(AddressFormatter.isNoise('322R+6P2'), isTrue);
      expect(AddressFormatter.isNoise('موريتانيا'), isTrue);
      expect(AddressFormatter.isNoise('10000'), isTrue);
      expect(AddressFormatter.isNoise('شارع 42'), isFalse);
      expect(AddressFormatter.isNoise('تفرغ زينة'), isFalse);
    });

    test('clean strips noise, dedupes and keeps the two useful parts', () {
      expect(
        AddressFormatter.clean(
            '322R+6P2, تفرغ زينة, تفرغ زينة, نواكشوط, موريتانيا'),
        'تفرغ زينة، نواكشوط',
      );
    });
  });

  group('ResolvedAddress', () {
    test('display joins the two lines so legacy readers can split them back',
        () {
      const address =
          ResolvedAddress(title: 'سوق العاصمة', subtitle: 'نواكشوط');
      expect(address.display, 'سوق العاصمة، نواكشوط');
    });

    test('display is just the title when there is nothing to place it with',
        () {
      const address = ResolvedAddress(title: 'مطار نواكشوط');
      expect(address.display, 'مطار نواكشوط');
    });

    test('coordinates fallback is precise enough to drive to', () {
      final address = ResolvedAddress.fromCoordinates(18.0735, -15.9582);
      expect(address.title, '18.07350, -15.95820');
      expect(address.isEmpty, isFalse);
    });
  });
}
