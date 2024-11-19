import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  /// Singleton instance
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  /// Save the paired device ID and device name
  Future<void> saveDevice(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paired_device_id', device.remoteId.toString());
    await prefs.setString('paired_device_name', device.advName);
  }

  /// Get the saved paired device ID and device name
  Future<Map<String, String?>> getSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('paired_device_id');
    String? deviceName = prefs.getString('paired_device_name');

    if (deviceId != null && deviceName != null) {
      return {
        'deviceId': deviceId,
        'deviceName': deviceName,
      };
    }
    return {};
  }

  /// Clear the paired device ID and device name
  Future<void> clearDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('paired_device_id');
    await prefs.remove('paired_device_name');
  }

  /// Save the RGB values for each LED
  ///
  ///

  Future<void> saveAllLedData(List<Map<String, dynamic>> ledData) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert the list of LED data maps to a JSON string
    String jsonString = jsonEncode(ledData);

    // Save the JSON string to SharedPreferences
    await prefs.setString('ledData', jsonString);

    debugPrint('All LED data (names and RGB values) saved successfully.');
  }

  Future<List<Map<String, dynamic>>> loadAllLedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Get the JSON string from SharedPreferences
    String? jsonString = prefs.getString('ledData');

    // Define default LED data if no data exists in SharedPreferences
    const List<Map<String, dynamic>> defaultLedData = [
      {"name": "Hi-Hat Open", "red": 0, "green": 0, "blue": 0},
      {"name": "Hi-Hat Closed", "red": 0, "green": 0, "blue": 0},
      {"name": "Snare Drum", "red": 0, "green": 0, "blue": 0},
      {"name": "Tom 1", "red": 0, "green": 0, "blue": 0},
      {"name": "Tom 2", "red": 0, "green": 0, "blue": 0},
      {"name": "Tom 3", "red": 0, "green": 0, "blue": 0},
      {"name": "Crash Cymbal", "red": 0, "green": 0, "blue": 0},
      {"name": "Ride Cymbal", "red": 0, "green": 0, "blue": 0},
      {"name": "Kick Drum", "red": 0, "green": 0, "blue": 0},
    ];

    // If no data exists, return the default LED data
    if (jsonString == null) {
      return defaultLedData;
    }

    // Decode the JSON string back to a list of maps
    List<dynamic> decodedJson = jsonDecode(jsonString);
    return List<Map<String, dynamic>>.from(
        decodedJson.map((item) => Map<String, dynamic>.from(item)));
  }

  /// Get RGB values for a specific drum part by name
  Future<List<int>> getRgbForDrumPart(String drumName) async {
    final prefs = await SharedPreferences.getInstance();

    // Get the JSON string from SharedPreferences
    String? jsonString = prefs.getString('ledData');

    // Define a default RGB color (black/off)
    List<int> defaultRgb = [0, 0, 0];

    // If no data exists, return the default RGB value
    if (jsonString == null) {
      return defaultRgb;
    }

    // Decode the JSON string back to a list of maps
    List<dynamic> decodedJson = jsonDecode(jsonString);
    List<Map<String, dynamic>> ledData = List<Map<String, dynamic>>.from(
        decodedJson.map((item) => Map<String, dynamic>.from(item)));

    // Search for the drum part by name
    for (var item in ledData) {
      if (item["name"] == drumName) {
        int red = item["red"] ?? 0;
        int green = item["green"] ?? 0;
        int blue = item["blue"] ?? 0;
        return [red, green, blue];
      }
    }

    // Return default RGB value if the drum part is not found
    return defaultRgb;
  }
}
