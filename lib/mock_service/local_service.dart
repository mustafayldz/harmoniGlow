import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:harmoniglow/constants.dart';
import 'package:harmoniglow/models/drum_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  /// Singleton instance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  static const String drumPartsKey = "drumParts";
  static const bool skipIntro = false;

  /// Save the paired device ID and device name
  Future<void> saveDevice(BluetoothDevice device) async {
    final prefs = await _prefs;
    prefs.setString('paired_device_id', device.remoteId.toString());
    prefs.setString('paired_device_name', device.advName);
  }

  /// Get the saved paired device ID and device name
  Future<Map<String, String?>> getSavedDevice() async {
    final prefs = await _prefs;
    return {
      'deviceId': prefs.getString('paired_device_id'),
      'deviceName': prefs.getString('paired_device_name'),
    };
  }

  /// Clear the paired device ID and device name
  Future<void> clearDevice() async {
    final prefs = await _prefs;
    prefs.remove('paired_device_id');
    prefs.remove('paired_device_name');
  }

  ////--------------------------------- Drum Parts ---------------------------------////
  ///
  ///
  /// Save all drum parts in bulk when the app starts, if they haven't been saved yet
  static Future<void> initializeDrumParts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString(drumPartsKey);

    if (savedData == null) {
      // Save the predefined drum parts
      await saveDrumPartsBulk(DrumParts.drumParts.values
          .map((e) => DrumModel.fromJson(e))
          .toList());
    }
  }

  /// Save all drum parts in bulk
  static Future<void> saveDrumPartsBulk(List<DrumModel> drumParts) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedDrumParts =
        jsonEncode(drumParts.map((e) => e.toJson()).toList());
    await prefs.setString(drumPartsKey, encodedDrumParts);
  }

  /// Retrieves drum parts data from SharedPreferences.
  /// Returns a list of DrumModel or null if not found.
  static Future<List<DrumModel>?> getDrumPartsBulk() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString(drumPartsKey);

    if (savedData != null) {
      try {
        // Decode the JSON string and cast it to List<DrumModel>
        return List<DrumModel>.from(
            jsonDecode(savedData).map((x) => DrumModel.fromJson(x)));
      } catch (e) {
        // Handle any parsing errors
        debugPrint("Error decoding saved drum parts: ${e.toString()}");
        return null;
      }
    }
    return null;
  }

  /// Save a single drum part
  static Future<void> saveDrumPart(String id, DrumModel drumPart) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? encodedDrumParts = prefs.getString(drumPartsKey);
    List<DrumModel> drumParts = [];

    if (encodedDrumParts != null) {
      drumParts = List<DrumModel>.from(
          jsonDecode(encodedDrumParts).map((x) => DrumModel.fromJson(x)));
    }

    // Update or add the drum part
    int index = drumParts.indexWhere((element) => element.led.toString() == id);
    if (index != -1) {
      drumParts[index] = drumPart;
    } else {
      drumParts.add(drumPart);
    }

    await prefs.setString(
        drumPartsKey, jsonEncode(drumParts.map((e) => e.toJson()).toList()));
  }

  /// Get a single drum part by ID, return null if not found
  static Future<DrumModel?> getDrumPart(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? encodedDrumParts = prefs.getString(drumPartsKey);

    if (encodedDrumParts != null) {
      List<DrumModel> drumParts = List<DrumModel>.from(
          jsonDecode(encodedDrumParts).map((x) => DrumModel.fromJson(x)));
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
    DrumModel? drumPart = await getDrumPart(id);
    if (drumPart != null) {
      drumPart.rgb = rgb;
      await saveDrumPart(id, drumPart);
    }
  }

  /// Skip the intro page
  ///
  /// Returns true if the intro page should be skipped
  static Future<bool> skipIntroPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('skip_intro') ?? false;
  }

  /// Set the skip intro page flag
  static Future<void> setSkipIntroPage(bool skip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_intro', skip);
  }
}
