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
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 3));
      debugPrint('Bluetooth scan started.');

      // Listen to scan results stream
      final subscription = FlutterBluePlus.scanResults.listen(
        (results) {
          debugPrint('Scan results received: ${results.length} devices found.');
          if (emit.isDone) {
            return; // Check if the emitter is done before emitting
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

      await FlutterBluePlus.stopScan();
      emit(state.copyWith(isScanning: false));
      debugPrint('Bluetooth scan completed.');

      // Cancel the subscription when done
      await subscription.cancel();
    } catch (e) {
      debugPrint('Error during Bluetooth scan: $e');
      emit(state.copyWith(
          isScanning: false, errorMessage: 'Failed to start scanning: $e'));
    }
  }

  Future<void> _onStopScan(
      StopScanEvent event, Emitter<BluetoothStateC> emit) async {
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    emit(state.copyWith(isScanning: false, scanResults: []));
  }

  Future<void> _onConnectToDevice(
      ConnectToDeviceEvent event, Emitter<BluetoothStateC> emit) async {
    try {
      // Connect to the device
      await event.device.connect();

      List<BluetoothService> services = await event.device.discoverServices();

      // Find the first writable characteristic
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.properties.write) {
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
