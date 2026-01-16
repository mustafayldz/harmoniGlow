import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:drumly/game/domain/entities/pad_spec.dart';

class InputController {

  InputController({
    required this.pads,
    this.enableHaptic = true,
  });
  /// Drum pad'lerin (çemberlerin) pozisyon ve boyut bilgileri.
  final List<PadSpec> pads;

  /// Haptic feedback aktif mi?
  final bool enableHaptic;

  /// Tap pozisyonundan lane index'i belirler.
  ///
  /// Circular hit detection kullanır - tap pad'in içinde mi diye kontrol eder.
  /// Geçerli bir tap'te hafif haptic feedback tetikler.
  ///
  /// [tapPosition] Ekran üzerindeki tap koordinatı.
  ///
  /// Returns: Lane index (0-7) veya null (hiçbir pad'e vurmadı).
  int? detectLane(Vector2 tapPosition) {
    for (int i = 0; i < pads.length; i++) {
      final pad = pads[i];
      final distance = _calculateDistance(
        tapPosition.x,
        tapPosition.y,
        pad.cx,
        pad.cy,
      );

      // Tap pad'in çemberi içinde mi?
      if (distance <= pad.r) {
        // Valid tap - trigger light haptic
        if (enableHaptic) {
          HapticFeedback.selectionClick();
        }
        return i;
      }
    }

    // Hiçbir pad'e vurmadı
    return null;
  }

  /// İki nokta arasındaki Euclidean mesafeyi hesaplar.
  double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Tap'in geçerli bir hit olup olmadığını kontrol eder.
  ///
  /// [tapPosition] Tap koordinatı.
  ///
  /// Returns: true ise tap bir lane'e denk geldi.
  bool isValidHit(Vector2 tapPosition) => detectLane(tapPosition) != null;

  /// Debug: Tap bilgilerini döndürür.
  Map<String, dynamic> getTapInfo(Vector2 tapPosition) {
    final lane = detectLane(tapPosition);

    if (lane != null) {
      final pad = pads[lane];
      final distance = _calculateDistance(
        tapPosition.x,
        tapPosition.y,
        pad.cx,
        pad.cy,
      );

      return {
        'lane': lane,
        'padCenter': {'x': pad.cx, 'y': pad.cy},
        'padRadius': pad.r,
        'distance': distance,
        'isHit': true,
      };
    }

    return {
      'isHit': false,
      'tapPosition': {'x': tapPosition.x, 'y': tapPosition.y},
    };
  }
}
