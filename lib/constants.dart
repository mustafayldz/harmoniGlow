import 'dart:ui';

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
  static const beatsPurple = Color(0xFFA855F7); // My Beats
  static const drumBlue = Color(0xFF3B82F6); // My Drum
  static const makerOrange = Color(0xFFF97316); // Beat Maker
  static const settingsRed = Color(0xFFEF4444); // Settings
}

class ApiServiceUrl {
  static const baseUrl =
      'https://drumly-backend-541755790098.us-central1.run.app/api/';
  // static const baseUrl = 'http://10.0.0.127:8080/api/';

  static const user = '${baseUrl}users/';
  static const song = '${baseUrl}songs/';
  static const beat = '${baseUrl}beats/';
  static const songTypes = '${baseUrl}song-types/';
}

class DrumParts {
  static const drumParts = {
    '1': {
      'led': 1,
      'name': 'Hi-Hat',
      'rgb': [220, 0, 0],
    }, // Yellow
    '2': {
      'led': 2,
      'name': 'Crash Cymbal',
      'rgb': [208, 151, 154],
    }, // Orange Red
    '3': {
      'led': 3,
      'name': 'Ride Cymbal',
      'rgb': [255, 125, 0],
    }, // Dark Orange
    '4': {
      'led': 4,
      'name': 'Snare Drum',
      'rgb': [7, 219, 2],
    }, // Red
    '5': {
      'led': 5,
      'name': 'Tom 1',
      'rgb': [0, 212, 154],
    }, // Green
    '6': {
      'led': 6,
      'name': 'Tom 2',
      'rgb': [21, 25, 207],
    }, // Light Blue
    '7': {
      'led': 7,
      'name': 'Tom Floor',
      'rgb': [235, 0, 255],
    }, // Blue
    '8': {
      'led': 8,
      'name': 'Kick Drum',
      'rgb': [242, 255, 0],
    }, // Purple
  };
}
