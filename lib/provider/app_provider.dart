import 'dart:collection';

import 'package:drumly/screens/songs/songs_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppProvider with ChangeNotifier {
  AppProvider() {
    _loadTheme();
  }
  // app data
  bool _loading = false;
  int? _countdownValue;
  bool isDarkMode = false;
  bool _isClassic = false;

  // 🎵 Şarkı cache'i
  List<SongModel> _cachedSongs = [];

  // Getter for app data
  int get countdownValue => _countdownValue ?? 3;
  bool get loading => _loading;
  bool get isClassic => _isClassic;

  List<SongModel> get cachedSongs => _cachedSongs;

  // Setter for app data

  final Queue<bool> _loadings = Queue<bool>();
  void setLoading(bool loading) {
    // Build sırasında setState çağrılmasını önlemek için
    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      Future.microtask(() => _updateLoading(loading));
    } else {
      _updateLoading(loading);
    }
  }

  void _updateLoading(bool loading) {
    if (loading) {
      _loadings.add(true);
    } else {
      _loadings.clear();
    }
    _loading = _loadings.isNotEmpty;
    notifyListeners();
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

  void setIsClassic(bool isClassic) {
    _isClassic = isClassic;
    notifyListeners();
  }

  void cacheSongs(List<SongModel> songs) {
    _cachedSongs = songs;
    notifyListeners();
  }

  void clearSongCache() {
    _cachedSongs = [];
    notifyListeners();
  }
}
