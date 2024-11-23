import 'dart:convert';

ShuffleModel shuffleModelFromJson(String str) =>
    ShuffleModel.fromJson(json.decode(str));

String shuffleModelToJson(ShuffleModel data) => json.encode(data.toJson());

class ShuffleModel {
  String? name;
  String? color;
  int? bpm;

  ShuffleModel({
    this.name,
    this.color,
    this.bpm,
  });

  factory ShuffleModel.fromJson(Map<String, dynamic> json) => ShuffleModel(
        name: json["name"],
        color: json["color"],
        bpm: json["bpm"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "color": color,
        "bpm": bpm,
      };
}
