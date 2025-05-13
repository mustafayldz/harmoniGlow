import 'dart:convert';

import 'package:drumly/models/notes_model.dart';

SongModel songModelNewFromJson(String str) =>
    SongModel.fromJson(json.decode(str));

String songModelNewToJson(SongModel data) => json.encode(data.toJson());

class SongModel {
  SongModel({
    this.songId,
    this.title,
    this.artist,
    this.durationSeconds,
    this.fileUrl,
    this.notes,
    this.rhythm,
    this.bpm,
    this.songtypeId,
    this.isLocked = false,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
        songId: json['song_id'] as String?,
        title: json['title'] as String?,
        artist: json['artist'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
        fileUrl: json['file_url'] as String?,
        notes: json['notes'] == null
            ? []
            : (json['notes'] as List<dynamic>)
                .map((n) => NoteModel.fromJson(n as Map<String, dynamic>))
                .toList(),
        rhythm: json['rhythm'] as String?,
        bpm: json['bpm'] as int?,
        songtypeId: json['songtype_id'] as int?,
        isLocked: json['is_locked'] as bool? ?? false,
      );

  String? songId;
  String? title;
  String? artist;
  int? durationSeconds;
  String? fileUrl;
  List<NoteModel>? notes;
  String? rhythm;
  int? bpm;
  int? songtypeId;
  bool isLocked;

  Map<String, dynamic> toJson() => {
        'song_id': songId,
        'title': title,
        'artist': artist,
        'duration_seconds': durationSeconds,
        'file_url': fileUrl,
        'notes': notes == null ? [] : notes!.map((n) => n.toJson()).toList(),
        'rhythm': rhythm,
        'bpm': bpm,
        'songtype_id': songtypeId,
        'is_locked': isLocked,
      };
}
