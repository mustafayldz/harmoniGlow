import 'package:flutter/material.dart';
import 'package:drumly/models/user_model.dart';

class UserProvider with ChangeNotifier {
  // User data
  UserModel? _userModel;

  // Getter for user data
  UserModel get user => _userModel!;

  // Setter for user data
  void setUser(UserModel user) {
    _userModel = user;
    notifyListeners();
  }

  void clearUser() {
    _userModel = null;
    notifyListeners();
  }
}
