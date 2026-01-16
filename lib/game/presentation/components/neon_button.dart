import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drumly/game/core/constants/drumly_colors.dart';
import 'package:drumly/game/core/constants/drumly_text_styles.dart';

/// ============================================================================
/// NEON BUTTON - Modern neon-style button component
/// ============================================================================
///
/// Reusable button with:
/// - Gradient border glow
/// - Pulse animation on hover/press
/// - Haptic feedback
/// - Disabled state with opacity
/// - Customizable colors
/// ============================================================================

enum NeonButtonSize {
  small,
  medium,
  large,
}

class NeonButton extends StatefulWidget {

  const NeonButton({
    required this.label, required this.onPressed, super.key,
    this.color = DrumlyColors.neonCyan,
    this.size = NeonButtonSize.medium,
    this.icon,
    this.fullWidth = false,
    this.enableHaptic = true,
  });

  /// Factory for danger style (red).
  factory NeonButton.danger({
    required String label,
    required VoidCallback? onPressed,
    NeonButtonSize size = NeonButtonSize.medium,
    IconData? icon,
    bool fullWidth = false,
  }) => NeonButton(
      label: label,
      onPressed: onPressed,
      color: DrumlyColors.missColor,
      size: size,
      icon: icon,
      fullWidth: fullWidth,
    );

  /// Factory for success style (green).
  factory NeonButton.success({
    required String label,
    required VoidCallback? onPressed,
    NeonButtonSize size = NeonButtonSize.medium,
    IconData? icon,
    bool fullWidth = false,
  }) => NeonButton(
      label: label,
      onPressed: onPressed,
      color: DrumlyColors.successColor,
      size: size,
      icon: icon,
      fullWidth: fullWidth,
    );

  /// Factory for accent style (gold).
  factory NeonButton.accent({
    required String label,
    required VoidCallback? onPressed,
    NeonButtonSize size = NeonButtonSize.medium,
    IconData? icon,
    bool fullWidth = false,
  }) => NeonButton(
      label: label,
      onPressed: onPressed,
      color: DrumlyColors.neonGold,
      size: size,
      icon: icon,
      fullWidth: fullWidth,
    );

  /// Factory for primary style (cyan).
  factory NeonButton.primary({
    required String label,
    required VoidCallback? onPressed,
    NeonButtonSize size = NeonButtonSize.medium,
    IconData? icon,
    bool fullWidth = false,
  }) => NeonButton(
      label: label,
      onPressed: onPressed,
      size: size,
      icon: icon,
      fullWidth: fullWidth,
    );
  /// Button label text.
  final String label;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Primary color for gradient and glow.
  final Color color;

  /// Button size preset.
  final NeonButtonSize size;

  /// Icon to display (optional).
  final IconData? icon;

  /// Full width button.
  final bool fullWidth;

  /// Enable haptic feedback.
  final bool enableHaptic;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  EdgeInsets get _padding => switch (widget.size) {
      NeonButtonSize.small => const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      NeonButtonSize.medium => const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      NeonButtonSize.large => const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
    };

  double get _fontSize => switch (widget.size) {
      NeonButtonSize.small => 14,
      NeonButtonSize.medium => 18,
      NeonButtonSize.large => 22,
    };

  double get _iconSize => switch (widget.size) {
      NeonButtonSize.small => 16,
      NeonButtonSize.medium => 20,
      NeonButtonSize.large => 24,
    };

  double get _borderRadius => switch (widget.size) {
      NeonButtonSize.small => 12,
      NeonButtonSize.medium => 16,
      NeonButtonSize.large => 20,
    };

  void _handleTap() {
    if (widget.onPressed == null) return;

    if (widget.enableHaptic) {
      HapticFeedback.mediumImpact();
    }

    widget.onPressed!();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final color = widget.color;
    final darkerColor = Color.lerp(color, Colors.black, 0.3)!;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_borderRadius),
            gradient: LinearGradient(
              colors: [color, darkerColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: color.withValues(alpha:
                        _isPressed ? 0.6 : 0.4 * _pulseAnimation.value,
                      ),
                      blurRadius: _isPressed ? 30 : 20,
                      spreadRadius: _isPressed ? 2 : 0,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : _handleTap,
              onTapDown: isDisabled ? null : _handleTapDown,
              onTapUp: isDisabled ? null : _handleTapUp,
              onTapCancel: isDisabled ? null : _handleTapCancel,
              borderRadius: BorderRadius.circular(_borderRadius),
              child: Opacity(
                opacity: isDisabled ? DrumlyColors.disabledOpacity : 1.0,
                child: Padding(
                  padding: _padding,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: DrumlyColors.textPrimary,
                          size: _iconSize,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: DrumlyTextStyles.buttonLabel.copyWith(
                          fontSize: _fontSize,
                          color: isDisabled
                              ? DrumlyColors.textDisabled
                              : DrumlyColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

/// ============================================================================
/// NEON ICON BUTTON - Icon-only variant
/// ============================================================================

class NeonIconButton extends StatefulWidget {

  const NeonIconButton({
    required this.icon, required this.onPressed, super.key,
    this.color = DrumlyColors.neonCyan,
    this.size = 48,
    this.enableHaptic = true,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final double size;
  final bool enableHaptic;

  @override
  State<NeonIconButton> createState() => _NeonIconButtonState();
}

class _NeonIconButtonState extends State<NeonIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;

    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final color = widget.color;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => GestureDetector(
          onTap: isDisabled ? null : _handleTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              boxShadow: isDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: color.withValues(alpha:
                          _isPressed ? 0.6 : 0.4 * _pulseAnimation.value,
                        ),
                        blurRadius: _isPressed ? 20 : 16,
                        spreadRadius: _isPressed ? 1 : 0,
                      ),
                    ],
            ),
            child: Icon(
              widget.icon,
              color: isDisabled ? DrumlyColors.textDisabled : color,
              size: widget.size * 0.5,
            ),
          ),
        ),
    );
  }
}
