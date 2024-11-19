import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothStateC {
  final bool isConnected;
  final bool isScanning;
  final BluetoothDevice? connectedDevice;
  final List<ScanResult> scanResults;
  final BluetoothCharacteristic? characteristic;
  final String? errorMessage;

  BluetoothStateC({
    this.isConnected = false,
    this.isScanning = false,
    this.connectedDevice,
    this.scanResults = const [],
    this.characteristic,
    this.errorMessage,
  });

  BluetoothStateC copyWith({
    bool? isConnected,
    bool? isScanning,
    BluetoothDevice? connectedDevice,
    List<ScanResult>? scanResults,
    BluetoothCharacteristic? characteristic,
    String? errorMessage,
  }) {
    return BluetoothStateC(
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      scanResults: scanResults ?? this.scanResults,
      characteristic: characteristic ?? this.characteristic,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
