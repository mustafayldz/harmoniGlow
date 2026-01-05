// constants.dart
import 'dart:ui';
import 'package:drumly/env.dart';

class Constants {
  static const int timeOutInterval = 15;
  static const String myServiceUuid = 'FFE0';

  // db box names
  static const String beatRecordsBox = 'beatRecordsBox';
  static const String lockSongBox = 'lockSongBox';
}

class AppColors {
  static const emerald = Color(0xFF34D399);
  static const rose = Color(0xFFFB7185);
  static const indigo = Color(0xFF6366F1);
  static const skyBlue = Color(0xFF38BDF8);
  static const amber = Color(0xFFFBBF24);
  static const teal = Color(0xFF14B8A6);
  static const slate = Color(0xFF64748B);
  static const warmGray = Color(0xFFE5E7EB);
  static const darkGray = Color(0xFF1F2937);
  static const white = Color(0xFFFFFFFF);

  // Additional colors from the cards
  static const trainingGreen = Color(0xFF22C55E); // Training
  static const songsPink = Color(0xFFEC4899); // Songs
  static const drumBlue = Color(0xFF3B82F6); // My Drum
  static const settingsRed = Color(0xFFEF4444); // Settings

  // Modern gradient colors
  static const gradientStart = Color(0xFF0F172A); // Dark slate
  static const gradientMid = Color(0xFF1E293B); // Lighter slate
  static const gradientEnd = Color(0xFF334155); // Even lighter

  // Glass effect colors
  static const glassWhite = Color(0x1AFFFFFF); // 10% white
  static const glassBorder = Color(0x33FFFFFF); // 20% white
}

class ApiServiceUrl {
  static const baseUrl = Env.apiBaseUrl;

  static const user = '${baseUrl}users/';
  static const song = '${baseUrl}songs/';
  static const beat = '${baseUrl}beats/';
}

class DrumParts {
  static const drumParts = {
    '1': {
      'led': 1,
      'name': 'Hi-Hat',
      'rgb': [220, 0, 0],
    },
    '2': {
      'led': 2,
      'name': 'Crash Cymbal',
      'rgb': [208, 151, 154],
    },
    '3': {
      'led': 3,
      'name': 'Ride Cymbal',
      'rgb': [255, 125, 0],
    },
    '4': {
      'led': 4,
      'name': 'Snare Drum',
      'rgb': [7, 219, 2],
    },
    '5': {
      'led': 5,
      'name': 'Tom 1',
      'rgb': [0, 212, 154],
    },
    '6': {
      'led': 6,
      'name': 'Tom 2',
      'rgb': [21, 25, 207],
    },
    '7': {
      'led': 7,
      'name': 'Tom Floor',
      'rgb': [235, 0, 255],
    },
    '8': {
      'led': 8,
      'name': 'Kick Drum',
      'rgb': [242, 255, 0],
    },
  };

  // ✅ kitIndex: 0..7 -> key: '1'..'8'
  static String _keyOfKit(int kitIndex) => '${kitIndex + 1}';

  static String nameByKitIndex(int kitIndex) {
    final m = drumParts[_keyOfKit(kitIndex)];
    return (m?['name'] as String?) ?? '';
  }

  static int ledByKitIndex(int kitIndex) {
    final m = drumParts[_keyOfKit(kitIndex)];
    return (m?['led'] as int?) ?? (kitIndex + 1);
  }

  static List<int> rgbByKitIndex(int kitIndex) {
    final m = drumParts[_keyOfKit(kitIndex)];
    final rgb = m?['rgb'];
    if (rgb is List && rgb.length == 3) {
      return [rgb[0] as int, rgb[1] as int, rgb[2] as int];
    }
    return const [255, 255, 255];
  }

  static Color colorByKitIndex(int kitIndex) {
    final rgb = rgbByKitIndex(kitIndex);
    return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
  }
}
