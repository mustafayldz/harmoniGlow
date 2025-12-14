import 'package:flutter/material.dart';

/// 🎨 Shared App Gradient Themes
/// Centralized gradient definitions to avoid duplication across screens
/// Used in: Settings, Songs, Training, Home, Player, Notifications, etc.
abstract final class AppGradients {
  // ===== CACHED GRADIENT LISTS =====
  // Pre-computed to avoid repeated allocations

  /// Dark theme background gradient colors
  static const List<Color> darkBackground = [
    Color(0xFF0F172A), // Dark slate
    Color(0xFF1E293B), // Lighter slate
    Color(0xFF334155), // Even lighter
  ];

  /// Light theme background gradient colors
  static const List<Color> lightBackground = [
    Color(0xFFF8FAFC), // Light gray
    Color(0xFFE2E8F0), // Slightly darker
    Color(0xFFCBD5E1), // Even darker
  ];

  /// Dark theme card gradient colors
  static const List<Color> darkCard = [
    Color(0xFF1E293B),
    Color(0xFF334155),
  ];

  /// Light theme card gradient colors
  static const List<Color> lightCard = [
    Colors.white,
    Color(0xFFF8FAFC),
  ];

  /// Primary accent color
  static const Color primaryAccent = Color(0xFF6366F1);

  /// Secondary accent color
  static const Color secondaryAccent = Color(0xFF4F46E5);

  // ===== CACHED GRADIENTS =====

  /// Background gradient for dark mode
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: darkBackground,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Background gradient for light mode
  static const LinearGradient lightBackgroundGradient = LinearGradient(
    colors: lightBackground,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Get background gradient based on theme
  static LinearGradient backgroundGradient(bool isDarkMode) =>
      isDarkMode ? darkBackgroundGradient : lightBackgroundGradient;

  /// Card gradient for dark mode with customizable alpha
  static LinearGradient darkCardGradient({
    double alphaStart = 0.8,
    double alphaEnd = 0.6,
  }) =>
      LinearGradient(
        colors: [
          darkCard[0].withValues(alpha: alphaStart),
          darkCard[1].withValues(alpha: alphaEnd),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Card gradient for light mode with customizable alpha
  static LinearGradient lightCardGradient({
    double alphaStart = 0.9,
    double alphaEnd = 0.8,
  }) =>
      LinearGradient(
        colors: [
          lightCard[0].withValues(alpha: alphaStart),
          lightCard[1].withValues(alpha: alphaEnd),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Get card gradient based on theme
  static LinearGradient cardGradient(
    bool isDarkMode, {
    double alphaStart = 0.8,
    double alphaEnd = 0.6,
  }) =>
      isDarkMode
          ? darkCardGradient(alphaStart: alphaStart, alphaEnd: alphaEnd)
          : lightCardGradient(
              alphaStart: alphaStart + 0.1,
              alphaEnd: alphaEnd + 0.2,
            );

  /// Music icon gradient (used in song cards)
  static LinearGradient musicIconGradient(bool isDarkMode) => LinearGradient(
        colors: isDarkMode
            ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
            : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// 🎨 Shared App Colors
/// Centralized color definitions with alpha variants
abstract final class AppColors {
  /// Get overlay color based on theme
  static Color overlayColor(bool isDarkMode, {double alpha = 0.1}) =>
      isDarkMode
          ? Colors.white.withValues(alpha: alpha)
          : Colors.black.withValues(alpha: alpha);

  /// Get text color based on theme
  static Color textColor(bool isDarkMode, {double alpha = 1.0}) =>
      isDarkMode
          ? Colors.white.withValues(alpha: alpha)
          : Colors.black.withValues(alpha: alpha);

  /// Get secondary text color based on theme
  static Color secondaryTextColor(bool isDarkMode) =>
      textColor(isDarkMode, alpha: 0.7);

  /// Get hint text color based on theme
  static Color hintTextColor(bool isDarkMode) =>
      textColor(isDarkMode, alpha: 0.5);

  /// Get border color based on theme
  static Color borderColor(bool isDarkMode) =>
      overlayColor(isDarkMode, alpha: isDarkMode ? 0.1 : 0.05);

  /// Get card shadow color based on theme
  static Color shadowColor(bool isDarkMode) =>
      isDarkMode
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.2);
}

/// 🎨 Shared App Decorations
/// Pre-built BoxDecoration instances for common UI patterns
abstract final class AppDecorations {
  /// Standard card decoration with gradient and border
  static BoxDecoration cardDecoration(bool isDarkMode) => BoxDecoration(
        gradient: AppGradients.cardGradient(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor(isDarkMode)),
      );

  /// Elevated card decoration with shadow
  static BoxDecoration elevatedCardDecoration(bool isDarkMode) => BoxDecoration(
        gradient: AppGradients.cardGradient(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor(isDarkMode)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(isDarkMode),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );

  /// Background decoration for scaffold
  static BoxDecoration backgroundDecoration(bool isDarkMode) => BoxDecoration(
        gradient: AppGradients.backgroundGradient(isDarkMode),
      );

  /// Icon container decoration
  static BoxDecoration iconContainerDecoration(bool isDarkMode) =>
      BoxDecoration(
        color: AppColors.overlayColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      );

  /// Accent icon container decoration
  static BoxDecoration accentIconContainerDecoration({
    Color? color,
    double alpha = 0.1,
  }) =>
      BoxDecoration(
        color: (color ?? AppGradients.primaryAccent).withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(12),
      );

  /// Chip decoration
  static BoxDecoration chipDecoration(bool isDarkMode) => BoxDecoration(
        color: AppColors.overlayColor(isDarkMode, alpha: isDarkMode ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(8),
      );
}
