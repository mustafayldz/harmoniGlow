import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_event.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_state.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/home_page.dart';
import 'package:harmoniglow/screens/intro/intro_page.dart';

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
    _startBluetoothScan();
  }

  void _startBluetoothScan() {
    context.read<BluetoothBloc>().add(StartScanEvent());
  }

  void _stopBluetoothScan() {
    context.read<BluetoothBloc>().add(StopScanEvent());
  }

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
            return result.device.advName.isNotEmpty;
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
          device.advName.isNotEmpty ? device.advName : 'Unknown Device',
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

  void _navigateToDeviceScreen(BluetoothDevice device) async {
    final skipIntro = await StorageService.skipIntroPage();
    if (!mounted) return;

    if (skipIntro) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IntroPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopBluetoothScan();
    super.dispose();
  }
}
