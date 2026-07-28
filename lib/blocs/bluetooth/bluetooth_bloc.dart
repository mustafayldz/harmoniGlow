import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_event.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_state.dart';
import 'package:drumly/services/local_service.dart';

class BluetoothBloc extends Bloc<BluetoothEvent, BluetoothStateC> {
  BluetoothBloc() : super(BluetoothStateC()) {
    on<StartScanEvent>(_onStartScan);
    on<StopScanEvent>(_onStopScan);
    on<ScanResultsUpdatedEvent>(_onScanResultsUpdated);
    on<ScanFailedEvent>(_onScanFailed);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<DisconnectFromDeviceEvent>(_onDisconnectFromDevice);
    on<ForceNavigationEvent>(_onForceNavigation);

    // Kick off auto‑connect as soon as the Bloc is instantiated
    _initializeConnection();
  }
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  Timer? _scanTimer;
  String? _savedDeviceId;
  BluetoothCharacteristic? characteristic;

  Future<void> _initializeConnection() async {
    _savedDeviceId = await StorageService().getSavedDeviceId();

    // ─── 0) Wait for Bluetooth to be powered ON ────────────────────────
    // Bluetooth açık mı kontrol et
    final adapterState = await FlutterBluePlus.adapterState.firstWhere(
      (s) => s == BluetoothAdapterState.on || s == BluetoothAdapterState.off,
    );

    if (adapterState == BluetoothAdapterState.off) {
      return;
    }

    if (_savedDeviceId != null) {
      // ─── 1) Check already‑connected devices ───────────────────────────
      final connected = FlutterBluePlus.connectedDevices;
      final already = connected.where((d) => d.remoteId.str == _savedDeviceId);
      if (already.isNotEmpty) {
        add(ConnectToDeviceEvent(already.first));
        return;
      }
    }
    add(StartScanEvent());
  }

  Future<void> _onStartScan(
    StartScanEvent event,
    Emitter<BluetoothStateC> emit,
  ) async {
    try {
      // Bluetooth açık mı kontrol et
      final adapterState = await FlutterBluePlus.adapterState.firstWhere(
        (s) => s == BluetoothAdapterState.on || s == BluetoothAdapterState.off,
      );

      if (adapterState == BluetoothAdapterState.off) {
        emit(
          state.copyWith(
            isScanning: false,
            errorMessage: 'Bluetooth is turned off. Please turn it on.',
          ),
        );
        return;
      }

      if (state.isScanning) {
        return;
      }

      emit(
        state.copyWith(
          isScanning: true,
          scanResults: const [],
          clearError: true,
        ),
      );

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) => add(ScanResultsUpdatedEvent(results)),
        onError: (Object error) =>
            add(ScanFailedEvent('Failed to scan: $error')),
      );

      await FlutterBluePlus.startScan(
        withNames: ['BT05'],
        timeout: const Duration(seconds: 10),
      );

      _scanTimer?.cancel();
      _scanTimer = Timer(
        const Duration(seconds: 10),
        () => add(StopScanEvent()),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isScanning: false,
          errorMessage: 'Unexpected error: $e',
        ),
      );
    }
  }

  void _onScanResultsUpdated(
    ScanResultsUpdatedEvent event,
    Emitter<BluetoothStateC> emit,
  ) {
    emit(state.copyWith(scanResults: event.results));
    if (_savedDeviceId == null || state.isConnected || state.isConnecting) {
      return;
    }
    final saved = event.results.where(
      (result) => result.device.remoteId.str == _savedDeviceId,
    );
    if (saved.isNotEmpty) add(ConnectToDeviceEvent(saved.first.device));
  }

  void _onScanFailed(
    ScanFailedEvent event,
    Emitter<BluetoothStateC> emit,
  ) {
    emit(state.copyWith(isScanning: false, errorMessage: event.message));
  }

  Future<void> _onStopScan(
    StopScanEvent event,
    Emitter<BluetoothStateC> emit,
  ) async {
    await _stopScanning(emit);
  }

  Future<void> _stopScanning(Emitter<BluetoothStateC> emit) async {
    try {
      _scanTimer?.cancel();
      _scanTimer = null;
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      emit(state.copyWith(isScanning: false));
    } catch (e) {
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
      await FlutterBluePlus.stopScan();
      _scanTimer?.cancel();
      _scanTimer = null;
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      emit(
        state.copyWith(
          isScanning: false,
          isConnecting: true,
          clearError: true,
        ),
      );
      await event.device.connect();

      // Listen for connection state changes
      await _connectionSubscription?.cancel();
      _connectionSubscription = event.device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          add(ForceNavigationEvent()); // Trigger navigation event
        }
      });

      // Discover services
      final List<BluetoothService> services =
          await event.device.discoverServices();

      // Find the correct characteristic
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic c in service.characteristics) {
          //   'Service UUID: ${service.uuid}, Characteristic UUID: ${c.uuid}, Properties: ${c.properties}',
          // );

          if (service.uuid.toString().toLowerCase() == 'ffe0' &&
              c.uuid.toString().toLowerCase() == 'ffe1' &&
              c.properties.write) {
            characteristic = c;
            _savedDeviceId = event.device.remoteId.str;
            await StorageService().saveDeviceId(event.device);
            emit(
              state.copyWith(
                characteristic: c,
                isConnected: true,
                isConnecting: false,
                connectedDevice: event.device,
              ),
            );
            return;
          }
        }
      }

      _savedDeviceId = event.device.remoteId.str;
      await StorageService().saveDeviceId(event.device);
      emit(
        state.copyWith(
          isConnected: true,
          isConnecting: false,
          connectedDevice: event.device,
          errorMessage: 'No writable characteristic found.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isConnected: false,
          isConnecting: false,
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
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      await event.device.disconnect();
      await StorageService().clearSavedDeviceId();
      _savedDeviceId = null;

      emit(
        state.copyWith(
          isConnected: false,
          isConnecting: false,
          clearConnectedDevice: true,
          clearCharacteristic: true,
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
    emit(
      state.copyWith(
        isConnected: false,
        isConnecting: false,
        clearConnectedDevice: true,
        clearCharacteristic: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    _connectionSubscription?.cancel();
    FlutterBluePlus.stopScan();
    return super.close();
  }
}
