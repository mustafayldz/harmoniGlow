import 'package:flutter/animation.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart';
import 'package:drumly/game/core/constants/drumly_colors.dart';
import 'package:drumly/game/core/constants/drumly_text_styles.dart';
import 'package:drumly/game/domain/entities/hit_result.dart';

/// ============================================================================
/// FLOATING HIT TEXT - Animated feedback text for hits
/// ============================================================================
///
/// Features:
/// - Spawns at hit position
/// - Floats upward with fade
/// - Color and size based on quality (Perfect/Good/Miss)
/// - Auto-removes after animation (1 second)
/// ============================================================================

class FloatingHitText extends TextComponent {

  FloatingHitText({
    required this.quality,
    required Vector2 position,
    this.floatDistance = 80,
    this.duration = 1.0,
  }) : super(
          text: _getTextForQuality(quality),
          textRenderer: _getTextRendererForQuality(quality),
          position: position,
          anchor: Anchor.center,
        );

  /// Factory for miss.
  factory FloatingHitText.miss({required Vector2 position}) => FloatingHitText(
      quality: HitQuality.miss,
      position: position,
      floatDistance: 60,
      duration: 0.8,
    );

  /// Factory for good hit.
  factory FloatingHitText.good({required Vector2 position}) => FloatingHitText(
      quality: HitQuality.good,
      position: position,
    );

  /// Factory for perfect hit.
  factory FloatingHitText.perfect({required Vector2 position}) => FloatingHitText(
      quality: HitQuality.perfect,
      position: position,
    );
  final HitQuality quality;
  final double floatDistance;
  final double duration;

  static String _getTextForQuality(HitQuality quality) => switch (quality) {
      HitQuality.perfect => 'PERFECT',
      HitQuality.good => 'GOOD',
      HitQuality.miss => 'MISS',
    };

  static TextPaint _getTextRendererForQuality(HitQuality quality) {
    final textStyle = switch (quality) {
      HitQuality.perfect => DrumlyTextStyles.perfectFeedback,
      HitQuality.good => DrumlyTextStyles.goodFeedback,
      HitQuality.miss => DrumlyTextStyles.missFeedback,
    };

    return TextPaint(
      style: textStyle,
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Float upward effect
    add(
      MoveByEffect(
        Vector2(0, -floatDistance),
        EffectController(
          duration: duration,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Fade out effect
    add(
      OpacityEffect.to(
        0.0,
        EffectController(
          duration: duration,
          curve: Curves.easeIn,
        ),
        onComplete: () => removeFromParent(),
      ),
    );

    // Scale effect (slight bounce for perfect)
    if (quality == HitQuality.perfect) {
      add(
        SequenceEffect([
          ScaleEffect.to(
            Vector2.all(1.2),
            EffectController(duration: 0.15, curve: Curves.easeOut),
          ),
          ScaleEffect.to(
            Vector2.all(1.0),
            EffectController(duration: 0.15, curve: Curves.easeIn),
          ),
        ]),
      );
    }
  }
}

/// ============================================================================
/// COMBO TEXT - Special text for combo milestones
/// ============================================================================

class ComboText extends TextComponent {

  ComboText({
    required this.combo,
    required Vector2 position,
    this.isMilestone = false,
  }) : super(
          text: '${combo}x COMBO',
          textRenderer: TextPaint(
            style: DrumlyTextStyles.comboDisplay.copyWith(
              fontSize: isMilestone ? 40 : 32,
            ),
          ),
          position: position,
          anchor: Anchor.center,
        );

  /// Factory for milestone combos (10x, 25x, 50x, 100x).
  factory ComboText.milestone({
    required int combo,
    required Vector2 position,
  }) => ComboText(
      combo: combo,
      position: position,
      isMilestone: true,
    );
  final int combo;
  final bool isMilestone;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final duration = isMilestone ? 1.5 : 1.0;
    final floatDistance = isMilestone ? 100.0 : 80.0;

    // Float upward
    add(
      MoveByEffect(
        Vector2(0, -floatDistance),
        EffectController(
          duration: duration,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Fade out
    add(
      OpacityEffect.to(
        0.0,
        EffectController(
          duration: duration,
          curve: Curves.easeIn,
        ),
        onComplete: () => removeFromParent(),
      ),
    );

    // Special effects for milestones
    if (isMilestone) {
      // Pulse animation
      add(
        SequenceEffect([
          ScaleEffect.to(
            Vector2.all(1.3),
            EffectController(duration: 0.2, curve: Curves.easeOut),
          ),
          ScaleEffect.to(
            Vector2.all(1.0),
            EffectController(duration: 0.2, curve: Curves.easeIn),
          ),
        ]),
      );
    }
  }
}

/// ============================================================================
/// SCORE TEXT - Floating score numbers
/// ============================================================================

class ScoreText extends TextComponent {

  ScoreText({
    required this.scoreValue,
    required Vector2 position,
  }) : super(
          text: '+$scoreValue',
          textRenderer: TextPaint(
            style: DrumlyTextStyles.body.copyWith(
              fontSize: 20,
              color: DrumlyColors.neonGold,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  color: DrumlyColors.neonGoldGlow,
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          position: position,
          anchor: Anchor.center,
        );
  final int scoreValue;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Float upward
    add(
      MoveByEffect(
        Vector2(0, -60),
        EffectController(
          duration: 0.8,
          curve: Curves.easeOut,
        ),
      ),
    );

    // Fade out
    add(
      OpacityEffect.to(
        0.0,
        EffectController(
          duration: 0.8,
          curve: Curves.easeIn,
        ),
        onComplete: () => removeFromParent(),
      ),
    );
  }
}
