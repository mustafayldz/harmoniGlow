import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_event.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothStateC> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothCharacteristic? characteristic;

  BluetoothBloc() : super(BluetoothStateC()) {
    on<StartScanEvent>(_onStartScan);
    on<StopScanEvent>(_onStopScan);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectFromDeviceEvent>(_onDisconnectFromDevice);
  }

  Future<void> _onStartScan(
      StartScanEvent event, Emitter<BluetoothStateC> emit) async {
    try {
      // Check if already scanning to avoid multiple scans
      if (state.isScanning) {
        debugPrint('Scan is already in progress. Ignoring new scan request.');
        return;
      }

      debugPrint('Starting Bluetooth scan...');
      emit(state.copyWith(isScanning: true));

      // Start the scan with a timeout
      await FlutterBluePlus.startScan(
          withNames: ["BT05"],
          withServices: [],
          timeout: const Duration(seconds: 3));

      debugPrint('Bluetooth scan started.');

      // Listen for scan results and handle them properly
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          if (results.isEmpty) {
            debugPrint('No devices found during scan.');
          }
          emit(state.copyWith(scanResults: results));
        },
        onError: (error) {
          debugPrint('Error during Bluetooth scan: $error');
          emit(state.copyWith(
              isScanning: false,
              errorMessage: 'Failed to start scanning: $error'));
        },
      );

      // Await the scan to complete before proceeding (using the timeout provided)
      await Future.delayed(const Duration(seconds: 5));

      // Stop the scan after timeout
      await _stopScanning(emit);
    } catch (e) {
      debugPrint('Error during Bluetooth scan: $e');
      emit(state.copyWith(
          isScanning: false, errorMessage: 'Failed to start scanning: $e'));
    }
  }

  Future<void> _onStopScan(
      StopScanEvent event, Emitter<BluetoothStateC> emit) async {
    await _stopScanning(emit);
  }

  Future<void> _stopScanning(Emitter<BluetoothStateC> emit) async {
    try {
      debugPrint('Stopping Bluetooth scan...');
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      emit(state.copyWith(isScanning: false));
      debugPrint('Bluetooth scan stopped.');
    } catch (e) {
      debugPrint('Error while stopping scan: $e');
      emit(state.copyWith(
          isScanning: false, errorMessage: 'Failed to stop scanning: $e'));
    }
  }

  Future<void> _onConnectToDevice(
      ConnectToDeviceEvent event, Emitter<BluetoothStateC> emit) async {
    try {
      // Connect to the device
      await event.device.connect();

      // Discover services
      List<BluetoothService> services = await event.device.discoverServices();

      // Find the correct characteristic
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          debugPrint(
              'Service UUID: ${service.uuid}, Characteristic UUID: ${c.uuid}, Properties: ${c.properties}');

          // Check if the service UUID and characteristic UUID match the target
          if (service.uuid.toString().toLowerCase() == 'ffe0' &&
              c.uuid.toString().toLowerCase() == 'ffe1' &&
              (c.properties.write)) {
            characteristic = c;
            emit(state.copyWith(
              characteristic: c,
              isConnected: true,
              connectedDevice: event.device,
            ));
            return;
          }
        }
      }

      // If no writable characteristic found
      emit(state.copyWith(
          isConnected: true,
          connectedDevice: event.device,
          errorMessage: 'No writable characteristic found.'));
    } catch (e) {
      emit(state.copyWith(
          characteristic: null,
          connectedDevice: null,
          isConnected: false,
          errorMessage: 'Failed to connect to device: $e'));
    }
  }

  Future<void> _onDisconnectFromDevice(
      DisconnectFromDeviceEvent event, Emitter<BluetoothStateC> emit) async {
    try {
      // Await the disconnection to make sure the device disconnects before the handler completes
      await event.device.disconnect();

      emit(state.copyWith(
        characteristic: null,
        connectedDevice: null,
        isConnected: false,
      ));
    } catch (e) {
      // Handle any errors that occur during disconnection
      if (!emit.isDone) {
        emit(state.copyWith(
            errorMessage: 'Failed to disconnect from device: $e'));
      }
    }
  }

  Future<bool> isDeviceConnected(BluetoothDevice device) async {
    try {
      // Get the current connection state of the device
      BluetoothConnectionState state = await device.connectionState.first;
      return state == BluetoothConnectionState.connected;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    return super.close();
  }
}
