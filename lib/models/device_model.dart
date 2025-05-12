// To parse this JSON data, do
//
//     final deviceModel = deviceModelFromJson(jsonString);

import 'dart:convert';

DeviceModel deviceModelFromJson(String str) =>
    DeviceModel.fromJson(json.decode(str));

String deviceModelToJson(DeviceModel data) => json.encode(data.toJson());

class DeviceModel {
  DeviceModel({
    this.deviceId,
    this.model,
    this.serialNumber,
    this.firmwareVersion,
    this.hardwareVersion,
    this.lastConnectedAt,
    this.pairedAt,
    this.isActive,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        deviceId: json['deviceId'],
        model: json['model'],
        serialNumber: json['serialNumber'],
        firmwareVersion: json['firmwareVersion'],
        hardwareVersion: json['hardwareVersion'],
        lastConnectedAt: json['lastConnectedAt'],
        pairedAt: json['pairedAt'],
        isActive: json['isActive'],
      );
  String? deviceId;
  String? model;
  String? serialNumber;
  String? firmwareVersion;
  String? hardwareVersion;
  int? lastConnectedAt;
  int? pairedAt;
  int? isActive;

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'model': model,
        'serialNumber': serialNumber,
        'firmwareVersion': firmwareVersion,
        'hardwareVersion': hardwareVersion,
        'lastConnectedAt': lastConnectedAt,
        'pairedAt': pairedAt,
        'isActive': isActive,
      };
}
