import 'dart:ui' as ui;
import 'package:flutter/animation.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:drumly/game/core/constants/drumly_colors.dart';
import 'package:drumly/game/domain/entities/hit_result.dart';

/// ============================================================================
/// HIT FEEDBACK RING - Expanding ring animation for hit feedback
/// ============================================================================
///
/// Visual effect component that:
/// - Expands from hit position
/// - Color based on hit quality (Perfect/Good/Miss)
/// - Fades out over 0.3 seconds
/// - Uses Flame's Effect system
/// ============================================================================

class HitFeedbackRing extends PositionComponent {

  HitFeedbackRing({
    required this.quality,
    required this.startRadius,
    required super.position,
    this.maxScale = 1.5,
    this.performanceMode = false,
    this.overrideColor,
  }) : super(
          size: Vector2.all(startRadius * 2 * maxScale),
          anchor: Anchor.center,
        ) {
    // Set color based on quality
    if (overrideColor != null) {
      _ringColor = overrideColor!;
    } else if (quality == HitQuality.perfect) {
      _ringColor = DrumlyColors.perfectColor;
    } else if (quality == HitQuality.good) {
      _ringColor = DrumlyColors.goodColor;
    } else {
      _ringColor = DrumlyColors.missColor;
    }
  }
  final HitQuality quality;
  final double startRadius;
  final double maxScale;
  final bool performanceMode;
  final ui.Color? overrideColor;

  late ui.Color _ringColor;
  double _life = 0.0;
  double _duration = 0.3;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _duration = quality == HitQuality.miss ? 0.2 : 0.3;
    scale = Vector2.all(1.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    final t = (_life / _duration).clamp(0.0, 1.0);
    final eased = Curves.easeOut.transform(t);
    scale = Vector2.all(1.0 + (maxScale - 1.0) * eased);
    if (_life >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);

    final centerOffset = size / 2;
    final currentOpacity = (1.0 - (_life / _duration)).clamp(0.0, 1.0);

    // Draw main ring
    final mainPaint = ui.Paint()
      ..color = _ringColor.withValues(alpha: currentOpacity * 0.8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      centerOffset.toOffset(),
      startRadius * scale.x,
      mainPaint,
    );

    // Draw glow ring (if not in performance mode)
    if (!performanceMode && quality != HitQuality.miss) {
      final glowPaint = ui.Paint()
        ..color = _ringColor.withValues(alpha: currentOpacity * 0.3)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

      canvas.drawCircle(
        centerOffset.toOffset(),
        startRadius * scale.x,
        glowPaint,
      );
    }
  }
}

/// ============================================================================
/// HIT FEEDBACK RING FACTORY - Convenience methods
/// ============================================================================

extension HitFeedbackRingFactory on HitFeedbackRing {
  /// Create perfect hit ring (gold).
  static HitFeedbackRing perfect({
    required Vector2 position,
    required double radius,
    bool performanceMode = false,
  }) => HitFeedbackRing(
      quality: HitQuality.perfect,
      startRadius: radius,
      position: position,
      maxScale: 1.6,
      performanceMode: performanceMode,
    );

  /// Create good hit ring (cyan).
  static HitFeedbackRing good({
    required Vector2 position,
    required double radius,
    bool performanceMode = false,
  }) => HitFeedbackRing(
      quality: HitQuality.good,
      startRadius: radius,
      position: position,
      maxScale: 1.4,
      performanceMode: performanceMode,
    );

  /// Create miss ring (red).
  static HitFeedbackRing miss({
    required Vector2 position,
    required double radius,
    bool performanceMode = false,
  }) => HitFeedbackRing(
      quality: HitQuality.miss,
      startRadius: radius,
      position: position,
      maxScale: 1.2,
      performanceMode: performanceMode,
    );

  /// Create success ring (green).
  static HitFeedbackRing success({
    required Vector2 position,
    required double radius,
    bool performanceMode = false,
  }) => HitFeedbackRing(
      quality: HitQuality.good,
      startRadius: radius,
      position: position,
      maxScale: 1.3,
      performanceMode: performanceMode,
      overrideColor: DrumlyColors.successColor,
    );
}

/// ============================================================================
/// PULSE EFFECT - For CircleLaneComponent hit feedback
/// ============================================================================

class PulseEffect extends Effect with EffectTarget<PositionComponent> {

  PulseEffect({this.intensity = 1.5})
      : super(
          EffectController(
            duration: 0.3,
            curve: Curves.easeOut,
          ),
        );
  final double intensity;

  @override
  void apply(double progress) {
    final component = target;
    final scale = 1.0 + (intensity - 1.0) * (1.0 - progress);
    component.scale = Vector2.all(scale);
    // Note: Opacity is handled by OpacityEffect separately
  }

  @override
  void onRemove() {
    // Reset to original state
    target.scale = Vector2.all(1.0);
    super.onRemove();
  }
}
