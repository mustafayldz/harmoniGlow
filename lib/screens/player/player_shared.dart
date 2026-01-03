import 'package:flutter/material.dart';
import 'package:drumly/shared/responsive_utils.dart';

/// Responsive control button for player screens.
/// Adapts size based on screen dimensions to work across phones and tablets.
class ResponsiveControlButton extends StatelessWidget {
  const ResponsiveControlButton({
    this.icon,
    this.onPressed,
    this.iconSizeRatio = 0.08,
    this.imagePath,
    this.backgroundColor,
    this.isLarge = false,
    super.key,
  });

  final IconData? icon;
  final VoidCallback? onPressed;
  final double iconSizeRatio; // Ratio of screen width for icon size
  final String? imagePath;
  final Color? backgroundColor;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveUtils.getMetrics(context);
    final minDimension = metrics.width < metrics.height 
        ? metrics.width 
        : metrics.height;
    
    // Calculate responsive sizes
    final baseSize = minDimension * (isLarge ? 0.16 : 0.12);
    final buttonSize = baseSize.clamp(48.0, 80.0);
    final iconSizeValue = (buttonSize * 0.5).clamp(20.0, 52.0);
    final imageSize = (buttonSize * 0.4).clamp(18.0, 32.0);
    final marginSize = (minDimension * 0.02).clamp(8.0, 24.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: marginSize),
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: buttonSize * 0.15,
            offset: Offset(0, buttonSize * 0.07),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    width: imageSize,
                    height: imageSize,
                    color: backgroundColor != null ? Colors.white : Colors.black,
                  )
                : Icon(
                    icon,
                    size: iconSizeValue,
                    color: Colors.black,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Legacy function wrapper for backward compatibility
/// Use ResponsiveControlButton widget for new implementations
Widget controlButton({
  IconData? icon,
  VoidCallback? onPressed,
  double iconSize = 32,
  String? imagePath,
  Color? backgroundColor,
}) =>
    Builder(
      builder: (context) {
        final metrics = ResponsiveUtils.getMetrics(context);
        final minDimension = metrics.width < metrics.height 
            ? metrics.width 
            : metrics.height;
        
        // Calculate responsive sizes
        final isLargeIcon = iconSize > 40;
        final baseSize = minDimension * (isLargeIcon ? 0.16 : 0.12);
        final buttonSize = baseSize.clamp(48.0, 80.0);
        final responsiveIconSize = isLargeIcon 
            ? (buttonSize * 0.65).clamp(32.0, 52.0)
            : (buttonSize * 0.5).clamp(20.0, 36.0);
        final imageSize = (buttonSize * 0.4).clamp(18.0, 32.0);
        final marginSize = (minDimension * 0.02).clamp(8.0, 24.0);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: marginSize),
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: buttonSize * 0.15,
                offset: Offset(0, buttonSize * 0.07),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        width: imageSize,
                        height: imageSize,
                        color: backgroundColor != null ? Colors.white : Colors.black,
                      )
                    : Icon(
                        icon,
                        size: responsiveIconSize,
                        color: Colors.black,
                      ),
              ),
            ),
          ),
        );
      },
    );
