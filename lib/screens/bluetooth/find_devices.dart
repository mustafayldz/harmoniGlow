import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_event.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_state.dart';
import 'package:harmoniglow/constants.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/home_page.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({super.key});

  @override
  FindDevicesScreenState createState() => FindDevicesScreenState();
}

class FindDevicesScreenState extends State<FindDevicesScreen> {
  List<ScanResult> filteredResults = [];
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // _checkSavedDevice();
    _startBluetoothScan();
  }

  void _startBluetoothScan() {
    context.read<BluetoothBloc>().add(StartScanEvent());
  }

  void _stopBluetoothScan() {
    context.read<BluetoothBloc>().add(StopScanEvent());
  }

  // void _checkSavedDevice() async {
  //   final device = await _storageService.getSavedDevice();
  //   if (device.isNotEmpty) {
  //     // Proceed with using the saved device information.
  //     String deviceId = device['deviceId'] ?? 'Unknown ID';
  //     String deviceName = device['deviceName'] ?? 'Unknown Name';
  //     debugPrint('Device ID: $deviceId, Device Name: $deviceName');
  //   } else {
  //     // Handle the case where no device has been saved, such as prompting the user to connect.
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Device'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const RgbLedsScreen(),
              //   ),
              // );
              _startBluetoothScan();
            },
          ),
        ],
      ),
      body: BlocBuilder<BluetoothBloc, BluetoothStateC>(
        builder: (context, state) {
          if (state.isScanning) {
            return const Center(child: CircularProgressIndicator());
          }

          filteredResults = state.scanResults.where((result) {
            return result.advertisementData.serviceUuids
                .contains(Constants.myServiceUuid);
          }).toList();

          if (filteredResults.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No devices found. Please ensure Bluetooth is enabled.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredResults.length,
            itemBuilder: (context, index) {
              final result = filteredResults[index];
              return _buildDeviceCard(context, result.device, result);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeviceCard(
      BuildContext context, BluetoothDevice device, ScanResult result) {
    final bluetoothBloc = context.read<BluetoothBloc>();

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor:
              bluetoothBloc.state.isConnected ? Colors.green : Colors.grey,
          child: Icon(
            bluetoothBloc.state.isConnected
                ? Icons.bluetooth_connected
                : Icons.bluetooth_disabled,
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          if (bluetoothBloc.state.isConnected) {
            await _disconnectDevice(context, device);
          } else {
            await _connectToDevice(context, device);
          }
        },
      ),
    );
  }

  Future<void> _disconnectDevice(
      BuildContext context, BluetoothDevice device) async {
    final bluetoothBloc = context.read<BluetoothBloc>();

    // Await the event dispatch to handle any asynchronous operation in the bloc
    bluetoothBloc.add(DisconnectFromDeviceEvent(device));

    // Assuming _storageService.clearDevice() could be async
    await _storageService.clearDevice();
  }

  Future<void> _connectToDevice(
      BuildContext context, BluetoothDevice device) async {
    final bluetoothBloc = context.read<BluetoothBloc>();
    bluetoothBloc.add(ConnectToDeviceEvent(device));
    await _storageService.saveDevice(device);
    _stopBluetoothScan();

    _navigateToDeviceScreen(device);
  }

  void _navigateToDeviceScreen(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  @override
  void dispose() {
    _stopBluetoothScan();
    super.dispose();
  }
}
