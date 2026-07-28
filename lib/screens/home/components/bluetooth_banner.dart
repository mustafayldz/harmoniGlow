import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:flutter/material.dart';

class BluetoothBanner extends StatelessWidget {
  const BluetoothBanner({
    required this.isConnected,
    required this.isDarkMode,
    super.key,
  });
  final bool isConnected;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FindDevicesView()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isConnected
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_rounded,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.84)
                      : const Color(0xFF252733),
                  size: 20,
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF3ED598)
                          : const Color(0xFF9A9CAA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDarkMode ? const Color(0xFF12151C) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
