import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// CircleLaneComponent - Modern circle-based lane gösterimi.
/// 
/// Drum kit yerine her lane için renkli circle gösterir.
/// Hit zone'da parlayan animasyonlu çemberler.
class CircleLaneComponent extends PositionComponent {

  CircleLaneComponent({
    required this.laneIndex,
    required this.radius,
    required this.color,
    required this.hitZoneY,
    required this.label,
    required super.position,
  }) : super(size: Vector2.all(radius * 2));
  final int laneIndex;
  final double radius;
  final ui.Color color;
  final double hitZoneY;
  final String label;
  
  double _flashIntensity = 0.0;
  double _pulsePhase = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    
    // Flash animasyonu (vuruştan sonra)
    if (_flashIntensity > 0) {
      _flashIntensity -= dt * 3.0; // 3x hızda sönüyor
      if (_flashIntensity < 0) _flashIntensity = 0;
    }
    
    // Pulse animasyonu (sürekli)
    _pulsePhase += dt * 2.0; // 2 rad/s
    if (_pulsePhase > math.pi * 2) {
      _pulsePhase -= math.pi * 2;
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    
    final center = Vector2(radius, radius);
    final pulseScale = 1.0 + (math.sin(_pulsePhase) * 0.05); // ±5% pulse
    
    // Outer glow (pulse effect)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(
      center.toOffset(),
      radius * pulseScale * 1.2,
      glowPaint,
    );
    
    // Main circle (base)
    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.6 + (_flashIntensity * 0.4))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      center.toOffset(),
      radius * pulseScale,
      basePaint,
    );
    
    // Inner circle (border)
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(
      center.toOffset(),
      radius * pulseScale * 0.9,
      borderPaint,
    );
    
    // Flash effect (hit feedback)
    if (_flashIntensity > 0) {
      final flashPaint = Paint()
        ..color = ui.Color.fromARGB(
          (255 * _flashIntensity).toInt(),
          255,
          255,
          255,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(
        center.toOffset(),
        radius * pulseScale * 1.3,
        flashPaint,
      );
    }

    if (label.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: (radius * 0.42).clamp(10.0, 16.0),
            fontWeight: FontWeight.w800,
            color: const ui.Color(0xFFFFFFFF),
            shadows: const [
              Shadow(
                color: ui.Color(0xAA000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: radius * 1.7);

      textPainter.paint(
        canvas,
        Offset(
          center.x - (textPainter.width / 2),
          center.y - (textPainter.height / 2),
        ),
      );
    }
  }

  /// Flash animasyonu tetikle (vuruş feedback'i).
  void triggerFlash() {
    _flashIntensity = 1.0;
  }

  /// Lane için renk palet'i.
  static ui.Color colorForLane(int lane) => switch (lane) {
      0 => const ui.Color(0xFF3498DB), // Mavi (Hi-hat)
      1 => const ui.Color(0xFF9B59B6), // Mor (Open Hi-hat)
      2 => const ui.Color(0xFFE74C3C), // Kırmızı (Crash)
      3 => const ui.Color(0xFFF39C12), // Turuncu (Ride)
      4 => const ui.Color(0xFFE67E22), // Koyu turuncu (Snare)
      5 => const ui.Color(0xFF2ECC71), // Yeşil (Kick)
      6 => const ui.Color(0xFF1ABC9C), // Turkuaz (Tom 1)
      7 => const ui.Color(0xFF34495E), // Gri (Floor tom)
      _ => const ui.Color(0xFFECF0F1), // Beyaz (default)
    };
}

/// CircleLaneLayout - Tüm lane'lerin layout hesaplaması.
class CircleLaneLayout {

  CircleLaneLayout({
    required this.screenWidth,
    required this.screenHeight,
    required this.laneCount,
    required this.hitZoneY,
    required this.laneRadius,
  });
  final double screenWidth;
  final double screenHeight;
  final int laneCount;
  final double hitZoneY;
  final double laneRadius;

  /// Lane pozisyonu hesapla (X koordinatı).
  double laneX(int laneIndex) {
    final spacing = screenWidth / (laneCount + 1);
    return spacing * (laneIndex + 1);
  }

  /// Lane pozisyonları listesi.
  List<Vector2> get allLanePositions => List.generate(
      laneCount,
      (i) => Vector2(laneX(i) - laneRadius, hitZoneY - laneRadius),
    );

  /// Lane component'lerini oluştur.
  List<CircleLaneComponent> createLaneComponents() => List.generate(
      laneCount,
      (i) => CircleLaneComponent(
        laneIndex: i,
        radius: laneRadius,
        color: CircleLaneComponent.colorForLane(i),
        hitZoneY: hitZoneY,
        position: allLanePositions[i],
        label: 'Lane $i',
      ),
    );
}
