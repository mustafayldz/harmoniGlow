import 'dart:ui';

class Constants {
  static const int timeOutInterval = 10;
  static const String myServiceUuid = 'FFE0';

  // db box names
  static const String beatRecordsBox = 'beatRecordsBox';
  static const String lockSongBox = 'lockSongBox';
}

class AppColors {
  static const Color primaryColor = Color(0xFF00c9f1);
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
