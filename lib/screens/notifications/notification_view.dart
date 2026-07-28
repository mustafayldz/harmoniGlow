import 'package:drumly/models/notification_model.dart';
import 'package:drumly/provider/notification_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().syncNotifications(context);
      }
    });
  }

  Future<void> _refresh() =>
      context.read<NotificationProvider>().syncNotifications(context);

  Future<void> _markAllAsRead(NotificationProvider provider) async {
    final success = await provider.markAllAsRead(context);
    if (!mounted || success) return;
    _showMessage('notification_action_failed'.tr());
  }

  Future<void> _openNotification(
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    if (!notification.isRead) {
      final success = await provider.markAsRead(context, notification.id);
      if (!mounted) return;
      if (!success) {
        _showMessage('notification_action_failed'.tr());
        return;
      }
    }

    if (!mounted) return;
    final action = notification.data['action']?.toString().toUpperCase();
    final entityType =
        notification.data['entity_type']?.toString().toLowerCase();

    if (action == 'OPEN_SONG' || entityType == 'song') {
      await Navigator.pushNamed(
        context,
        '/songs',
        arguments: notification.data['entity_id'],
      );
    } else if (action == 'OPEN_SONG_REQUEST') {
      await Navigator.pushNamed(context, '/song-request');
    } else if (action == 'OPEN_HOME' || action == 'OPEN_ANNOUNCEMENT') {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteNotification(
    NotificationModel notification,
    NotificationProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_notification'.tr()),
        content: Text('delete_notification_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await provider.removeNotification(context, notification.id);
    if (!mounted || success) return;
    _showMessage('notification_action_failed'.tr());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF070A10) : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) => Column(
            children: [
              _NotificationAppBar(
                isDark: isDark,
                isRefreshing: provider.isSyncing,
                onRefresh: _refresh,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFF6C5CE7),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        sliver: SliverToBoxAdapter(
                          child: _InboxSummary(
                            isDark: isDark,
                            totalCount: provider.notificationCount,
                            unreadCount: provider.unreadCount,
                            onMarkAll: provider.hasUnreadNotifications
                                ? () => _markAllAsRead(provider)
                                : null,
                          ),
                        ),
                      ),
                      if (provider.syncError != null &&
                          provider.notifications.isNotEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          sliver: SliverToBoxAdapter(
                            child: _ErrorBanner(onRetry: _refresh),
                          ),
                        ),
                      if (provider.notifications.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: provider.isSyncing
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _EmptyNotifications(
                                  isDark: isDark,
                                  hasError: provider.syncError != null,
                                  onRetry: _refresh,
                                ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                          sliver: SliverList.separated(
                            itemCount: provider.notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final notification =
                                  provider.notifications[index];
                              return _NotificationCard(
                                key: ValueKey(notification.id),
                                notification: notification,
                                isDark: isDark,
                                timestamp: _formatTimestamp(
                                  notification.timestamp,
                                ),
                                onTap: () =>
                                    _openNotification(notification, provider),
                                onDelete: () =>
                                    _deleteNotification(notification, provider),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.isNegative || difference.inMinutes < 1) {
      return 'justNow'.tr();
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}${'minutesAgo'.tr()}';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}${'hoursAgo'.tr()}';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}${'daysAgo'.tr()}';
    }
    return DateFormat('MMM d, yyyy • HH:mm').format(timestamp);
  }
}

class _NotificationAppBar extends StatelessWidget {
  const _NotificationAppBar({
    required this.isDark,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isDark;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            _TopButton(
              icon: Icons.arrow_back_ios_new_rounded,
              isDark: isDark,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'notifications'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF171923),
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'notification_inbox_subtitle'.tr(),
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF727481),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _TopButton(
              icon: Icons.refresh_rounded,
              isDark: isDark,
              onTap: isRefreshing ? null : onRefresh,
              isLoading: isRefreshing,
            ),
          ],
        ),
      );
}

class _TopButton extends StatelessWidget {
  const _TopButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Material(
        color: isDark ? const Color(0xFF151923) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 44,
            child: Center(
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      icon,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF252733),
                    ),
            ),
          ),
        ),
      );
}

class _InboxSummary extends StatelessWidget {
  const _InboxSummary({
    required this.isDark,
    required this.totalCount,
    required this.unreadCount,
    required this.onMarkAll,
  });

  final bool isDark;
  final int totalCount;
  final int unreadCount;
  final VoidCallback? onMarkAll;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF25203F), Color(0xFF151A2C)]
                : const [Color(0xFF6C5CE7), Color(0xFF4F46C8)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unreadCount ${'unread_notifications'.tr()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$totalCount ${'notificationsCount'.tr()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onMarkAll != null)
              TextButton(
                onPressed: onMarkAll,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
                child: Text(
                  'markAllAsRead'.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.timestamp,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final NotificationModel notification;
  final bool isDark;
  final String timestamp;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final foreground = isDark ? Colors.white : const Color(0xFF20222D);
    final type = notification.data['type']?.toString();

    return Material(
      color: unread
          ? (isDark ? const Color(0xFF19182A) : const Color(0xFFF1EFFF))
          : (isDark ? const Color(0xFF12161E) : Colors.white),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread
                  ? const Color(0xFF6C5CE7).withValues(alpha: 0.28)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7)
                      .withValues(alpha: unread ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _notificationIcon(type),
                  color: const Color(0xFF8B7CF6),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              height: 1.2,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C5CE7),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.58)
                            : const Color(0xFF686A76),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : const Color(0xFF9A9CAA),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timestamp,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.38)
                                : const Color(0xFF8C8E99),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'delete'.tr(),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.38)
                    : const Color(0xFF9A9CAA),
                iconSize: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _notificationIcon(String? type) {
    switch (type) {
      case 'USER_REGISTERED':
        return Icons.celebration_rounded;
      case 'REQUESTED_SONG_PUBLISHED':
      case 'SONG_PUBLISHED':
        return Icons.library_music_rounded;
      case 'ANNOUNCEMENT_PUBLISHED':
        return Icons.campaign_rounded;
      case 'ACHIEVEMENT_UNLOCKED':
        return Icons.emoji_events_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 10),
            Expanded(child: Text('notifications_load_failed'.tr())),
            TextButton(onPressed: onRetry, child: Text('refresh'.tr())),
          ],
        ),
      );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({
    required this.isDark,
    required this.hasError,
    required this.onRetry,
  });

  final bool isDark;
  final bool hasError;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                hasError
                    ? Icons.cloud_off_rounded
                    : Icons.notifications_none_rounded,
                color: const Color(0xFF6C5CE7),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasError
                  ? 'notifications_load_failed'.tr()
                  : 'noNotifications'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF20222D),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasError ? 'pull_to_retry'.tr() : 'allCaughtUp'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF777985),
                height: 1.4,
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('refresh'.tr()),
              ),
            ],
          ],
        ),
      );
}
