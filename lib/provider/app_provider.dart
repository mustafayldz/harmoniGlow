import 'dart:collection';

import 'package:drumly/screens/songs/songs_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppProvider with ChangeNotifier {
  AppProvider() {
    // Sistem temasını al ve async theme load yap
    _initializeTheme();
  }
  
  // app data
  bool _loading = false;
  int? _countdownValue;
  bool isDarkMode = true; // Başlangıçta dark mode
  bool _isClassic = false;

  // 🎵 Şarkı cache'i
  List<SongModel> _cachedSongs = [];
  
  // 🔒 Debounce için
  bool _isNotifying = false;

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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateLoading(loading);
      });
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
    final newLoading = _loadings.isNotEmpty;
    if (_loading != newLoading) {
      _loading = newLoading;
      _safeNotifyListeners();
    }
  }

  void setCountdownValue(bool isIncrement) {
    final newValue = isIncrement 
        ? (_countdownValue ?? 3) + 1 
        : (_countdownValue ?? 3) - 1;
    
    if (_countdownValue != newValue) {
      _countdownValue = newValue;
      _safeNotifyListeners();
    }
  }

  /// Initialize theme - system tema kontrolü + saved tema
  Future<void> _initializeTheme() async {
    try {
      final savedDarkMode = await StorageService.getThemeMode();
      if (isDarkMode != savedDarkMode) {
        isDarkMode = savedDarkMode;
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Theme load error: $e');
      // Hata durumunda sistem temasını kullan
      isDarkMode = true; // Default dark mode
    }
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    _safeNotifyListeners();
    // Storage'a kaydetmeyi arka planda yap
    StorageService.saveThemeMode(isDarkMode).catchError((e) {
      debugPrint('⚠️ Theme save error: $e');
    });
  }

  void setIsClassic(bool isClassic) {
    if (_isClassic != isClassic) {
      _isClassic = isClassic;
      _safeNotifyListeners();
    }
  }

  void cacheSongs(List<SongModel> songs) {
    if (_cachedSongs != songs) {
      _cachedSongs = songs;
      _safeNotifyListeners();
    }
  }

  void clearSongCache() {
    if (_cachedSongs.isNotEmpty) {
      _cachedSongs = [];
      _safeNotifyListeners();
    }
  }
  
  /// Safe notify - aynı frame'de birden fazla notify'ı önler
  void _safeNotifyListeners() {
    if (_isNotifying) return;
    _isNotifying = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isNotifying = false;
      notifyListeners();
    });
  }
}
