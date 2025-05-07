import 'dart:convert';

import 'package:drumly/models/device_model.dart';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  UserModel({
    this.userId,
    this.email,
    this.name,
    this.createdAt,
    this.lastLogin,
    this.devices,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['user_id'],
        email: json['email'],
        name: json['name'],
        createdAt: json['created_at'],
        lastLogin: json['last_login'],
        devices: json['devices'] == null
            ? []
            : List<DeviceModel>.from(
                json['devices']!.map((x) => DeviceModel.fromJson(x)),
              ),
      );
  String? userId;
  String? email;
  String? name;
  int? createdAt;
  int? lastLogin;
  List<DeviceModel>? devices;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'name': name,
        'created_at': createdAt,
        'last_login': lastLogin,
        'devices': devices == null
            ? []
            : List<dynamic>.from(devices!.map((x) => x.toJson())),
      };
}
