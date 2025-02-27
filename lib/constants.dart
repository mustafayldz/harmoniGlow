import 'dart:ui';

class Constants {
  static const int timeOutInterval = 10;
  static const String myServiceUuid = 'FFE0';
}

class AppColors {
  static const emeraldGreen = Color(0xFF008000);
  static const brickRed = Color(0xFFC0392B);
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
      'name': 'Snare Drum',
      'rgb': [7, 219, 2],
    }, // Red
    '3': {
      'led': 3,
      'name': 'Tom 1',
      'rgb': [0, 212, 154],
    }, // Green
    '4': {
      'led': 4,
      'name': 'Tom 2',
      'rgb': [21, 25, 207],
    }, // Light Blue
    '5': {
      'led': 5,
      'name': 'Tom 3',
      'rgb': [235, 0, 255],
    }, // Blue
    '6': {
      'led': 6,
      'name': 'Crash Cymbal',
      'rgb': [208, 151, 154],
    }, // Orange Red
    '7': {
      'led': 7,
      'name': 'Ride Cymbal',
      'rgb': [255, 125, 0],
    }, // Dark Orange
    '8': {
      'led': 8,
      'name': 'Kick Drum',
      'rgb': [242, 255, 0],
    }, // Purple
  };
}
