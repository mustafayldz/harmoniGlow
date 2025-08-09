import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/home/components/bluetooth_banner.dart';
import 'package:drumly/screens/home/components/notification_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModernAppBar extends StatelessWidget {
  const ModernAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;
    final deviceName = state.connectedDevice?.advName ?? 'Unknown Device';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20,
        20,
        isSmallScreen ? 16 : 20,
        isSmallScreen ? 16 : 20,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: isSmallScreen ? 2 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF34D399)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Drumly',
                        style: TextStyle(
                          fontSize:
                              isSmallScreen ? 24 : (isMediumScreen ? 28 : 32),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (!isSmallScreen) ...[
                      const SizedBox(height: 2),
                      Text(
                        'followTheBeat'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                flex: isSmallScreen ? 1 : 2,
                child: BluetoothBanner(
                  isConnected: isConnected,
                  deviceName: deviceName,
                  isDarkMode: isDarkMode,
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                ),
              ),
              NotificationButton(
                isDarkMode: isDarkMode,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
