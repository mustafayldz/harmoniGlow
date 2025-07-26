import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final maxWidth = isSmallScreen ? 100.0 : (isMediumScreen ? 120.0 : 140.0);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        minWidth: 80,
      ),
      child: GestureDetector(
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FindDevicesView()),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isSmallScreen ? 36 : 40,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isConnected
                  ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.green : Colors.red)
                    .withValues(alpha: 0.2),
                blurRadius: isSmallScreen ? 3 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected
                    ? Icons.bluetooth_connected_rounded
                    : Icons.bluetooth_disabled_rounded,
                color: Colors.white,
                size: isSmallScreen ? 14 : 16,
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isConnected
                        ? _getDeviceDisplayName(deviceName, isSmallScreen)
                        : 'Off',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 10 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: isConnected ? 4 : 0,
                        spreadRadius: isConnected ? 1 : 0,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getDeviceDisplayName(String deviceName, bool isSmallScreen) {
    if (deviceName.isEmpty) return 'Connected';

    final maxLength = isSmallScreen ? 4 : 8;
    if (deviceName.length <= maxLength) return deviceName;

    return '${deviceName.substring(0, maxLength)}...';
  }
}
