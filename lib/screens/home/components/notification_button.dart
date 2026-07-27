import 'package:drumly/screens/notifications/notification_view.dart';
import 'package:drumly/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({
    required this.isDarkMode,
    required this.isSmallScreen,
    super.key,
  });
  final bool isDarkMode;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationView(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
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
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) => Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.84)
                          : const Color(0xFF252733),
                      size: 21,
                    ),
                    if (notificationProvider.hasUnreadNotifications)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDarkMode
                                  ? const Color(0xFF12151C)
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: isSmallScreen ? 15 : 17,
                            minHeight: isSmallScreen ? 15 : 17,
                          ),
                          child: Text(
                            notificationProvider.unreadCount > 99
                                ? '99+'
                                : notificationProvider.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
