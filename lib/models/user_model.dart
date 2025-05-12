// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

import 'package:drumly/models/device_model.dart';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  UserModel({
    this.id,
    this.assignedSongIds,
    this.createdAt,
    this.devices,
    this.email,
    this.lastLogin,
    this.name,
    this.userId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'],
        assignedSongIds: json['assigned_song_ids'] == null
            ? []
            : List<dynamic>.from(json['assigned_song_ids']!.map((x) => x)),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at']),
        devices: json['devices'] == null
            ? []
            : List<DeviceModel>.from(
                json['devices']!.map((x) => DeviceModel.fromJson(x)),
              ),
        email: json['email'],
        lastLogin: json['last_login'] == null
            ? null
            : DateTime.parse(json['last_login']),
        name: json['name'],
        userId: json['user_id'],
      );
  String? id;
  List<dynamic>? assignedSongIds;
  DateTime? createdAt;
  List<DeviceModel>? devices;
  String? email;
  DateTime? lastLogin;
  String? name;
  String? userId;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'assigned_song_ids': assignedSongIds == null
            ? []
            : List<dynamic>.from(assignedSongIds!.map((x) => x)),
        'created_at': createdAt?.toIso8601String(),
        'devices': devices == null
            ? []
            : List<dynamic>.from(devices!.map((x) => x.toJson())),
        'email': email,
        'last_login': lastLogin?.toIso8601String(),
        'name': name,
        'user_id': userId,
      };
}
