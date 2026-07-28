import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class BluetoothEvent {}

class StartScanEvent extends BluetoothEvent {}

class ForceNavigationEvent extends BluetoothEvent {}

class StopScanEvent extends BluetoothEvent {}

class ScanResultsUpdatedEvent extends BluetoothEvent {
  ScanResultsUpdatedEvent(this.results);
  final List<ScanResult> results;
}

class ScanFailedEvent extends BluetoothEvent {
  ScanFailedEvent(this.message);
  final String message;
}

class ConnectToDeviceEvent extends BluetoothEvent {
  ConnectToDeviceEvent(this.device);
  final BluetoothDevice device;
}

class DisconnectFromDeviceEvent extends BluetoothEvent {
  DisconnectFromDeviceEvent(this.device);
  final BluetoothDevice device;
}
