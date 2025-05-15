import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 2)
class NoteModel extends HiveObject {
  NoteModel({
    required this.i,
    required this.sM,
    required this.eM,
    required this.led,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        i: json['i'],
        sM: json['sM'],
        eM: json['eM'],
        led: List<int>.from(json['led']),
      );
  @HiveField(0)
  int i;

  @HiveField(1)
  int sM;

  @HiveField(2)
  int eM;

  @HiveField(3)
  List<int> led;

  Map<String, dynamic> toJson() => {
        'i': i,
        'sM': sM,
        'eM': eM,
        'led': led,
      };
}
