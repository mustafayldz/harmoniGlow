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
                  Create or Update User - DÜZELTME
----------------------------------------------------------------------*/
  Future<UserModel?> createOrUpdateUser(
    BuildContext context, {
    required String firebaseToken,
    String? name,
    String? email,
    String? fcmToken,
  }) async {
    // DOĞRU ENDPOINT: /users/me kullan (405 hatasını önlemek için)
    final String url = '${ApiServiceUrl.baseUrl}users/me';

    try {
      debugPrint('🔄 createOrUpdateUser called');
      debugPrint('📧 Email: $email');
      debugPrint('👤 Name: $name');
      debugPrint(
        '🔔 FCM Token: ${fcmToken?.isNotEmpty == true ? "Mevcut (${fcmToken?.substring(0, 20)}...)" : "Yok"}',
      );
      debugPrint('🔥 Firebase Token: ${firebaseToken.substring(0, 20)}...');
      debugPrint('🌐 URL: $url');

      final Map<String, dynamic> userData = {
        'firebase_token': firebaseToken,
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      };

      debugPrint('📤 Request data: ${jsonEncode(userData)}');

      // PUT method kullan (users/me endpoint'i için)
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put, // POST değil PUT kullan
        url,
        userData,
      );

      debugPrint(
        '📥 Response received: ${response?.isNotEmpty == true ? "Data var" : "Boş"}',
      );

      if (response != null && response.isNotEmpty) {
        try {
          final jsonResponse = json.decode(response);
          debugPrint('📥 Response parsed: $jsonResponse');

          // API response yapısını kontrol et
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            debugPrint(
              '✅ User created/updated successfully via API success response',
            );
            return UserModel.fromJson(jsonResponse['data']);
          } else if (jsonResponse['data'] != null) {
            debugPrint('✅ User created/updated successfully via data field');
            return UserModel.fromJson(jsonResponse['data']);
          } else if (jsonResponse is Map<String, dynamic> &&
              jsonResponse.containsKey('email')) {
            debugPrint(
              '✅ User created/updated successfully via direct response',
            );
            return UserModel.fromJson(jsonResponse);
          } else {
            debugPrint('⚠️ Unexpected response structure: $jsonResponse');
            return null;
          }
        } catch (parseError) {
          debugPrint('❌ JSON parse error: $parseError');
          debugPrint('❌ Raw response: $response');
          return null;
        }
      } else {
        debugPrint('❌ Empty or null response from backend');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error in createOrUpdateUser: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      if (e is Exception) {
        debugPrint('❌ Exception details: ${e.toString()}');
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
    final String url = '${ApiServiceUrl.baseUrl}users/me/firebase-token';

    try {
      final Map<String, dynamic> tokenData = {
        'firebase_token': firebaseToken,
      };

      debugPrint('🔄 Updating Firebase token for user: $userId');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        tokenData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('✅ Firebase token updated successfully');
        final jsonResponse = json.decode(response);
        if (jsonResponse['data'] != null) {
          return UserModel.fromJson(jsonResponse['data']);
        } else {
          return UserModel.fromJson(jsonResponse);
        }
      }
    } catch (e) {
      debugPrint('❌ Error in updateFirebaseToken: $e');
      return null;
    }
    return null;
  }

  /*----------------------------------------------------------------------
                  Update FCM Token Only - DÜZELTME
----------------------------------------------------------------------*/
  Future<UserModel?> updateFCMToken(
    BuildContext context, {
    required String fcmToken,
  }) async {
    final String url = '${ApiServiceUrl.baseUrl}users/me/fcm-token';

    try {
      final Map<String, dynamic> tokenData = {
        'fcm_token': fcmToken,
      };

      debugPrint('🔄 Updating FCM token via: $url');
      debugPrint('🔔 FCM Token: ${fcmToken.substring(0, 20)}...');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        tokenData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('✅ FCM token updated successfully');
        final jsonResponse = json.decode(response);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return UserModel.fromJson(jsonResponse['data']);
        } else if (jsonResponse['data'] != null) {
          return UserModel.fromJson(jsonResponse['data']);
        } else {
          return UserModel.fromJson(jsonResponse);
        }
      }
    } catch (e) {
      debugPrint('❌ Error in updateFCMToken: $e');
      return null;
    }
    return null;
  }

  /*----------------------------------------------------------------------
                  Separate FCM Token Update (Alternative)
----------------------------------------------------------------------*/
  Future<bool> sendFCMTokenToServer(
    BuildContext context, {
    required String fcmToken,
  }) async {
    try {
      debugPrint('🔔 Sending FCM token to server...');
      debugPrint('🔔 Token: ${fcmToken.substring(0, 20)}...');

      final result = await updateFCMToken(context, fcmToken: fcmToken);

      if (result != null) {
        debugPrint('✅ FCM token successfully sent to server');
        debugPrint(
          '✅ Updated user FCM token: ${result.fcmToken?.substring(0, 20) ?? "null"}...',
        );
        return true;
      } else {
        debugPrint('❌ Failed to send FCM token to server');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM token: $e');
      return false;
    }
  }
}
