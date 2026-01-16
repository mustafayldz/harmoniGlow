import 'package:drumly/game/core/enums/game_enums.dart';

class GameConfig {

  const GameConfig({
    required this.laneCount,
    required this.hitZoneYPercentage,
    required this.spawnYOffset,
    required this.diskSizeRatio,
    required this.speedMultipliers,
  });

  /// Preset: Performans modu (düşük spec cihazlar).
  factory GameConfig.performance() => const GameConfig(
      laneCount: 8,
      hitZoneYPercentage: 0.75,
      spawnYOffset: -30,
      diskSizeRatio: 0.30, // Daha küçük diskler
      speedMultipliers: {
        Difficulty.easy: 0.9,
        Difficulty.medium: 1.3,
        Difficulty.hard: 1.8,
      },
    );

  /// Preset: Tablet için optimize edilmiş.
  factory GameConfig.tablet() => const GameConfig(
      laneCount: 8,
      hitZoneYPercentage: 0.70,
      spawnYOffset: -40,
      diskSizeRatio: 0.35, // Tablet'te daha büyük diskler
      speedMultipliers: {
        Difficulty.easy: 1.2,
        Difficulty.medium: 1.7,
        Difficulty.hard: 2.3,
      },
    );

  /// Varsayılan konfigürasyon.
  factory GameConfig.defaultConfig() => const GameConfig(
      laneCount: 8,
      hitZoneYPercentage: 0.75, // Ekranın %75'inde
      spawnYOffset: -30, // 30 piksel ekran üstü
      diskSizeRatio: 0.32, // Lane genişliğinin %32'si
      speedMultipliers: {
        Difficulty.easy: 1.0,
        Difficulty.medium: 1.5,
        Difficulty.hard: 2.0,
      },
    );
  /// Lane sayısı (drum pad sayısı).
  final int laneCount;

  /// Hit zone'un ekran yüksekliğindeki oranı (0.0 - 1.0).
  final double hitZoneYPercentage;

  /// Spawn noktasının ekran üstünden uzaklığı (negative = ekran dışı).
  final double spawnYOffset;

  /// Disk boyutunun lane genişliğine oranı.
  final double diskSizeRatio;

  /// Hız çarpanları (zorluk seviyesine göre).
  final Map<Difficulty, double> speedMultipliers;

  /// Lane genişliğini hesaplar.
  double calculateLaneWidth(double screenWidth) => screenWidth / laneCount;

  /// Hit zone Y koordinatını hesaplar.
  double calculateHitZoneY(double screenHeight) => screenHeight * hitZoneYPercentage;

  /// Disk yarıçapını hesaplar.
  double calculateDiskRadius(double laneWidth) => laneWidth * diskSizeRatio;

  /// Spawn Y koordinatını hesaplar.
  double calculateSpawnY() => spawnYOffset;

  /// Zorluk seviyesine göre hız çarpanını döndürür.
  double getSpeedMultiplier(Difficulty difficulty) => speedMultipliers[difficulty] ?? 1.0;

  /// Kopyalama metodu.
  GameConfig copyWith({
    int? laneCount,
    double? hitZoneYPercentage,
    double? spawnYOffset,
    double? diskSizeRatio,
    Map<Difficulty, double>? speedMultipliers,
  }) => GameConfig(
      laneCount: laneCount ?? this.laneCount,
      hitZoneYPercentage: hitZoneYPercentage ?? this.hitZoneYPercentage,
      spawnYOffset: spawnYOffset ?? this.spawnYOffset,
      diskSizeRatio: diskSizeRatio ?? this.diskSizeRatio,
      speedMultipliers: speedMultipliers ?? this.speedMultipliers,
    );
}
