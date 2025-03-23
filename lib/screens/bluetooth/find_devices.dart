import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_event.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_state.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/home_page.dart';
import 'package:url_launcher/url_launcher.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({super.key});

  @override
  FindDevicesScreenState createState() => FindDevicesScreenState();
}

class FindDevicesScreenState extends State<FindDevicesScreen> {
  bool hasNavigated = false; // ✅ Prevents multiple navigations
  List<ScanResult> filteredResults = [];
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();

    // ✅ Start scan only if navigation hasn't happened yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !hasNavigated) {
        print('Starting Bluetooth scan from FindDevicesScreen initState');
        _startBluetoothScan();
      }
    });
  }

  @override
  void dispose() {
    print('Stopping Bluetooth scan from FindDevicesScreen dispose');
    Future.microtask(() {
      if (mounted) {
        context.read<BluetoothBloc>().add(StopScanEvent());
      }
    });
    super.dispose();
  }

  void _startBluetoothScan() {
    if (mounted) {
      print('Starting Bluetooth scan from _startBluetoothScan');
      context.read<BluetoothBloc>().add(StartScanEvent());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            _startBluetoothScan();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<BluetoothBloc, BluetoothStateC>(
                    builder: (context, state) {
                      if (state.isScanning) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      filteredResults = state.scanResults
                          .where((result) => result.device.advName.isNotEmpty)
                          .toList();

                      if (filteredResults.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  'No devices found. Please ensure Bluetooth is enabled.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  _startBluetoothScan();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          final result = filteredResults[index];
                          return _buildDeviceCard(
                            context,
                            result.device,
                            result,
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildPurchaseCard(),
              ],
            ),
          ),
        ),
      );

  Widget _buildDeviceCard(
    BuildContext context,
    BluetoothDevice device,
    ScanResult result,
  ) {
    final bluetoothBloc = context.read<BluetoothBloc>();

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
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
            subtitle: Text('Signal Strength: ${result.rssi} dBm'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                if (bluetoothBloc.state.isConnected) {
                  await _disconnectDevice(context, device);
                } else {
                  await _connectToDevice(context, device);
                }
              },
              icon: Icon(
                bluetoothBloc.state.isConnected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_connected,
              ),
              label: Text(
                bluetoothBloc.state.isConnected ? 'Disconnect' : 'Connect',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard() => Card(
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: ElevatedButton(
            onPressed: () async {
              const url =
                  'https://www.amazon.ca/Jackery-Generator-Portable-Charging-Emergencies/dp/B0DHRV6W9K?ref=dlx_black_dg_dcl_B0DHRV6W9K_dt_sl7_14&th=1';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              } else {
                throw 'Could not launch $url';
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Buy on Amazon'),
          ),
        ),
      );

  Future<void> _disconnectDevice(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    print('Disconnecting from device: ${device.advName}');
    final bluetoothBloc = context.read<BluetoothBloc>();

    // Await the event dispatch to handle any asynchronous operation in the bloc
    bluetoothBloc.add(DisconnectFromDeviceEvent(device));

    // Assuming _storageService.clearDevice() could be async
    await _storageService.clearDevice();
  }

  Future<void> _connectToDevice(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    print('Connecting to device: ${device.advName}');
    final bluetoothBloc = context.read<BluetoothBloc>();
    bluetoothBloc.add(ConnectToDeviceEvent(device));
    await _storageService.saveDevice(device);

    _navigateToDeviceScreen(device);
  }

  void _navigateToDeviceScreen(BluetoothDevice device) async {
    print('Navigating to DeviceScreen _navigateToDeviceScreen');
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }
}
