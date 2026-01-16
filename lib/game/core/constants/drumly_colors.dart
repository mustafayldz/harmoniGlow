import 'package:flutter/painting.dart';

/// ============================================================================
/// DRUMLY COLORS - Consolidated color palette
/// ============================================================================
///
/// Modern neon-themed color scheme for the entire app.
/// Follows the design system with primary neon cyan and accent gold.
/// ============================================================================

abstract final class DrumlyColors {
  // ===========================================================================
  // PRIMARY COLORS (Neon Cyan)
  // ===========================================================================

  /// Primary neon cyan - main brand color.
  static const neonCyan = Color(0xFF4ECDC4);

  /// Neon cyan glow effect - lighter variant.
  static const neonCyanGlow = Color(0xFF6FFFFF);

  /// Neon cyan dark - for subtle accents.
  static const neonCyanDark = Color(0xFF3DB8AF);

  // ===========================================================================
  // ACCENT COLORS (Neon Gold)
  // ===========================================================================

  /// Accent neon gold - for important highlights.
  static const neonGold = Color(0xFFFFD700);

  /// Neon gold glow effect - lighter variant.
  static const neonGoldGlow = Color(0xFFFFEA70);

  /// Neon gold dark - for subtle gold accents.
  static const neonGoldDark = Color(0xFFCCA700);

  // ===========================================================================
  // BACKGROUND COLORS (Dark Theme)
  // ===========================================================================

  /// Main background - deep dark blue.
  static const darkBg = Color(0xFF0A0E27);

  /// Card background - slightly lighter than main bg.
  static const darkCard = Color(0xFF1A1F3A);

  /// Secondary background - for layers.
  static const darkSecondary = Color(0xFF141829);

  // ===========================================================================
  // FEEDBACK COLORS
  // ===========================================================================

  /// Perfect hit color - gold.
  static const perfectColor = neonGold;

  /// Good hit color - cyan.
  static const goodColor = neonCyan;

  /// Miss/error color - red.
  static const missColor = Color(0xFFFF6B6B);

  /// Warning color - orange.
  static const warningColor = Color(0xFFFFB86C);

  /// Success color - green.
  static const successColor = Color(0xFF50FA7B);

  // ===========================================================================
  // UI ELEMENT COLORS
  // ===========================================================================

  /// Primary text - white.
  static const textPrimary = Color(0xFFFFFFFF);

  /// Secondary text - gray.
  static const textSecondary = Color(0xFFBDBDBD);

  /// Disabled text - dark gray.
  static const textDisabled = Color(0xFF6E6E6E);

  /// Divider/border color.
  static const divider = Color(0xFF2A2F4A);

  /// Overlay shadow color.
  static const shadowColor = Color(0x88000000);

  // ===========================================================================
  // LANE COLORS (from GameConstants)
  // ===========================================================================

  /// Lane colors for drum pads - vibrant palette.
  static const List<Color> laneColors = [
    Color(0xFFFF6B6B), // 0: Close Hi-Hat - Red
    Color(0xFFFFE66D), // 1: Open Hi-Hat - Yellow
    Color(0xFF4ECDC4), // 2: Crash - Cyan
    Color(0xFF95E1D3), // 3: Ride - Light Green
    Color(0xFFA8E6CF), // 4: Snare - Mint
    Color(0xFF88D8B0), // 5: Kick - Green
    Color(0xFFB8B5FF), // 6: Tom 1 - Purple
    Color(0xFFFF9F9F), // 7: Floor Tom - Pink
  ];

  // ===========================================================================
  // GRADIENT DEFINITIONS
  // ===========================================================================

  /// Primary gradient - cyan to dark cyan.
  static const primaryGradient = [neonCyan, neonCyanDark];

  /// Accent gradient - gold to dark gold.
  static const accentGradient = [neonGold, neonGoldDark];

  /// Background gradient - dark blue variants.
  static const backgroundGradient = [darkBg, darkSecondary];

  // ===========================================================================
  // OPACITY VARIANTS
  // ===========================================================================

  /// Glass effect opacity.
  static const glassOpacity = 0.7;

  /// Glow effect opacity.
  static const glowOpacity = 0.5;

  /// Subtle overlay opacity.
  static const overlayOpacity = 0.3;

  /// Disabled element opacity.
  static const disabledOpacity = 0.4;
}
