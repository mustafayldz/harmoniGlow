import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:drumly/screens/my_drum/drum_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  factory StorageService() => _instance;
  StorageService._internal();

  /// Singleton instance
  static final StorageService _instance = StorageService._internal();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  static const String drumPartsKey = 'drumParts';
  static const themeKey = 'darkMode';
  static const String deviceIdKey = 'paired_device_id';

  /// Save the paired device ID
  Future<void> saveDeviceId(BluetoothDevice device) async {
    final prefs = await _prefs;
    await prefs.setString(deviceIdKey, device.remoteId.toString());
  }

  /// Get the saved paired device ID
  Future<String?> getSavedDeviceId() async {
    final prefs = await _prefs;
    return prefs.getString(deviceIdKey);
  }

  /// Clear the paired device ID
  Future<void> clearSavedDeviceId() async {
    final prefs = await _prefs;
    await prefs.remove(deviceIdKey);
  }

  //// Drum Parts
  ///
  ///
  /// Save all drum parts in bulk
  static Future<void> saveDrumPartsBulk(List<DrumModel> drumParts) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String encodedDrumParts =
        jsonEncode(drumParts.map((e) => e.toJson()).toList());
    await prefs.setString(drumPartsKey, encodedDrumParts);
  }

  /// Retrieves drum parts data from SharedPreferences.
  /// Returns a list of DrumModel or null if not found.
  static Future<List<DrumModel>?> getDrumPartsBulk() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(drumPartsKey);

    if (savedData != null) {
      try {
        // Decode the JSON string and cast it to List<DrumModel>
        return List<DrumModel>.from(
          jsonDecode(savedData).map((x) => DrumModel.fromJson(x)),
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Save a single drum part
  static Future<void> saveDrumPart(String id, DrumModel drumPart) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encodedDrumParts = prefs.getString(drumPartsKey);
    List<DrumModel> drumParts = [];

    if (encodedDrumParts != null) {
      drumParts = List<DrumModel>.from(
        jsonDecode(encodedDrumParts).map((x) => DrumModel.fromJson(x)),
      );
    }

    // Update or add the drum part
    final int index =
        drumParts.indexWhere((element) => element.led.toString() == id);
    if (index != -1) {
      drumParts[index] = drumPart;
    } else {
      drumParts.add(drumPart);
    }

    await prefs.setString(
      drumPartsKey,
      jsonEncode(drumParts.map((e) => e.toJson()).toList()),
    );
  }

  /// Get a single drum part by ID, return null if not found
  static Future<DrumModel?> getDrumPart(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? encodedDrumParts = prefs.getString(drumPartsKey);

    if (encodedDrumParts != null) {
      final List<DrumModel> drumParts = List<DrumModel>.from(
        jsonDecode(encodedDrumParts).map((x) => DrumModel.fromJson(x)),
      );
      try {
        return drumParts.firstWhere((element) => element.led.toString() == id);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Update the RGB values of a drum part
  static Future<void> updateDrumPartRgb(String id, List<int> rgb) async {
    final DrumModel? drumPart = await getDrumPart(id);
    if (drumPart != null) {
      drumPart.rgb = rgb;
      await saveDrumPart(id, drumPart);
    }
  }

  /// Firebase
  ///
  /// Save the Firebase token
  static Future<void> saveFirebaseToken(String token) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_token', token);
  }

  /// Get the saved Firebase token
  Future<String?> getFirebaseToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_token');
  }

  /// Clear the Firebase token
  Future<void> clearFirebaseToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('firebase_token');
  }

  /// Theme
  ///
  /// Save the theme mode
  static Future<void> saveThemeMode(bool isDarkMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isDarkMode);
  }

  /// Get the saved theme mode
  static Future<bool> getThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeKey) ?? false;
  }

  /// Beat Maker parts positions
  // Save the position of a drum part
  Future<void> saveDrumPosition(String key, Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${key}_dx', position.dx);
    await prefs.setDouble('${key}_dy', position.dy);
  }

  /// Get the saved position of a drum part
  Future<Offset?> loadDrumPosition(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble('${key}_dx');
    final dy = prefs.getDouble('${key}_dy');
    if (dx != null && dy != null) {
      return Offset(dx, dy);
    }
    return null;
  }

  Future<void> clearDrumPositionAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.endsWith('_dx') || key.endsWith('_dy')) {
        await prefs.remove(key);
      }
    }
  }

  /// Clear all stored preferences
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
