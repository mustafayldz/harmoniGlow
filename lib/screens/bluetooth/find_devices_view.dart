import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_state.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/screens/bluetooth/find_device_viewmodel.dart';
import 'package:drumly/screens/home/home_view.dart';
import 'package:drumly/services/local_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FindDevicesView extends StatefulWidget {
  const FindDevicesView({super.key});

  @override
  State<FindDevicesView> createState() => _FindDevicesViewState();
}

class _FindDevicesViewState extends State<FindDevicesView> {
  late final FindDevicesViewModel vm;
  bool hasNavigated = false;

  @override
  void initState() {
    super.initState();
    vm = FindDevicesViewModel(
      bluetoothBloc: context.read<BluetoothBloc>(),
      storageService: StorageService(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !hasNavigated) vm.startScan();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (mounted) vm.stopScan();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: const Icon(Icons.arrow_back, color: Colors.transparent),
          actions: [
            GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeView()),
                (route) => false,
              ),
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.double_arrow_outlined,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async => vm.startScan(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<BluetoothBloc, BluetoothStateC>(
                    builder: (context, state) {
                      final results = vm.filterScanResults(state.scanResults);

                      if (state.isScanning) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (state.isConnected &&
                          state.connectedDevice != null) {
                        return _buildConnectedView(state.connectedDevice!);
                      } else if (results.isEmpty) {
                        return _buildEmptyView();
                      } else {
                        return ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) =>
                              _buildDeviceCard(results[index]),
                        );
                      }
                    },
                  ),
                ),
                // _buildPurchaseCard(),
              ],
            ),
          ),
        ),
      );

  Widget _buildConnectedView(BluetoothDevice device) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${'alreadyConnectedTo'.tr()} ${device.advName}.',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => vm.disconnect(device),
                icon: const Icon(Icons.restart_alt),
                label: const Text('disconnectAndScanAgain').tr(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyView() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'noDevicesFound'.tr(),
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: vm.startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('refresh').tr(),
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

  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final isConnected = context.read<BluetoothBloc>().state.isConnected;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: isConnected ? Colors.green : Colors.grey,
              child: Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: Colors.white,
              ),
            ),
            title: Text(
              device.advName.isNotEmpty ? device.advName : 'unknownDevice'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${'signalStrength'.tr()} ${result.rssi} dBm'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                if (isConnected) {
                  await vm.disconnect(device);
                } else {
                  await vm.connect(device);
                  if (!mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                }
              },
              icon: Icon(
                isConnected
                    ? Icons.bluetooth_disabled
                    : Icons.bluetooth_connected,
              ),
              label: Text(isConnected ? 'disconnect'.tr() : 'connect'.tr()),
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

  // Widget _buildPurchaseCard() => Card(
  //       elevation: 6,
  //       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
  //         child: ElevatedButton(
  //           onPressed: () async {
  //             const url =
  //                 'https://www.amazon.ca/Jackery-Generator-Portable-Charging-Emergencies/dp/B0DHRV6W9K';
  //             if (await canLaunchUrl(Uri.parse(url))) {
  //               await launchUrl(Uri.parse(url));
  //             }
  //           },
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.emerald,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //           ),
  //           child: const Text(
  //             'Buy on Amazon',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //         ),
  //       ),
  //     );
}
