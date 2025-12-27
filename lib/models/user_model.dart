import 'package:drumly/models/device_model.dart';
import 'package:flutter/material.dart';

class UserModel {
  UserModel({
    required this.userId,
    required this.email,
    required this.name,
    required this.createdAt,
    required this.lastLogin,
    required this.assignedSongIds,
    required this.devices,
    this.id,
    this.firebaseToken,
    this.fcmToken,
    this.language = 'english',
    this.score = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint('🔍 UserModel.fromJson received: $json');

    return UserModel(
      id: json['_id'] ?? json['id'],
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      firebaseToken: json['firebase_token'],
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] ?? '',
      lastLogin: json['last_login'] ?? '',
      assignedSongIds: List<String>.from(json['assigned_song_ids'] ?? []),
      devices: (json['devices'] as List<dynamic>?)
              ?.map((device) => DeviceModel.fromJson(device))
              .toList() ??
          [],
      language: json['language'] ?? 'english',
      score: json['score'] ?? 0,
    );
  }
  final String? id;
  final String userId;
  final String email;
  final String name;
  final String? firebaseToken;
  final String? fcmToken;
  final String createdAt;
  final String lastLogin;
  final List<String> assignedSongIds;
  final List<DeviceModel> devices;
  final String language;
  final int score;

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'user_id': userId,
        'email': email,
        'name': name,
        if (firebaseToken != null) 'firebase_token': firebaseToken,
        if (fcmToken != null) 'fcm_token': fcmToken,
        'created_at': createdAt,
        'last_login': lastLogin,
        'assigned_song_ids': assignedSongIds,
        'devices': devices.map((device) => device.toJson()).toList(),
        'language': language,
        'score': score,
      };
}
