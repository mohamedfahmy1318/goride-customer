import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherUtils {
  static const List<String> _knownCountryCodes = ['222', '966', '971', '20'];

  static String? _sanitize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    String digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    for (final cc in _knownCountryCodes) {
      if (digits.length > cc.length &&
          digits.startsWith(cc) &&
          digits[cc.length] == '0') {
        digits = digits.substring(0, cc.length) + digits.substring(cc.length + 1);
        break;
      }
    }
    return digits;
  }

  static Future<bool> launchPhoneCall(String? phoneNumber) async {
    final digits = _sanitize(phoneNumber);
    if (digits == null) {
      debugPrint('[UrlLauncherUtils] launchPhoneCall: empty/invalid number "$phoneNumber"');
      return false;
    }
    final Uri uri = Uri.parse('tel:+$digits');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) debugPrint('[UrlLauncherUtils] launchPhoneCall: launchUrl returned false for $uri');
      return ok;
    } catch (e) {
      debugPrint('[UrlLauncherUtils] launchPhoneCall failed for $uri: $e');
      return false;
    }
  }

  static Future<bool> launchWhatsApp(String? phoneNumber, {String? message}) async {
    final digits = _sanitize(phoneNumber);
    if (digits == null) {
      debugPrint('[UrlLauncherUtils] launchWhatsApp: empty/invalid number "$phoneNumber"');
      return false;
    }
    final query = (message != null && message.isNotEmpty)
        ? '?text=${Uri.encodeComponent(message)}'
        : '';
    final Uri uri = Uri.parse('https://wa.me/$digits$query');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) debugPrint('[UrlLauncherUtils] launchWhatsApp: launchUrl returned false for $uri');
      return ok;
    } catch (e) {
      debugPrint('[UrlLauncherUtils] launchWhatsApp failed for $uri: $e');
      return false;
    }
  }
}
