// To parse this JSON data, do
//
//     final songRequestModel = songRequestModelFromJson(jsonString);

import 'dart:convert';

SongRequestModel songRequestModelFromJson(String str) =>
    SongRequestModel.fromJson(json.decode(str));

String songRequestModelToJson(SongRequestModel data) =>
    json.encode(data.toJson());

class SongRequestModel {
  SongRequestModel({
    required this.artistName,
    required this.songTitle,
    this.requestId,
    this.userId,
    this.userEmail,
    this.userName,
    this.songLink,
    this.albumName,
    this.genre,
    this.releaseYear,
    this.language,
    this.description,
    this.status = 'pending',
    this.priority = 'normal',
    this.createdAt,
  });

  factory SongRequestModel.fromJson(Map<String, dynamic> json) =>
      SongRequestModel(
        requestId: json['request_id'],
        userId: json['user_id'],
        userEmail: json['user_email'],
        userName: json['user_name'],
        artistName: json['artist_name'] ?? '',
        songTitle: json['song_title'] ?? '',
        songLink: json['song_link'],
        albumName: json['album_name'],
        genre: json['genre'],
        releaseYear: json['release_year'],
        language: json['language'],
        description: json['description'],
        status: json['status'] ?? 'pending',
        priority: json['priority'] ?? 'normal',
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at']),
      );

  String? requestId;
  String? userId;
  String? userEmail;
  String? userName;
  String artistName;
  String songTitle;
  String? songLink;
  String? albumName;
  String? genre;
  int? releaseYear;
  String? language;
  String? description;
  String status; // pending, approved, rejected
  String priority; // low, normal, high
  DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'user_id': userId,
        'user_email': userEmail,
        'user_name': userName,
        'artist_name': artistName,
        'song_title': songTitle,
        'song_link': songLink,
        'album_name': albumName,
        'genre': genre,
        'release_year': releaseYear,
        'language': language,
        'description': description,
        'status': status,
        'priority': priority,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Copy with method for easier updates
  SongRequestModel copyWith({
    String? requestId,
    String? userId,
    String? userEmail,
    String? userName,
    String? artistName,
    String? songTitle,
    String? songLink,
    String? albumName,
    String? genre,
    int? releaseYear,
    String? language,
    String? description,
    String? status,
    String? priority,
    DateTime? createdAt,
  }) =>
      SongRequestModel(
        requestId: requestId ?? this.requestId,
        userId: userId ?? this.userId,
        userEmail: userEmail ?? this.userEmail,
        userName: userName ?? this.userName,
        artistName: artistName ?? this.artistName,
        songTitle: songTitle ?? this.songTitle,
        songLink: songLink ?? this.songLink,
        albumName: albumName ?? this.albumName,
        genre: genre ?? this.genre,
        releaseYear: releaseYear ?? this.releaseYear,
        language: language ?? this.language,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        createdAt: createdAt ?? this.createdAt,
      );
}
