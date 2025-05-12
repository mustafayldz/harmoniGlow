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
}
