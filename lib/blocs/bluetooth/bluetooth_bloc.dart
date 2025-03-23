import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_event.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_state.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothStateC> {
  BluetoothBloc() : super(BluetoothStateC()) {
    on<StartScanEvent>(_onStartScan);
    on<StopScanEvent>(_onStopScan);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectFromDeviceEvent>(_onDisconnectFromDevice);
    on<ForceNavigationEvent>(_onForceNavigation);
  }
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothCharacteristic? characteristic;

  Future<void> _onStartScan(
    StartScanEvent event,
    Emitter<BluetoothStateC> emit,
  ) async {
    try {
      // Bluetooth açık mı kontrol et
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        debugPrint('Bluetooth is not ON. Current state: $adapterState');
        emit(
          state.copyWith(
            isScanning: false,
            errorMessage: 'Bluetooth is turned off. Please turn it on.',
          ),
        );
        return;
      }

      if (state.isScanning) {
        debugPrint('Scan is already in progress. Ignoring new scan request.');
        return;
      }

      debugPrint('Starting Bluetooth scan...');
      emit(state.copyWith(isScanning: true));

      await FlutterBluePlus.startScan(
        withNames: ['BT05'],
        withServices: [],
        timeout: const Duration(seconds: 10),
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          if (results.isEmpty) {
            debugPrint('No devices found during scan.');
          }
          emit(state.copyWith(scanResults: results));
        },
        onError: (error) {
          debugPrint('Error during Bluetooth scan: $error');
          emit(
            state.copyWith(
              isScanning: false,
              errorMessage: 'Failed to scan: $error',
            ),
          );
        },
      );

      // İsteğe bağlı: 3 saniye sonra taramayı durdur
      await Future.delayed(const Duration(seconds: 3));
      await _stopScanning(emit);
    } catch (e) {
      debugPrint('Error during Bluetooth scan: $e');
      emit(
        state.copyWith(
          isScanning: false,
          errorMessage: 'Unexpected error: $e',
        ),
      );
    }
  }

  Future<void> _onStopScan(
    StopScanEvent event,
    Emitter<BluetoothStateC> emit,
  ) async {
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
      emit(
        state.copyWith(
          isScanning: false,
          errorMessage: 'Failed to stop scanning: $e',
        ),
      );
    }
  }

  Future<void> _onConnectToDevice(
    ConnectToDeviceEvent event,
    Emitter<BluetoothStateC> emit,
  ) async {
    try {
      await event.device.connect();

      // Listen for connection state changes
      event.device.connectionState.listen((state) {
        debugPrint('Bluetooth Connection State: $state');

        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('Device disconnected! Navigating to another page.');
          add(ForceNavigationEvent()); // Trigger navigation event
        }
      });

      // Discover services
      final List<BluetoothService> services =
          await event.device.discoverServices();

      // Find the correct characteristic
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          debugPrint(
            'Service UUID: ${service.uuid}, Characteristic UUID: ${c.uuid}, Properties: ${c.properties}',
          );

          if (service.uuid.toString().toLowerCase() == 'ffe0' &&
              c.uuid.toString().toLowerCase() == 'ffe1' &&
              c.properties.write) {
            characteristic = c;
            emit(
              state.copyWith(
                characteristic: c,
                isConnected: true,
                connectedDevice: event.device,
              ),
            );
            return;
          }
        }
      }

      emit(
        state.copyWith(
          isConnected: true,
          connectedDevice: event.device,
          errorMessage: 'No writable characteristic found.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isConnected: false,
          errorMessage: 'Failed to connect to device: $e',
        ),
      );
    }
  }

  Future<void> _onDisconnectFromDevice(
    DisconnectFromDeviceEvent event,
    Emitter<BluetoothStateC> emit,
  ) async {
    try {
      await event.device.disconnect();

      // ✅ Tarama otomatik olarak durdurulsun
      await FlutterBluePlus.stopScan();

      emit(
        state.copyWith(
          isConnected: false,
        ),
      );
    } catch (e) {
      if (!emit.isDone) {
        emit(
          state.copyWith(errorMessage: 'Failed to disconnect from device: $e'),
        );
      }
    }
  }

  Future<bool> isDeviceConnected(BluetoothDevice device) async {
    try {
      // Get the current connection state of the device
      final BluetoothConnectionState state = await device.connectionState.first;
      return state == BluetoothConnectionState.connected;
    } catch (e) {
      return false;
    }
  }

  Future<void> _onForceNavigation(
    ForceNavigationEvent event,
    Emitter<BluetoothStateC> emit,
  ) async {
    emit(state.copyWith(isConnected: false));
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    return super.close();
  }
}
