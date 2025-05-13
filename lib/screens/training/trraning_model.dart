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
    this.beatId,
    this.bpm,
    this.durationSeconds,
    this.fileUrl,
    this.genre,
    this.notes,
    this.rhythm,
    this.title,
  });

  factory TraningModel.fromJson(Map<String, dynamic> json) => TraningModel(
        id: json['_id'],
        beatId: json['beat_id'],
        bpm: json['bpm'],
        durationSeconds: json['duration_seconds'],
        fileUrl: json['file_url'],
        genre: json['genre'],
        notes: json['notes'] == null
            ? []
            : List<NoteModel>.from(
                json['notes']!.map((x) => NoteModel.fromJson(x)),
              ),
        rhythm: json['rhythm'],
        title: json['title'],
      );
  String? id;
  String? beatId;
  int? bpm;
  int? durationSeconds;
  String? fileUrl;
  String? genre;
  List<NoteModel>? notes;
  String? rhythm;
  String? title;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'beat_id': beatId,
        'bpm': bpm,
        'duration_seconds': durationSeconds,
        'file_url': fileUrl,
        'genre': genre,
        'notes': notes == null
            ? []
            : List<dynamic>.from(notes!.map((x) => x.toJson())),
        'rhythm': rhythm,
        'title': title,
      };
}
