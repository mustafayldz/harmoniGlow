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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 16 : 20,
        18,
        isSmallScreen ? 16 : 20,
        8,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drumly',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'followTheBeat'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.46),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          BluetoothBanner(
            isConnected: isConnected,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(width: 8),
          NotificationButton(
            isDarkMode: isDarkMode,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }
}
