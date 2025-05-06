import 'dart:convert';

DeviceModel deviceModelFromJson(String str) =>
    DeviceModel.fromJson(json.decode(str));

String deviceModelToJson(DeviceModel data) => json.encode(data.toJson());

class DeviceModel {
  DeviceModel({
    this.deviceId,
    this.model,
    this.hardwareVersion,
    this.firmwareVersion,
    this.serialNumber,
    this.isActive,
    this.pairedAt,
    this.lastConnectedAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
        deviceId: json['device_id'],
        model: json['model'],
        hardwareVersion: json['hardware_version'],
        firmwareVersion: json['firmware_version'],
        serialNumber: json['serial_number'],
        isActive: json['is_active'],
        pairedAt: json['paired_at'],
        lastConnectedAt: json['last_connected_at'],
      );
  String? deviceId;
  String? model;
  String? hardwareVersion;
  String? firmwareVersion;
  String? serialNumber;
  int? isActive;
  int? pairedAt;
  int? lastConnectedAt;

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'model': model,
        'hardware_version': hardwareVersion,
        'firmware_version': firmwareVersion,
        'serial_number': serialNumber,
        'is_active': isActive,
        'paired_at': pairedAt,
        'last_connected_at': lastConnectedAt,
      };
}
