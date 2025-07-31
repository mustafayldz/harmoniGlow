import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BluetoothBanner extends StatelessWidget {
  const BluetoothBanner({
    required this.isConnected,
    required this.deviceName,
    required this.isDarkMode,
    required this.isSmallScreen,
    required this.isMediumScreen,
    super.key,
  });
  final bool isConnected;
  final String deviceName;
  final bool isDarkMode;
  final bool isSmallScreen;
  final bool isMediumScreen;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FindDevicesView()),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isSmallScreen ? 32 : 36,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 6 : 8, // Padding'i biraz azalttık
            vertical: 4,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isConnected
                  ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.green : Colors.red)
                    .withValues(alpha: 0.2),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: Colors.white,
                size: isSmallScreen ? 12 : 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                // ConstrainedBox yerine Flexible kullanıyoruz
                child: Text(
                  _getCompactDisplayText(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 9 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );

  String _getCompactDisplayText() {
    if (!isConnected) {
      // Lokalizasyonlu text'leri kullan
      final notConnectedText = 'notConnected'.tr();

      // Küçük ekranlar için kısaltılmış versiyon
      if (isSmallScreen) {
        // "Not Connected" -> "No BT" gibi kısa alternatifler
        if (notConnectedText.length > 8) {
          return 'OFF'; // Çok uzunsa basit "OFF" kullan
        }
      }
      return notConnectedText;
    }

    if (deviceName.isEmpty) {
      final connectedText = 'connected'.tr();

      // Küçük ekranlar için kısaltılmış versiyon
      if (isSmallScreen) {
        if (connectedText.length > 8) {
          return 'ON'; // Çok uzunsa basit "ON" kullan
        }
      }
      return connectedText;
    }

    // Cihaz adı varsa, cihaz adını göster
    final maxLength = isSmallScreen ? 6 : 10;

    // Özel durumlar
    if (deviceName.toLowerCase().contains('drumly')) {
      return 'Drumly';
    }

    if (deviceName.toLowerCase().startsWith('bt')) {
      return deviceName.substring(
        0,
        deviceName.length > maxLength ? maxLength : deviceName.length,
      );
    }

    // İlk kelimeyi al
    final firstWord = deviceName.split(' ').first;
    if (firstWord.length <= maxLength) {
      return firstWord;
    }

    return deviceName.substring(0, maxLength);
  }
}
