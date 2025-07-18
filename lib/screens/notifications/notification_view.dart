import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/provider/notification_provider.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  @override
  void initState() {
    super.initState();
    // Removed automatic mark all as read - let user control this manually
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF0F172A), // Dark slate
                    const Color(0xFF1E293B), // Lighter slate
                    const Color(0xFF334155), // Even lighter
                  ]
                : [
                    const Color(0xFFF8FAFC), // Light gray
                    const Color(0xFFE2E8F0), // Slightly darker
                    const Color(0xFFCBD5E1), // Even darker
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(context, isDarkMode),

              // Content
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    final notifications = notificationProvider.notifications;

                    if (notifications.isEmpty) {
                      return _buildEmptyState(isDarkMode);
                    }

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Clear All Button
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${notifications.length}/${notificationProvider.maxNotificationLimit} ${'notificationsCount'.tr()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : Colors.black.withValues(alpha: 0.7),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _showClearAllDialog(
                                      context,
                                      notificationProvider,
                                    );
                                  },
                                  child: Text(
                                    'clearAll'.tr(),
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Info text about limit
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 8,
                            ),
                            child: Text(
                              'notificationLimit'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),

                        // Notifications List
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final notification = notifications[index];
                                return _buildNotificationCard(
                                  notification,
                                  isDarkMode,
                                  notificationProvider,
                                );
                              },
                              childCount: notifications.length,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, bool isDarkMode) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Text(
                    'notifications'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final unreadCount = notificationProvider.unreadCount;
                      if (unreadCount > 0) {
                        return Container(
                          margin: const EdgeInsets.only(left: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState(bool isDarkMode) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'noNotifications'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'allCaughtUp'.tr(),
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildNotificationCard(
    NotificationModel notification,
    bool isDarkMode,
    NotificationProvider provider,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: notification.isRead
                ? isDarkMode
                    ? [const Color(0xFF374151), const Color(0xFF4B5563)]
                    : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)]
                : [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: notification.isRead
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Colors.blue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.data['type']),
                      color: notification.isRead
                          ? (isDarkMode
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6))
                          : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: notification.isRead
                                ? (isDarkMode ? Colors.white : Colors.black)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 14,
                            color: notification.isRead
                                ? (isDarkMode
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black.withValues(alpha: 0.7))
                                : Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: notification.isRead
                                ? (isDarkMode
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5))
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: notification.isRead
                          ? (isDarkMode
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6))
                          : Colors.white,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'markRead':
                          provider.markAsRead(notification.id);
                          break;
                        case 'markUnread':
                          provider.markAsUnread(notification.id);
                          break;
                        case 'delete':
                          provider.removeNotification(notification.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        PopupMenuItem(
                          value: 'markRead',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mark_email_read_outlined,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text('markAsRead'.tr()),
                            ],
                          ),
                        ),
                      if (notification.isRead)
                        PopupMenuItem(
                          value: 'markUnread',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mark_email_unread_outlined,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text('markAsUnread'.tr()),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('delete'.tr()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'welcome':
        return Icons.celebration_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'reminder':
        return Icons.schedule_rounded;
      case 'update':
        return Icons.system_update_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'justNow'.tr();
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}${'minutesAgo'.tr()}';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}${'hoursAgo'.tr()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${'daysAgo'.tr()}';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('clearAllNotifications'.tr()),
        content: Text(
          'clearAllConfirmation'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('clearAll'.tr()),
          ),
        ],
      ),
    );
  }
}
