import 'dart:ui' as ui;

/// Cihaz tipi ve ekran özellikleri.
enum DeviceType {
  phone,
  tablet,
  desktop,
}

/// Cihaz profili - ekran boyutu ve yoğunluğu bilgileri.
class DeviceProfile {

  const DeviceProfile({
    required this.type,
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
    required this.aspectRatio,
  });

  /// Mevcut ekran boyutundan DeviceProfile oluşturur.
  factory DeviceProfile.fromSize(ui.Size size) {
    final width = size.width;
    final height = size.height;
    final pixelRatio = ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1.0;
    final aspectRatio = width / height;

    // Cihaz tipini belirle
    final DeviceType type;
    final minDimension = width < height ? width : height;

    if (minDimension >= 600) {
      type = DeviceType.tablet;
    } else if (minDimension >= 1024) {
      type = DeviceType.desktop;
    } else {
      type = DeviceType.phone;
    }

    return DeviceProfile(
      type: type,
      screenWidth: width,
      screenHeight: height,
      pixelRatio: pixelRatio,
      aspectRatio: aspectRatio,
    );
  }
  final DeviceType type;
  final double screenWidth;
  final double screenHeight;
  final double pixelRatio;
  final double aspectRatio;

  bool get isPhone => type == DeviceType.phone;
  bool get isTablet => type == DeviceType.tablet;
  bool get isDesktop => type == DeviceType.desktop;

  /// Ekran büyük mü? (tablet veya desktop)
  bool get isLargeScreen => isTablet || isDesktop;

  /// Ekran portrait mı?
  bool get isPortrait => aspectRatio < 1.0;

  /// Ekran landscape mi?
  bool get isLandscape => aspectRatio >= 1.0;
}
