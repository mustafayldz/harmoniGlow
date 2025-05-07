import 'package:flutter/material.dart';
import 'package:drumly/mock_service/local_service.dart';

class AppProvider with ChangeNotifier {
  AppProvider() {
    _loadTheme();
  }
  // app data
  int? _countdownValue;
  bool isDarkMode = false;

  // Getter for app data
  int get countdownValue => _countdownValue ?? 3;

  // Setter for app data
  void setCountdownValue(bool isIncrement) {
    if (isIncrement) {
      _countdownValue = (_countdownValue ?? 3) + 1;
    } else {
      _countdownValue = (_countdownValue ?? 3) - 1;
    }
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    isDarkMode = await StorageService.getThemeMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    notifyListeners();
    await StorageService.saveThemeMode(isDarkMode);
  }
}
