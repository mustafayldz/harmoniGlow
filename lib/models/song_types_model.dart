// To parse this JSON data, do
//
//     final songTypeModel = songTypeModelFromJson(jsonString);

import 'dart:convert';

SongTypeModel songTypeModelFromJson(String str) =>
    SongTypeModel.fromJson(json.decode(str));

String songTypeModelToJson(SongTypeModel data) => json.encode(data.toJson());

class SongTypeModel {
  SongTypeModel({
    this.id,
    this.createdAt,
    this.description,
    this.name,
    this.songtypeId,
    this.updatedAt,
  });

  factory SongTypeModel.fromJson(Map<String, dynamic> json) => SongTypeModel(
        id: json['_id'],
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at']),
        description: json['description'],
        name: json['name'],
        songtypeId: json['songtype_id'],
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at']),
      );
  String? id;
  DateTime? createdAt;
  String? description;
  String? name;
  int? songtypeId;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        '_id': id,
        'created_at': createdAt?.toIso8601String(),
        'description': description,
        'name': name,
        'songtype_id': songtypeId,
        'updated_at': updatedAt?.toIso8601String(),
      };
}
