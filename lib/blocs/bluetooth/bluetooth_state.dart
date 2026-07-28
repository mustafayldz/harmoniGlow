import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothStateC {
  BluetoothStateC({
    this.isConnected = false,
    this.isScanning = false,
    this.isConnecting = false,
    this.connectedDevice,
    this.scanResults = const [],
    this.characteristic,
    this.errorMessage,
  });
  final bool isConnected;
  final bool isScanning;
  final bool isConnecting;
  final BluetoothDevice? connectedDevice;
  final List<ScanResult> scanResults;
  final BluetoothCharacteristic? characteristic;
  final String? errorMessage;

  BluetoothStateC copyWith({
    bool? isConnected,
    bool? isScanning,
    bool? isConnecting,
    BluetoothDevice? connectedDevice,
    List<ScanResult>? scanResults,
    BluetoothCharacteristic? characteristic,
    String? errorMessage,
    bool clearConnectedDevice = false,
    bool clearCharacteristic = false,
    bool clearError = false,
  }) =>
      BluetoothStateC(
        isConnected: isConnected ?? this.isConnected,
        isScanning: isScanning ?? this.isScanning,
        isConnecting: isConnecting ?? this.isConnecting,
        connectedDevice: clearConnectedDevice
            ? null
            : connectedDevice ?? this.connectedDevice,
        scanResults: scanResults ?? this.scanResults,
        characteristic:
            clearCharacteristic ? null : characteristic ?? this.characteristic,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}
