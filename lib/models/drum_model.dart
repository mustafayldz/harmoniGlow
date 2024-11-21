import 'dart:convert';

DrumModel drumModelFromJson(String str) => DrumModel.fromJson(json.decode(str));

String drumModelToJson(DrumModel data) => json.encode(data.toJson());

class DrumModel {
  int? led;
  String? name;
  List<int>? rgb;

  DrumModel({
    this.led,
    this.name,
    this.rgb,
  });

  factory DrumModel.fromJson(Map<String, dynamic> json) => DrumModel(
        led: json["led"],
        name: json["name"],
        rgb: json["rgb"] == null
            ? []
            : List<int>.from(json["rgb"]!.map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "led": led,
        "name": name,
        "rgb": rgb == null ? [] : List<dynamic>.from(rgb!.map((x) => x)),
      };
}
