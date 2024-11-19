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
    "1": {
      "name": "Hi-Hat Open",
      "rgb": [255, 255, 0]
    }, // Yellow
    "2": {
      "name": "Hi-Hat Closed",
      "rgb": [255, 215, 0]
    }, // Gold
    "3": {
      "name": "Snare Drum",
      "rgb": [255, 0, 0]
    }, // Red
    "4": {
      "name": "Tom 1",
      "rgb": [0, 255, 0]
    }, // Green
    "5": {
      "name": "Tom 2",
      "rgb": [0, 128, 255]
    }, // Light Blue
    "6": {
      "name": "Tom 3",
      "rgb": [0, 0, 255]
    }, // Blue
    "7": {
      "name": "Crash Cymbal",
      "rgb": [255, 69, 0]
    }, // Orange Red
    "8": {
      "name": "Ride Cymbal",
      "rgb": [255, 140, 0]
    }, // Dark Orange
    "9": {
      "name": "Kick Drum",
      "rgb": [128, 0, 128]
    }, // Purple
    "10": {
      "name": "Kick Drum",
      "rgb": [99, 10, 23]
    } // Purple
  };
}
