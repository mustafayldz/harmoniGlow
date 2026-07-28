import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drumly/constants.dart';
import 'package:drumly/models/user_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const _notificationDeviceIdKey = 'notification_device_id';

  Future<UserModel?> getUser(BuildContext context) async {
    final response = await RequestHelper.requestAsync(
      context,
      RequestType.get,
      ApiServiceUrl.endpoint('users/me'),
    );
    return _parseUser(response);
  }

  /// `GET /users/me` creates a missing profile in drumly-core. Profile updates
  /// now accept only the user's display name.
  Future<UserModel?> createOrUpdateUser(
    BuildContext context, {
    required String firebaseToken,
    String? name,
    String? email,
    String? fcmToken,
  }) async {
    await StorageService.saveFirebaseToken(firebaseToken);

    var user = await getUser(context);
    if (user == null) return null;

    if (name != null && name.isNotEmpty && name != user.name) {
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        ApiServiceUrl.endpoint('users/me'),
        {'name': name},
      );
      user = _parseUser(response) ?? user;
    }

    if (fcmToken != null && fcmToken.isNotEmpty) {
      await updateFCMToken(context, fcmToken: fcmToken);
    }
    return user;
  }

  /// Firebase ID tokens are authentication credentials and are no longer
  /// persisted in the user document.
  Future<UserModel?> updateFirebaseToken(
    BuildContext context, {
    required String userId,
    required String firebaseToken,
  }) async {
    await StorageService.saveFirebaseToken(firebaseToken);
    return getUser(context);
  }

  /// Register or refresh this installation through the notification-device
  /// upsert endpoint.
  Future<bool> updateFCMToken(
    BuildContext context, {
    required String fcmToken,
  }) async {
    if (fcmToken.isEmpty) return false;

    final packageInfo = await PackageInfo.fromPlatform();
    final locale = EasyLocalization.of(context)?.locale.languageCode ?? 'en';
    final response = await RequestHelper.requestAsync(
      context,
      RequestType.post,
      ApiServiceUrl.endpoint('users/me/notification-devices'),
      {
        'device_id': await _getOrCreateNotificationDeviceId(),
        'fcm_token': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'app_version': packageInfo.version,
        'language': locale,
        'timezone': await _getLocalTimezone(),
      },
    );

    if (response == null || response.isEmpty) {
      debugPrint('notification-device response: empty');
      return false;
    }
    try {
      final decoded = json.decode(response);
      final success =
          decoded is Map<String, dynamic> && decoded['success'] == true;
      debugPrint('notification-device response success: $success');
      return success;
    } catch (error) {
      debugPrint('notification-device response parse error: $error');
      return false;
    }
  }

  Future<bool> sendFCMTokenToServer(
    BuildContext context, {
    required String fcmToken,
  }) =>
      updateFCMToken(context, fcmToken: fcmToken);

  UserModel? _parseUser(String? response) {
    if (response == null || response.isEmpty) return null;
    try {
      final decoded = json.decode(response);
      if (decoded is Map<String, dynamic> &&
          decoded['success'] == true &&
          decoded['data'] is Map<String, dynamic>) {
        return UserModel.fromJson(decoded['data'] as Map<String, dynamic>);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<String> _getOrCreateNotificationDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_notificationDeviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final suffix = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final deviceId = 'mobile-${DateTime.now().microsecondsSinceEpoch}-$suffix';
    await preferences.setString(_notificationDeviceIdKey, deviceId);
    return deviceId;
  }

  Future<String> _getLocalTimezone() async {
    try {
      return (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (error) {
      debugPrint('Timezone lookup failed, using platform fallback: $error');
      return DateTime.now().timeZoneName;
    }
  }
}
