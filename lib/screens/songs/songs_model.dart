import 'dart:convert';

SongModel songModelFromJson(String str) => SongModel.fromJson(json.decode(str));

String songModelToJson(SongModel data) => json.encode(data.toJson());

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
  });

  factory SongModel.fromJson(Map<String, dynamic> json) => SongModel(
        songId: json['song_id'] as String?,
        title: json['title'] as String?,
        artist: json['artist'] as String?,
        durationSeconds: json['durationSeconds'] as int?,
        fileUrl: json['fileUrl'] as String?,
        notes: json['notes'] == null
            ? []
            : List<List<int>>.from(
                (json['notes'] as List<dynamic>).map(
                  (beat) => List<int>.from(
                    (beat as List<dynamic>).map((n) => n as int),
                  ),
                ),
              ),
        rhythm: json['rhythm'] as String?,
        bpm: json['bpm'] as int?,
        songtypeId: json['songtypeId'] as String?,
      );

  String? songId;
  String? title;
  String? artist;
  int? durationSeconds;
  String? fileUrl;
  List<List<int>>? notes;
  String? rhythm;
  int? bpm;
  String? songtypeId;

  Map<String, dynamic> toJson() => {
        'song_id': songId,
        'title': title,
        'artist': artist,
        'durationSeconds': durationSeconds,
        'fileUrl': fileUrl,
        'notes': notes == null
            ? []
            : List<dynamic>.from(
                notes!.map(
                  (beat) => List<dynamic>.from(beat.map((n) => n)),
                ),
              ),
        'rhythm': rhythm,
        'bpm': bpm,
        'songtypeId': songtypeId,
      };
}
