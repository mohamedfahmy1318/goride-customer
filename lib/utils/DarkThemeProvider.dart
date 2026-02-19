import 'package:customer/utils/DarkThemePreference.dart';
import 'package:flutter/foundation.dart';

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  int _darkTheme = 1; // Default to Light mode

  int get darkTheme => _darkTheme;

  set darkTheme(int value) {
    _darkTheme = 1; // Always Light mode
    darkThemePreference.setDarkTheme(1);
    notifyListeners();
  }

  bool getThem() {
    // Always return false for Light mode (white and green theme)
    return false;
  }

  bool getSystemThem() {
    // Always return false for Light mode
    return false;
  }
}
