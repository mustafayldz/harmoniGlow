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
    final String url = '${getBaseUrlUser()}me';

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response == null || response == '' || response.isEmpty) {
        return null;
      } else if (response.isNotEmpty && response != '') {
        return userModelFromJson(response);
      }
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
    return null;
  }

  /*----------------------------------------------------------------------
                  Create or Update User
----------------------------------------------------------------------*/
  Future<UserModel?> createOrUpdateUser(
    BuildContext context, {
    required String firebaseToken,
    String? name,
    String? email,
  }) async {
    final String url = getBaseUrlUser();

    try {
      final Map<String, dynamic> userData = {
        'firebase_token': firebaseToken,
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      debugPrint(
          '🔥 Creating/Updating user with token: ${firebaseToken.substring(0, 20)}...');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.post,
        url,
        userData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('✅ User created/updated successfully');
        return userModelFromJson(response);
      }
    } catch (e) {
      debugPrint('❌ Error in createOrUpdateUser: $e');
      return null;
    }
    return null;
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

      debugPrint('🔄 Updating Firebase token for user: $userId');

      final response = await RequestHelper.requestAsync(
        context,
        RequestType.put,
        url,
        tokenData,
      );

      if (response != null && response.isNotEmpty) {
        debugPrint('✅ Firebase token updated successfully');
        return userModelFromJson(response);
      }
    } catch (e) {
      debugPrint('❌ Error in updateFirebaseToken: $e');
      return null;
    }
    return null;
  }

  /*----------------------------------------------------------------------
                  Get All Users (Admin only)
----------------------------------------------------------------------*/
  Future<List<UserModel>?> getAllUsers(BuildContext context) async {
    final String url = getBaseUrlUser();

    try {
      final response =
          await RequestHelper.requestAsync(context, RequestType.get, url);

      if (response == null || response == '' || response.isEmpty) {
        return null;
      }

      final List<dynamic> jsonList = json.decode(response);
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error in getAllUsers: $e');
      return null;
    }
  }
}
