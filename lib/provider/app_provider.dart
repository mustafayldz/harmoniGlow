import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:drumly/services/local_service.dart';

class AppProvider with ChangeNotifier {
  AppProvider() {
    _loadTheme();
  }
  // app data
  bool _loading = false;
  int? _countdownValue;
  bool isDarkMode = false;

  // Getter for app data
  int get countdownValue => _countdownValue ?? 3;
  bool get loading => _loading;

  // Setter for app data

  final Queue<bool> _loadings = Queue<bool>();
  void setLoading(bool loading) {
    if (loading) {
      _loadings.add(true);
    } else {
      _loadings.clear();
    }
    _loading = _loadings.isNotEmpty;
    debugPrint('loading status is ===>  $_loading');
  }

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
