import 'dart:convert';

SongModel songModelNewFromJson(String str) =>
    SongModel.fromJson(json.decode(str));

String songModelNewToJson(SongModel data) => json.encode(data.toJson());

class NoteModel {
  NoteModel({
    required this.i,
    required this.sM,
    required this.eM,
    required this.led,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        i: json['i'] as int,
        sM: json['sM'] as int,
        eM: json['eM'] as int,
        led:
            List<int>.from((json['led'] as List<dynamic>).map((n) => n as int)),
      );
  final int i;
  final int sM;
  final int eM;
  final List<int> led;

  Map<String, dynamic> toJson() => {
        'i': i,
        'sM': sM,
        'eM': eM,
        'led': led,
      };
}

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
    this.genre,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
        songId: json['songId'] as int?,
        title: json['title'] as String?,
        artist: json['artist'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        fileUrl: json['fileUrl'] as String?,
        notes: json['notes'] == null
            ? []
            : (json['notes'] as List<dynamic>)
                .map((n) => NoteModel.fromJson(n as Map<String, dynamic>))
                .toList(),
        rhythm: json['rhythm'] as String?,
        bpm: json['bpm'] as int?,
        songtypeId: json['songtypeId'] as int?,
        genre: json['genre'] as String?,
      );

  int? songId;
  String? title;
  String? artist;
  int? durationSeconds;
  String? fileUrl;
  List<NoteModel>? notes;
  String? rhythm;
  int? bpm;
  int? songtypeId;
  String? genre;

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'title': title,
        'artist': artist,
        'durationSeconds': durationSeconds,
        'fileUrl': fileUrl,
        'notes': notes == null ? [] : notes!.map((n) => n.toJson()).toList(),
        'rhythm': rhythm,
        'bpm': bpm,
        'songtypeId': songtypeId,
        'genre': genre,
      };
}
