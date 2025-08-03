class GameConstants {
  // Timing Constants
  static const double perfectHitThreshold = 30.0; // ms - more precise
  static const double goodHitThreshold = 60.0; // ms - tighter timing

  // Scoring
  static const int perfectScore = 150;
  static const int goodScore = 75;
  static const int comboMultiplier = 15;

  // Staff Positions for LANDSCAPE mode (0.0 to 1.0 screen width)
  static const double hihatPosition = 0.15;
  static const double tom1Position = 0.30;
  static const double snarePosition = 0.45;
  static const double tom2Position = 0.60;
  static const double kickPosition = 0.75;
  static const double hitZonePosition = 0.85; // 85% from left in landscape

  // Animation & Performance
  static const double noteSpeed = 300.0; // pixels per second - faster
  static const double noteFallDuration = 2.5; // seconds - shorter
  static const double effectAnimationDuration = 0.8; // seconds

  // Level System
  static const Map<int, LevelConfig> levels = {
    0: LevelConfig(
      name: "Warm Up",
      bpm: 90,
      noteCount: 50, // Increased from 20
      requiredAccuracy: 0.7, // 70%
      backgroundColor: [0xFF1A1A2E, 0xFF16213E],
    ),
    1: LevelConfig(
      name: "Getting Started",
      bpm: 110,
      noteCount: 75, // Increased from 35
      requiredAccuracy: 0.75,
      backgroundColor: [0xFF0F3460, 0xFF533483],
    ),
    2: LevelConfig(
      name: "Building Rhythm",
      bpm: 130,
      noteCount: 100, // Increased from 50
      requiredAccuracy: 0.8,
      backgroundColor: [0xFF16537E, 0xFF5B2C87],
    ),
    3: LevelConfig(
      name: "Drum Master",
      bpm: 150,
      noteCount: 150, // Increased from 75
      requiredAccuracy: 0.85,
      backgroundColor: [0xFF8B5CF6, 0xFF7C3AED],
    ),
    4: LevelConfig(
      name: "Legend",
      bpm: 180,
      noteCount: 200, // Increased from 100
      requiredAccuracy: 0.9,
      backgroundColor: [0xFFFF6B6B, 0xFFEE5A24],
    ),
  };

  // Screen dimensions
  static const double noteWidth = 50.0;
  static const double noteHeight = 35.0;
  static const double laneSpacing = 80.0;
}

class LevelConfig {
  final String name;
  final int bpm;
  final int noteCount;
  final double requiredAccuracy;
  final List<int> backgroundColor;

  const LevelConfig({
    required this.name,
    required this.bpm,
    required this.noteCount,
    required this.requiredAccuracy,
    required this.backgroundColor,
  });
}
