import 'dart:convert';
import 'package:drumly/constants.dart';
import 'package:drumly/models/user_model.dart';
import 'package:drumly/shared/enums.dart';
import 'package:drumly/shared/request_helper.dart';
import 'package:flutter/material.dart';

class UserService {
  String getBaseUrlUser() => ApiServiceUrl.user;

  /*----------------------------------------------------------------------
                  Get User
----------------------------------------------------------------------*/
  Future<UserModel?> getUser(BuildContext context) async {
    debugPrint('UserService.getUser called');

    final String url = '${ApiServiceUrl.baseUrl}users/me';
    debugPrint('Making request to: $url');

    final response =
        await RequestHelper.requestAsync(context, RequestType.get, url);

    if (response != null) {
      try {
        final jsonResponse = json.decode(response);
        debugPrint('Full response: $jsonResponse');

        // API response'da data field'i var, onu kullanmaliyiz
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final userData = jsonResponse['data'];
          debugPrint('UserService.getUser successful');
          return UserModel.fromJson(userData);
        } else {
          debugPrint(
            'UserService.getUser API returned success=false or no data',
          );
          return null;
        }
      } catch (e) {
        debugPrint('UserService.getUser parse error: $e');
        return null;
      }
    } else {
      debugPrint('UserService.getUser response is null');
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Create or Update User
----------------------------------------------------------------------*/
  Future<UserModel?> createOrUpdateUser(
    BuildContext context, {
    required String firebaseToken,
    String? name,
    String? email,
    String? fcmToken,
  }) async {
    final String url = getBaseUrlUser();

    try {
      final Map<String, dynamic> userData = {
        'firebase_token': firebaseToken,
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      };

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.post, // POST metodu kullaniyoruz
        url,
        userData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('User created/updated successfully');
        return userModelFromJson(response);
      } else {
        debugPrint('Empty or null response from backend');
        return null;
      }
    } catch (e) {
      debugPrint('Error in createOrUpdateUser: $e');
      debugPrint('Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('Exception details: ${e.toString()}');
      }
      return null;
    }
  }

  /*----------------------------------------------------------------------
                  Update Firebase Token Only
----------------------------------------------------------------------*/
  Future<UserModel?> updateFirebaseToken(
    BuildContext context, {
    required String userId,
    required String firebaseToken,
  }) async {
    final String url = '${getBaseUrlUser()}$userId/token';

    try {
      final Map<String, dynamic> tokenData = {
        'firebase_token': firebaseToken,
      };

      debugPrint('Updating Firebase token for user: $userId');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        tokenData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('Firebase token updated successfully');
        return userModelFromJson(response);
      }
    } catch (e) {
      debugPrint('Error in updateFirebaseToken: $e');
      return null;
    }
    return null;
  }

  /*----------------------------------------------------------------------
                  Update FCM Token Only
----------------------------------------------------------------------*/
  Future<UserModel?> updateFCMToken(
    BuildContext context, {
    required String fcmToken,
  }) async {
    final String url = '${getBaseUrlUser()}me/fcm-token';

    try {
      final Map<String, dynamic> tokenData = {
        'fcm_token': fcmToken,
      };

      debugPrint('Updating FCM token via: $url');
      debugPrint('FCM Token: ${fcmToken.substring(0, 20)}...');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        tokenData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('FCM token updated successfully');
        return userModelFromJson(response);
      }
    } catch (e) {
      debugPrint('Error in updateFCMToken: $e');
      return null;
    }
    return null;
  }
}
