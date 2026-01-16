import 'dart:ui' as ui;
import 'package:flutter/widgets.dart' show EdgeInsets;
import 'package:drumly/game/core/services/device_profile.dart';
import 'package:drumly/game/core/enums/game_enums.dart';

/// Responsive layout hesaplamaları için servis.
/// 
/// Tüm UI ve gameplay elementlerinin boyutlarını
/// cihaz tipine ve ekran boyutuna göre hesaplar.
class LayoutService {

  LayoutService({
    required this.deviceProfile,
    required this.screenSize,
  });
  final DeviceProfile deviceProfile;
  final ui.Size screenSize;

  // ===========================================================================
  // HIT ZONE HESAPLAMALARI
  // ===========================================================================

  /// Hit zone Y pozisyonu (ekran yüksekliğinin yüzdesi).
  double get hitZoneY => screenSize.height * 0.75;

  /// Hit zone çizgi kalınlığı.
  double get hitZoneLineThickness => deviceProfile.isLargeScreen ? 4.0 : 3.0;

  // ===========================================================================
  // LANE VE PAD HESAPLAMALARI
  // ===========================================================================

  /// Lane sayısı - cihaza göre optimize edilmiş.
  int get laneCount {
    if (deviceProfile.isPhone) {
      return 6; // Telefonda daha az pad (kolay tıklanabilir)
    } else if (deviceProfile.isTablet) {
      return 8; // Tablet'te standart
    } else {
      return 10; // Desktop'ta daha fazla challenge
    }
  }

  /// Pad boyutu - ekran genişliğinin yüzdesi.
  double get padRadius {
    final baseRadius = screenSize.width / (laneCount * 2.5);
    
    if (deviceProfile.isPhone) {
      return baseRadius * 1.2; // Telefonda daha büyük (kolay dokunma)
    } else if (deviceProfile.isTablet) {
      return baseRadius;
    } else {
      return baseRadius * 0.9; // Desktop'ta daha kompakt
    }
  }

  /// Not disk boyutu.
  double get noteDiskRadius => padRadius * 0.8; // Pad'den biraz daha küçük

  // ===========================================================================
  // NOT HIZI HESAPLAMALARI
  // ===========================================================================

  /// Not hızı - zorluk ve cihaza göre.
  double getNoteSpeed(Difficulty difficulty) {
    // Base speed (pixels per second)
    final baseSpeed = switch (difficulty) {
      Difficulty.easy => 200.0,
      Difficulty.medium => 300.0,
      Difficulty.hard => 450.0,
    };

    // Cihaz multiplier
    final deviceMultiplier = switch (deviceProfile.type) {
      DeviceType.phone => 0.9,
      DeviceType.tablet => 1.0,
      DeviceType.desktop => 1.1,
    };

    // Ekran boyutu multiplier (büyük ekranlarda daha hızlı görünmeli)
    final screenMultiplier = screenSize.height / 800.0; // 800px baseline

    return baseSpeed * deviceMultiplier * screenMultiplier;
  }

  // ===========================================================================
  // UI BOYUTLARI
  // ===========================================================================

  /// Font boyutu - metin elementleri için.
  double getFontSize(TextSize size) {
    final baseSize = switch (size) {
      TextSize.small => 14.0,
      TextSize.medium => 18.0,
      TextSize.large => 24.0,
      TextSize.title => 32.0,
    };

    final multiplier = deviceProfile.isLargeScreen ? 1.3 : 1.0;
    return baseSize * multiplier;
  }

  /// Buton boyutu.
  double get buttonWidth => deviceProfile.isLargeScreen ? 200.0 : 150.0;

  double get buttonHeight => deviceProfile.isLargeScreen ? 60.0 : 50.0;

  /// Padding/margin değeri.
  double get standardPadding => deviceProfile.isLargeScreen ? 20.0 : 16.0;

  // ===========================================================================
  // HIT WINDOW HESAPLAMALARI
  // ===========================================================================

  /// Hit window boyutları - cihaz tipine göre ayarlı.
  /// Küçük ekranlarda daha toleranslı timing.
  Map<String, double> getHitWindowsForDifficulty(Difficulty difficulty) {
    final basePerfect = switch (difficulty) {
      Difficulty.easy => 100.0,
      Difficulty.medium => 80.0,
      Difficulty.hard => 60.0,
    };

    final baseGood = basePerfect * 1.5;
    final baseMiss = baseGood * 1.5;

    // Telefonda biraz daha toleranslı
    final multiplier = deviceProfile.isPhone ? 1.15 : 1.0;

    return {
      'perfectMs': basePerfect * multiplier,
      'goodMs': baseGood * multiplier,
      'missMs': baseMiss * multiplier,
    };
  }

  // ===========================================================================
  // YARDIMCI METODLAR
  // ===========================================================================

  /// Koordinatları normalize et (0.0 - 1.0 arası).
  double normalizeX(double x) => x / screenSize.width;
  double normalizeY(double y) => y / screenSize.height;

  /// Normalize koordinatları piksel koordinatına çevir.
  double denormalizeX(double normalizedX) => normalizedX * screenSize.width;
  double denormalizeY(double normalizedY) => normalizedY * screenSize.height;

  /// Safe area insets (notch, home indicator vb.)
  EdgeInsets get safeAreaInsets {
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view == null) return EdgeInsets.zero;

    return EdgeInsets.fromViewPadding(
      view.padding,
      view.devicePixelRatio, // ya da deviceProfile.pixelRatio
    );
  }
}

/// Metin boyutu enum'u.
enum TextSize {
  small,
  medium,
  large,
  title,
}
