import 'package:drumly/hive/models/note_model.dart';
import 'package:hive/hive.dart';

part 'beat_maker_model.g.dart';

@HiveType(typeId: 1)
class BeatMakerModel extends HiveObject {
  BeatMakerModel({
    required this.createdAt,
    required this.updatedAt,
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

  @HiveField(0)
  String? id;

  @HiveField(1)
  String? beatId;

  @HiveField(2)
  int? bpm;

  @HiveField(3)
  int? durationSeconds;

  @HiveField(4)
  String? fileUrl;

  @HiveField(5)
  String? genre;

  @HiveField(6)
  List<NoteModel>? notes;

  @HiveField(7)
  String? rhythm;

  @HiveField(8)
  String? title;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;
}
