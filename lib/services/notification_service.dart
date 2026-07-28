import 'dart:convert';

import 'package:drumly/constants.dart';
import 'package:drumly/models/notification_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/material.dart';

class NotificationService {
  String get _baseUrl => ApiServiceUrl.endpoint('users/me/notifications');

  Future<NotificationPage?> getNotifications(
    BuildContext context, {
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
    final response = await RequestHelper.requestAsync(
      context,
      RequestType.get,
      uri.toString(),
    );
    if (response == null || response.isEmpty) return null;

    try {
      final decoded = json.decode(response) as Map<String, dynamic>;
      if (decoded['success'] != true || decoded['data'] is! List) return null;
      final meta = decoded['meta'] as Map<String, dynamic>?;
      return NotificationPage(
        notifications: (decoded['data'] as List<dynamic>)
            .map(
              (item) => NotificationModel.fromApi(
                item as Map<String, dynamic>,
              ),
            )
            .toList(),
        unreadCount: meta?['unread_count'] as int? ?? 0,
        page: _asInt(meta?['page'], fallback: page),
        totalPages: _asInt(meta?['total_pages'], fallback: 1),
        total: _asInt(meta?['total']),
      );
    } catch (_) {
      return null;
    }
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<bool> markAsRead(
    BuildContext context,
    String notificationId,
  ) =>
      _put(context, '$_baseUrl/$notificationId/read');

  Future<bool> markAllAsRead(BuildContext context) =>
      _put(context, '$_baseUrl/read-all');

  Future<bool> deleteNotification(
    BuildContext context,
    String notificationId,
  ) async {
    final response = await RequestHelper.requestAsync(
      context,
      RequestType.delete,
      '$_baseUrl/$notificationId',
    );
    if (response == null || response.isEmpty) return false;
    try {
      final decoded = json.decode(response);
      return decoded is Map<String, dynamic> && decoded['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _put(BuildContext context, String url) async {
    final response = await RequestHelper.requestAsync(
      context,
      RequestType.put,
      url,
      <String, dynamic>{},
    );
    if (response == null || response.isEmpty) return false;
    try {
      final decoded = json.decode(response);
      return decoded is Map<String, dynamic> && decoded['success'] == true;
    } catch (_) {
      return false;
    }
  }
}

class NotificationPage {
  const NotificationPage({
    required this.notifications,
    required this.unreadCount,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;
  final int page;
  final int totalPages;
  final int total;
}
