// To parse this JSON data, do
//
//     final traningModel = traningModelFromJson(jsonString);

import 'dart:convert';

import 'package:drumly/models/notes_model.dart';

TraningModel traningModelFromJson(String str) =>
    TraningModel.fromJson(json.decode(str));

String traningModelToJson(TraningModel data) => json.encode(data.toJson());

class TraningModel {
  TraningModel({
    this.id,
    this.beatId, // Backward compatibility
    this.name,
    this.title, // Backward compatibility
    this.level,
    this.description,
    this.duration,
    this.durationSeconds, // Backward compatibility
    this.bpm,
    this.notes,
    this.rhythm,
    this.fileUrl, // Backward compatibility
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory TraningModel.fromJson(Map<String, dynamic> json) => TraningModel(
        // API field mappings
        id: json['id'] as String? ?? json['_id'] as String?,
        beatId: json['beat_id'] as String? ?? json['id'] as String?,
        name: json['name'] as String?,
        title: json['title'] as String? ?? json['name'] as String?,
        level: json['level'] as String?,
        description: json['description'] as String?,
        duration: json['duration'] as double?,
        durationSeconds: json['duration_seconds'] as int? ??
            (json['duration'] != null
                ? (json['duration'] as double).toInt()
                : null),
        bpm: json['bpm'] as int?,
        notes: json['notes'] == null
            ? []
            : List<NoteModel>.from(
                json['notes']!.map((x) => NoteModel.fromJson(x)),
              ),
        rhythm: json['rhythm'] as String?,
        fileUrl: json['file_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
        isActive: json['is_active'] as bool? ?? true,
      );

  // API fields
  String? id;
  String? name;
  String? level;
  String? description;
  double? duration;
  int? bpm;
  List<NoteModel>? notes;
  String? rhythm;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool isActive;

  // Backward compatibility fields
  String? beatId;
  String? title;
  int? durationSeconds;
  String? fileUrl;

  Map<String, dynamic> toJson() => {
        // API fields
        'id': id,
        'name': name,
        'level': level,
        'description': description,
        'duration': duration,
        'bpm': bpm,
        'notes': notes == null
            ? []
            : List<dynamic>.from(notes!.map((x) => x.toJson())),
        'rhythm': rhythm,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_active': isActive,

        // Backward compatibility fields
        '_id': id,
        'beat_id': beatId ?? id,
        'title': title ?? name,
        'duration_seconds': durationSeconds ?? duration?.toInt(),
        'file_url': fileUrl,
      };
}
