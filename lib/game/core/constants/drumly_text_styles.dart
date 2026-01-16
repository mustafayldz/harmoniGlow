import 'package:flutter/painting.dart';
import 'package:drumly/game/core/constants/drumly_colors.dart';

/// ============================================================================
/// DRUMLY TEXT STYLES - Typography system
/// ============================================================================
///
/// Defines all text styles used throughout the game.
/// Follows a consistent hierarchy: display → headline → title → body → caption.
/// ============================================================================

abstract final class DrumlyTextStyles {
  // ===========================================================================
  // DISPLAY STYLES (Largest - Menu titles, game title)
  // ===========================================================================

  /// Display - Extra large with neon glow.
  /// Use for: Main menu title, game branding.
  static const display = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    color: DrumlyColors.textPrimary,
    letterSpacing: 3,
    height: 1.2,
    shadows: [
      Shadow(
        color: DrumlyColors.neonCyan,
        blurRadius: 24,
      ),
      Shadow(
        color: DrumlyColors.neonCyanGlow,
        blurRadius: 40,
      ),
    ],
  );

  /// Display medium - Game over title.
  static const displayMedium = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: DrumlyColors.textPrimary,
    letterSpacing: 2,
    height: 1.2,
    shadows: [
      Shadow(
        color: DrumlyColors.neonCyan,
        blurRadius: 20,
      ),
    ],
  );

  // ===========================================================================
  // HEADLINE STYLES (Large - Scores, combo counter)
  // ===========================================================================

  /// Headline - Large numbers (score, combo).
  static const headline = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: DrumlyColors.textPrimary,
    letterSpacing: 1,
    height: 1.2,
  );

  /// Headline medium - Section headers.
  static const headlineMedium = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: DrumlyColors.textPrimary,
    letterSpacing: 1,
    height: 1.3,
  );

  /// Headline small - Subsection headers.
  static const headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: DrumlyColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ===========================================================================
  // TITLE STYLES (Medium - Button labels, card titles)
  // ===========================================================================

  /// Title - Button text, important labels.
  static const title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: DrumlyColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  /// Title medium - Secondary buttons.
  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: DrumlyColors.textPrimary,
    letterSpacing: 0.3,
    height: 1.4,
  );

  // ===========================================================================
  // BODY STYLES (Default - Normal text)
  // ===========================================================================

  /// Body - Default text for most UI.
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: DrumlyColors.textSecondary,
    letterSpacing: 0.2,
    height: 1.5,
  );

  /// Body medium - Slightly emphasized text.
  static const bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: DrumlyColors.textSecondary,
    letterSpacing: 0.2,
    height: 1.5,
  );

  /// Body small - Less important text.
  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: DrumlyColors.textSecondary,
    letterSpacing: 0.1,
    height: 1.5,
  );

  // ===========================================================================
  // CAPTION STYLES (Small - Labels, hints, metadata)
  // ===========================================================================

  /// Caption - Small informational text.
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: DrumlyColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  /// Caption small - Tiny labels (if needed).
  static const captionSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: DrumlyColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // ===========================================================================
  // SPECIALIZED STYLES
  // ===========================================================================

  /// Score display - Large animated numbers.
  static const scoreDisplay = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.w900,
    color: DrumlyColors.neonGold,
    letterSpacing: 2,
    height: 1.0,
    shadows: [
      Shadow(
        color: DrumlyColors.neonGoldGlow,
        blurRadius: 30,
      ),
    ],
  );

  /// Combo display - Combo counter with glow.
  static const comboDisplay = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: DrumlyColors.neonCyan,
    letterSpacing: 1,
    height: 1.0,
    shadows: [
      Shadow(
        color: DrumlyColors.neonCyanGlow,
        blurRadius: 20,
      ),
    ],
  );

  /// Perfect hit feedback - Gold glow.
  static const perfectFeedback = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: DrumlyColors.perfectColor,
    letterSpacing: 2,
    height: 1.0,
    shadows: [
      Shadow(
        color: DrumlyColors.neonGoldGlow,
        blurRadius: 20,
      ),
    ],
  );

  /// Good hit feedback - Cyan glow.
  static const goodFeedback = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: DrumlyColors.goodColor,
    letterSpacing: 1.5,
    height: 1.0,
    shadows: [
      Shadow(
        color: DrumlyColors.neonCyanGlow,
        blurRadius: 16,
      ),
    ],
  );

  /// Miss feedback - Red glow.
  static const missFeedback = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: DrumlyColors.missColor,
    letterSpacing: 1,
    height: 1.0,
    shadows: [
      Shadow(
        color: DrumlyColors.missColor,
        blurRadius: 12,
      ),
    ],
  );

  /// Button label - Uppercase with spacing.
  static const buttonLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: DrumlyColors.textPrimary,
    letterSpacing: 1.5,
    height: 1.2,
  );

  /// Disabled button label.
  static TextStyle get buttonLabelDisabled => buttonLabel.copyWith(
        color: DrumlyColors.textDisabled,
      );
}

/// ============================================================================
/// SPACING CONSTANTS
/// ============================================================================

abstract final class DrumlySpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

/// ============================================================================
/// BORDER RADIUS CONSTANTS
/// ============================================================================

abstract final class DrumlyRadius {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const circular = 999.0;
}
