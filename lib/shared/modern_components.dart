import 'package:flutter/material.dart';

/// 🎨 Modern Design System Components
class ModernComponents {
  // Modern Color Palette
  static const modernColors = ModernColors();

  // Gradient Presets
  static const gradients = ModernGradients();

  // Shadow Presets
  static const shadows = ModernShadows();
}

/// 🌈 Modern Color Palette
class ModernColors {
  const ModernColors();

  // Primary Colors
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);

  // Secondary Colors
  static const secondary = Color(0xFF8B5CF6);
  static const secondaryDark = Color(0xFF7C3AED);

  // Accent Colors
  static const accent = Color(0xFF06B6D4);
  static const accentDark = Color(0xFF0891B2);

  // Success Colors
  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF059669);

  // Warning Colors
  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFD97706);

  // Error Colors
  static const error = Color(0xFFEF4444);
  static const errorDark = Color(0xFFDC2626);

  // Neutral Colors - Dark Theme
  static const darkBackground1 = Color(0xFF0F172A);
  static const darkBackground2 = Color(0xFF1E293B);
  static const darkBackground3 = Color(0xFF334155);
  static const darkSurface = Color(0xFF475569);

  // Neutral Colors - Light Theme
  static const lightBackground1 = Color(0xFFF8FAFC);
  static const lightBackground2 = Color(0xFFE2E8F0);
  static const lightBackground3 = Color(0xFFCBD5E1);
  static const lightSurface = Color(0xFF94A3B8);
}

/// 🌅 Modern Gradient Presets
class ModernGradients {
  const ModernGradients();

  // Background Gradients
  static const darkBackground = LinearGradient(
    colors: [
      ModernColors.darkBackground1,
      ModernColors.darkBackground2,
      ModernColors.darkBackground3,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const lightBackground = LinearGradient(
    colors: [
      ModernColors.lightBackground1,
      ModernColors.lightBackground2,
      ModernColors.lightBackground3,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Card Gradients
  static const primaryCard = LinearGradient(
    colors: [ModernColors.primary, ModernColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const secondaryCard = LinearGradient(
    colors: [ModernColors.secondary, ModernColors.secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentCard = LinearGradient(
    colors: [ModernColors.accent, ModernColors.accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successCard = LinearGradient(
    colors: [ModernColors.success, ModernColors.successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warningCard = LinearGradient(
    colors: [ModernColors.warning, ModernColors.warningDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const errorCard = LinearGradient(
    colors: [ModernColors.error, ModernColors.errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// 🌟 Modern Shadow Presets
class ModernShadows {
  const ModernShadows();

  static List<BoxShadow> small(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> medium(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> large(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> extraLarge(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}

/// 🎨 Modern App Bar Component
class ModernAppBar extends StatelessWidget {
  const ModernAppBar({
    required this.title,
    required this.isDarkMode,
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (showBackButton) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      );
}

/// 💎 Modern Glass Card Component
class ModernGlassCard extends StatelessWidget {
  const ModernGlassCard({
    required this.child,
    required this.isDarkMode,
    super.key,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.gradient,
    this.borderColor,
    this.borderRadius = 24,
    this.boxShadow,
  });
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isDarkMode;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          gradient: gradient ??
              LinearGradient(
                colors: isDarkMode
                    ? [
                        ModernColors.darkBackground2.withValues(alpha: 0.9),
                        ModernColors.darkBackground3.withValues(alpha: 0.7),
                      ]
                    : [
                        Colors.white,
                        ModernColors.lightBackground1,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ??
                (isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05)),
          ),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(24),
          child: child,
        ),
      );
}

/// 🌈 Modern Gradient Card Component
class ModernGradientCard extends StatelessWidget {
  const ModernGradientCard({
    required this.child,
    required this.gradient,
    super.key,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.boxShadow,
  });
  final Widget child;
  final Gradient gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
          ),
        ),
      );
}

/// 📱 Modern Screen Layout
class ModernScreenLayout extends StatelessWidget {
  const ModernScreenLayout({
    required this.title,
    required this.body,
    required this.isDarkMode,
    super.key,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.bottomWidget,
  });
  final String title;
  final Widget body;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? bottomWidget;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? ModernGradients.darkBackground
                : ModernGradients.lightBackground,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Modern App Bar
                ModernAppBar(
                  title: title,
                  showBackButton: showBackButton,
                  onBackPressed: onBackPressed,
                  actions: actions,
                  isDarkMode: isDarkMode,
                ),

                // Content
                Expanded(child: body),

                // Bottom Widget
                if (bottomWidget != null) bottomWidget!,
              ],
            ),
          ),
        ),
      );
}

/// 🎯 Modern Icon Button
class ModernIconButton extends StatelessWidget {
  const ModernIconButton({
    required this.icon,
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.padding = 12,
    this.borderRadius = 12,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: color ?? Colors.white,
            size: size,
          ),
          onPressed: onPressed,
          padding: EdgeInsets.all(padding),
        ),
      );
}

/// 🔘 Modern Button
class ModernButton extends StatelessWidget {
  const ModernButton({
    required this.text,
    super.key,
    this.onPressed,
    this.gradient,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.icon,
    this.isLoading = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient ?? ModernGradients.primaryCard,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: (gradient?.colors.first ?? ModernColors.primary)
                  .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: isLoading ? null : onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ] else ...[
                    if (icon != null) ...[
                      Icon(
                        icon,
                        color: textColor ?? Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
