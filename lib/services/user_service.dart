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
    final String url = '${ApiServiceUrl.baseUrl}users/me';

    final response =
        await RequestHelper.requestAsync(context, RequestType.get, url);

    if (response != null) {
      try {
        final jsonResponse = json.decode(response);

        // API response'da data field'i var, onu kullanmaliyiz
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final userData = jsonResponse['data'];
          return UserModel.fromJson(userData);
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    } else {
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
      final Map<String, dynamic> userData = {
        'firebase_token': firebaseToken,
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
      };

      // PUT method kullan (users/me endpoint'i için)
      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put, // POST değil PUT kullan
        url,
        userData,
      );
      if (response != null && response.isNotEmpty) {
        try {
          final jsonResponse = json.decode(response);

          // API response yapısını kontrol et
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            return UserModel.fromJson(jsonResponse['data']);
          } else if (jsonResponse['data'] != null) {
            return UserModel.fromJson(jsonResponse['data']);
          } else if (jsonResponse is Map<String, dynamic> &&
              jsonResponse.containsKey('email')) {
            return UserModel.fromJson(jsonResponse);
          } else {
            return null;
          }
        } catch (parseError) {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      if (e is Exception) {}
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

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        tokenData,
      );

      if (response != null && response.isNotEmpty) {
        final jsonResponse = json.decode(response);
        if (jsonResponse['data'] != null) {
          return UserModel.fromJson(jsonResponse['data']);
        } else {
          return UserModel.fromJson(jsonResponse);
        }
      }
    } catch (e) {
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

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        tokenData,
      );

      if (response != null && response.isNotEmpty) {
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
      final result = await updateFCMToken(context, fcmToken: fcmToken);

      if (result != null) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
