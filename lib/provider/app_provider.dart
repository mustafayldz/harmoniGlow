import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  // app data
  int? _countdownValue;
  bool _isDarkMode = false;

  // Getter for app data
  int get countdownValue => _countdownValue ?? 3;
  bool get isDarkMode => _isDarkMode;

  // Setter for app data
  void setCountdownValue(bool isIncrement) {
    if (isIncrement) {
      _countdownValue = (_countdownValue ?? 3) + 1;
    } else {
      _countdownValue = (_countdownValue ?? 3) - 1;
    }
    notifyListeners();
  }

  void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    notifyListeners();
  }
}
