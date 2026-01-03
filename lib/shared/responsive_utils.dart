import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Responsive utility class for adaptive layouts across different screen sizes.
/// Provides scaling factors, breakpoints, and helper methods for responsive UI.
class ResponsiveUtils {
  ResponsiveUtils._();

  // Design reference dimensions (based on standard phone)
  static const double _designWidth = 375.0;
  static const double _designHeight = 812.0;

  /// Breakpoints for device classification
  static const double smallPhoneMaxWidth = 360.0;
  static const double phoneMaxWidth = 600.0;
  static const double tabletMaxWidth = 1024.0;

  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= smallPhoneMaxWidth) return DeviceType.smallPhone;
    if (width <= phoneMaxWidth) return DeviceType.phone;
    if (width <= tabletMaxWidth) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Check if the device is in landscape orientation
  static bool isLandscape(BuildContext context) => MediaQuery.of(context).orientation == Orientation.landscape;

  /// Get screen metrics for responsive calculations
  static ScreenMetrics getMetrics(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return ScreenMetrics(
      width: mediaQuery.size.width,
      height: mediaQuery.size.height,
      safeArea: mediaQuery.padding,
      devicePixelRatio: mediaQuery.devicePixelRatio,
    );
  }

  /// Calculate scale factor based on screen width
  static double widthScale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width / _designWidth;
  }

  /// Calculate scale factor based on screen height
  static double heightScale(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return height / _designHeight;
  }

  /// Calculate a balanced scale factor (average of width and height scales)
  static double scale(BuildContext context) => (widthScale(context) + heightScale(context)) / 2;

  /// Calculate minimum scale to prevent overflow
  static double minScale(BuildContext context) => math.min(widthScale(context), heightScale(context));

  /// Responsive width - scales a design width to actual screen width
  static double rw(BuildContext context, double designValue) => designValue * widthScale(context);

  /// Responsive height - scales a design height to actual screen height
  static double rh(BuildContext context, double designValue) => designValue * heightScale(context);

  /// Responsive size using minimum scale (prevents overflow)
  static double rs(BuildContext context, double designValue) => designValue * minScale(context);

  /// Responsive font size with constraints
  static double fontSize(
    BuildContext context,
    double designSize, {
    double minSize = 10.0,
    double maxSize = 36.0,
  }) {
    final scaled = designSize * minScale(context);
    return scaled.clamp(minSize, maxSize);
  }

  /// Responsive padding
  static EdgeInsets padding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    final s = minScale(context);

    if (all != null) {
      return EdgeInsets.all(all * s);
    }

    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * s,
      top: (top ?? vertical ?? 0) * s,
      right: (right ?? horizontal ?? 0) * s,
      bottom: (bottom ?? vertical ?? 0) * s,
    );
  }

  /// Get safe area padding
  static EdgeInsets safeArea(BuildContext context) => MediaQuery.of(context).padding;

  /// Calculate available height minus safe areas
  static double availableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
  }

  /// Calculate available width minus safe areas
  static double availableWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width -
        mediaQuery.padding.left -
        mediaQuery.padding.right;
  }

  /// Get aspect ratio of the screen
  static double aspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  /// Calculate a responsive value that adapts between phone and tablet
  static double adaptive(
    BuildContext context, {
    required double phone,
    required double tablet,
    double? smallPhone,
    double? desktop,
  }) {
    final deviceType = getDeviceType(context);
    switch (deviceType) {
      case DeviceType.smallPhone:
        return smallPhone ?? phone * 0.85;
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet;
      case DeviceType.desktop:
        return desktop ?? tablet * 1.2;
    }
  }

  /// Calculate icon size responsively
  static double iconSize(
    BuildContext context,
    double designSize, {
    double minSize = 16.0,
    double maxSize = 64.0,
  }) {
    final scaled = designSize * minScale(context);
    return scaled.clamp(minSize, maxSize);
  }

  /// Calculate button size responsively
  static Size buttonSize(
    BuildContext context, {
    required double designWidth,
    required double designHeight,
    double minWidth = 40.0,
    double minHeight = 40.0,
    double maxWidth = 120.0,
    double maxHeight = 80.0,
  }) {
    final s = minScale(context);
    return Size(
      (designWidth * s).clamp(minWidth, maxWidth),
      (designHeight * s).clamp(minHeight, maxHeight),
    );
  }

  /// Calculate responsive spacing
  static double spacing(BuildContext context, double designSpacing) => (designSpacing * minScale(context)).clamp(4.0, designSpacing * 2);

  /// Calculate responsive border radius
  static double borderRadius(BuildContext context, double designRadius) => (designRadius * minScale(context)).clamp(4.0, designRadius * 1.5);
}

/// Device type classification
enum DeviceType {
  smallPhone,
  phone,
  tablet,
  desktop,
}

/// Screen metrics data class
class ScreenMetrics {
  const ScreenMetrics({
    required this.width,
    required this.height,
    required this.safeArea,
    required this.devicePixelRatio,
  });

  final double width;
  final double height;
  final EdgeInsets safeArea;
  final double devicePixelRatio;

  double get aspectRatio => width / height;
  bool get isLandscape => width > height;
  bool get isPortrait => height >= width;

  double get availableWidth => width - safeArea.left - safeArea.right;
  double get availableHeight => height - safeArea.top - safeArea.bottom;
}

/// Extension on BuildContext for convenient access to responsive utilities
extension ResponsiveContextExtension on BuildContext {
  /// Get responsive utilities metrics
  ScreenMetrics get screenMetrics => ResponsiveUtils.getMetrics(this);

  /// Get device type
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);

  /// Check if device is a small phone
  bool get isSmallPhone => deviceType == DeviceType.smallPhone;

  /// Check if device is a phone (including small phones)
  bool get isPhone =>
      deviceType == DeviceType.smallPhone || deviceType == DeviceType.phone;

  /// Check if device is a tablet
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Check if in landscape mode
  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  /// Responsive width
  double rw(double designValue) => ResponsiveUtils.rw(this, designValue);

  /// Responsive height
  double rh(double designValue) => ResponsiveUtils.rh(this, designValue);

  /// Responsive size (uses minimum scale)
  double rs(double designValue) => ResponsiveUtils.rs(this, designValue);

  /// Responsive font size
  double fontSize(double designSize, {double minSize = 10.0, double maxSize = 36.0}) =>
      ResponsiveUtils.fontSize(this, designSize, minSize: minSize, maxSize: maxSize);

  /// Responsive spacing
  double spacing(double designSpacing) => ResponsiveUtils.spacing(this, designSpacing);

  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
}

/// A widget that provides responsive constraints for its child
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });

  final Widget Function(
    BuildContext context,
    ScreenMetrics metrics,
    DeviceType deviceType,
  ) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final metrics = ResponsiveUtils.getMetrics(context);
        final deviceType = ResponsiveUtils.getDeviceType(context);
        return builder(context, metrics, deviceType);
      },
    );
}

/// A widget that adapts its child based on device type
class AdaptiveWidget extends StatelessWidget {
  const AdaptiveWidget({
    required this.phone,
    this.smallPhone,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget phone;
  final Widget? smallPhone;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.smallPhone:
        return smallPhone ?? phone;
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.desktop:
        return desktop ?? tablet ?? phone;
    }
  }
}
