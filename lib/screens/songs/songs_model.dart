import 'dart:convert';

import 'package:drumly/models/notes_model.dart';

SongModel songModelNewFromJson(String str) =>
    SongModel.fromJson(json.decode(str));

String songModelNewToJson(SongModel data) => json.encode(data.toJson());

class SongModel {
  SongModel({
    this.id,
    this.songId, // Backward compatibility
    this.name,
    this.title, // Backward compatibility
    this.artist,
    this.userId,
    this.songTypeId,
    this.songtypeId, // Backward compatibility
    this.description,
    this.duration,
    this.durationSeconds, // Backward compatibility
    this.bpm,
    this.notes,
    this.rhythm,
    this.fileUrl,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.isLocked = false,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
        id: json['song_id'] as String?, // API'dan song_id'yi al
        songId: json['song_id'] as String?, // Backward compatibility
        name: json['name'] as String?,
        title: json['title'] as String?,
        artist: json['artist'] as String?,
        userId: json['user_id'] as String?,
        songTypeId: json['song_type_id'] as String?,
        songtypeId: json['songtype_id'] as int?, // Backward compatibility
        description: json['description'] as String?,
        duration: json['duration'] as double?,
        durationSeconds: json['duration_seconds'] as int? ??
            (json['duration'] != null
                ? (json['duration'] as double).toInt()
                : null),
        bpm: json['bpm'] as int?,
        notes: json['notes'] == null
            ? []
            : (json['notes'] as List<dynamic>)
                .map((n) => NoteModel.fromJson(n as Map<String, dynamic>))
                .toList(),
        rhythm: json['rhythm'] as String?,
        fileUrl: json['file_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
        isLocked: json['is_locked'] as bool? ?? false,
      );

  // API fields
  String? id;
  String? name;
  String? userId;
  String? songTypeId;
  String? description;
  double? duration;
  int? bpm;
  List<NoteModel>? notes;
  String? rhythm;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isActive;

  // Backward compatibility fields
  String? songId;
  String? title;
  String? artist;
  int? durationSeconds;
  String? fileUrl;
  int? songtypeId;
  bool isLocked;

  Map<String, dynamic> toJson() => {
        // API fields
        'id': id,
        'name': name,
        'user_id': userId,
        'song_type_id': songTypeId,
        'description': description,
        'duration': duration,
        'bpm': bpm,
        'notes': notes == null ? [] : notes!.map((n) => n.toJson()).toList(),
        'rhythm': rhythm,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_active': isActive,

        // Backward compatibility fields
        'song_id': songId ?? id,
        'title': title ?? name,
        'artist': artist,
        'duration_seconds': durationSeconds ?? duration?.toInt(),
        'file_url': fileUrl,
        'songtype_id': songtypeId,
        'is_locked': isLocked,
      };
}
