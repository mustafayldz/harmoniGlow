import 'dart:convert';

TraningModel traningModelFromJson(String str) =>
    TraningModel.fromJson(json.decode(str));

String traningModelToJson(TraningModel data) => json.encode(data.toJson());

class TraningModel {
  String? name;
  String? rhythm;
  int? bpm;
  int? totalTime;
  List<List<int>>? notes;

  TraningModel({
    this.name,
    this.rhythm,
    this.bpm,
    this.totalTime,
    this.notes,
  });

  factory TraningModel.fromJson(Map<String, dynamic> json) => TraningModel(
        name: json["name"],
        rhythm: json["rhythm"],
        bpm: json["bpm"],
        totalTime: json["totalTime"],
        notes: json["notes"] == null
            ? []
            : List<List<int>>.from(
                json["notes"]!.map((x) => List<int>.from(x.map((x) => x)))),
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "rhythm": rhythm,
        "bpm": bpm,
        "totalTime": totalTime,
        "notes": notes == null
            ? []
            : List<dynamic>.from(
                notes!.map((x) => List<dynamic>.from(x.map((x) => x)))),
      };
}
