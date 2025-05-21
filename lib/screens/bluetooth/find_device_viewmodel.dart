import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_event.dart';
import 'package:drumly/services/local_service.dart';

class FindDevicesViewModel {
  FindDevicesViewModel({
    required this.bluetoothBloc,
    required this.storageService,
  });
  final BluetoothBloc bluetoothBloc;
  final StorageService storageService;

  void startScan() => bluetoothBloc.add(StartScanEvent());

  void stopScan() => bluetoothBloc.add(StopScanEvent());

  Future<void> disconnect(BluetoothDevice device) async {
    bluetoothBloc.add(DisconnectFromDeviceEvent(device));
    await storageService.clearSavedDeviceId();
  }

  Future<void> connect(BluetoothDevice device) async {
    bluetoothBloc.add(ConnectToDeviceEvent(device));
    await storageService.saveDeviceId(device);
  }

  List<ScanResult> filterScanResults(List<ScanResult> results) =>
      results.where((r) => r.device.advName.isNotEmpty).toList();
}
