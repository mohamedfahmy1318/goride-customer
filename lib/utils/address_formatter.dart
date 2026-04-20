import 'package:customer/model/place_picker_model.dart';

class AddressFormatter {
  static const List<String> _neighborhoodTypes = [
    'sublocality_level_1',
    'sublocality',
    'neighborhood',
    'sublocality_level_2',
    'sublocality_level_3',
  ];

  static const List<String> _cityTypes = [
    'locality',
    'postal_town',
    'administrative_area_level_2',
    'administrative_area_level_1',
  ];

  /// Formats Google address_components to "[District/Neighborhood], [City]".
  /// Falls back to filtered formattedAddress (without numeric segments) if
  /// neighborhood/city aren't found, never returns an empty string when input
  /// has any usable text.
  static String formatFromComponents(List<AddressComponents>? components,
      {String? fallback}) {
    final neighborhood = _firstMatch(components, _neighborhoodTypes);
    final city = _firstMatch(components, _cityTypes);

    final parts = <String>[];
    if (neighborhood != null && neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city != null && city.isNotEmpty && city != neighborhood) parts.add(city);

    if (parts.isNotEmpty) return parts.join(', ');
    final filtered = _filterFormatted(fallback);
    if (filtered != null && filtered.isNotEmpty) return filtered;
    return (fallback ?? '').trim();
  }

  static String formatFromPlaceDetails(PlaceDetailsModel? details) {
    if (details?.result == null) return '';
    return formatFromComponents(
      details!.result!.addressComponents,
      fallback: details.result!.formattedAddress,
    );
  }

  static String? _firstMatch(
      List<AddressComponents>? components, List<String> wanted) {
    if (components == null) return null;
    for (final type in wanted) {
      for (final c in components) {
        if (c.types?.contains(type) == true) {
          final name = c.longName?.trim();
          if (name != null && name.isNotEmpty) return name;
        }
      }
    }
    return null;
  }

  static String? _filterFormatted(String? formatted) {
    if (formatted == null || formatted.isEmpty) return null;
    final parts = formatted
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty && !_looksNumeric(p))
        .toList();
    if (parts.isEmpty) return null;
    return parts.length > 2
        ? parts.sublist(0, 2).join(', ')
        : parts.join(', ');
  }

  static bool _looksNumeric(String s) {
    final digits = RegExp(r'\d').allMatches(s).length;
    if (digits == 0) return false;
    return digits / s.length >= 0.5;
  }
}
