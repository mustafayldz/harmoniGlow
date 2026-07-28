import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_state.dart';
import 'package:drumly/screens/bluetooth/find_device_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    vm = FindDevicesViewModel(
      bluetoothBloc: context.read<BluetoothBloc>(),
      storageService: StorageService(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !vm.bluetoothBloc.state.isConnected) vm.startScan();
    });
  }

  @override
  void dispose() {
    vm.stopScan();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF070A10) : const Color(0xFFF5F6F8);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BluetoothBloc, BluetoothStateC>(
          builder: (context, state) {
            final results = vm.filterScanResults(state.scanResults);
            return Column(
              children: [
                _BluetoothAppBar(isDark: isDark, onBack: _goBack),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => vm.startScan(),
                    color: const Color(0xFF3ED598),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                          sliver: SliverToBoxAdapter(
                            child: _ProductInfoCard(isDark: isDark),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          sliver: SliverToBoxAdapter(
                            child: _ScanStatusCard(
                              isDark: isDark,
                              state: state,
                              deviceCount: results.length,
                              onScan:
                                  state.isScanning ? vm.stopScan : vm.startScan,
                            ),
                          ),
                        ),
                        if (state.errorMessage != null)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                            sliver: SliverToBoxAdapter(
                              child: _BluetoothError(
                                message: state.errorMessage!,
                                onRetry: vm.startScan,
                              ),
                            ),
                          ),
                        if (state.isConnected && state.connectedDevice != null)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                            sliver: SliverToBoxAdapter(
                              child: _ConnectedDeviceCard(
                                isDark: isDark,
                                device: state.connectedDevice!,
                                onHome: _goBack,
                                onDisconnect: () async {
                                  await vm.disconnect(state.connectedDevice!);
                                  vm.startScan();
                                },
                              ),
                            ),
                          )
                        else if (results.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyScanState(
                              isDark: isDark,
                              isScanning: state.isScanning,
                              onScan: vm.startScan,
                            ),
                          )
                        else ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                'available_devices'.tr(),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF20222D),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                            sliver: SliverList.separated(
                              itemCount: results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) => _DeviceCard(
                                result: results[index],
                                isDark: isDark,
                                isConnecting: state.isConnecting,
                                onConnect: () =>
                                    vm.connect(results[index].device),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BluetoothAppBar extends StatelessWidget {
  const _BluetoothAppBar({required this.isDark, required this.onBack});

  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            Material(
              color: isDark ? const Color(0xFF151923) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : const Color(0xFF252733),
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'bluetooth_devices'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF171923),
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'bluetooth_page_subtitle'.tr(),
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF727481),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF3ED598).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bluetooth_rounded,
                color: Color(0xFF3ED598),
              ),
            ),
          ],
        ),
      );
}

class _ProductInfoCard extends StatelessWidget {
  const _ProductInfoCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF12312D), Color(0xFF151C24)]
                : const [Color(0xFF173C37), Color(0xFF102B30)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3ED598).withValues(alpha: 0.13),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.lightbulb_circle_rounded,
                    color: Color(0xFF3ED598),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'drumly_kit_title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'drumly_kit_description'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(
                  icon: Icons.bolt_rounded,
                  label: 'realtime_lighting'.tr(),
                ),
                _FeatureChip(
                  icon: Icons.bluetooth_searching_rounded,
                  label: 'wireless_connection'.tr(),
                ),
                _FeatureChip(
                  icon: Icons.music_note_rounded,
                  label: 'guided_practice'.tr(),
                ),
              ],
            ),
          ],
        ),
      );
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF3ED598), size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({
    required this.isDark,
    required this.state,
    required this.deviceCount,
    required this.onScan,
  });

  final bool isDark;
  final BluetoothStateC state;
  final int deviceCount;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12161E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 42,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (state.isScanning)
                    const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF3ED598),
                    ),
                  Icon(
                    state.isConnected
                        ? Icons.bluetooth_connected_rounded
                        : Icons.radar_rounded,
                    color: const Color(0xFF3ED598),
                    size: 21,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isConnecting
                        ? 'connecting'.tr()
                        : state.isScanning
                            ? 'scanning_devices'.tr()
                            : state.isConnected
                                ? 'connected'.tr()
                                : 'scan_ready'.tr(),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF20222D),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$deviceCount ${'device_count'.tr()}',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : const Color(0xFF858793),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!state.isConnected && !state.isConnecting)
              TextButton(
                onPressed: onScan,
                child: Text(
                  state.isScanning ? 'stop'.tr() : 'scan_again'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      );
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.result,
    required this.isDark,
    required this.isConnecting,
    required this.onConnect,
  });

  final ScanResult result;
  final bool isDark;
  final bool isConnecting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final name = result.device.advName.isEmpty
        ? 'unknownDevice'.tr()
        : result.device.advName;
    final signal = result.rssi >= -60
        ? 'signal_excellent'.tr()
        : result.rssi >= -75
            ? 'signal_good'.tr()
            : 'signal_weak'.tr();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12161E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3ED598).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Color(0xFF3ED598),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF20222D),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$signal • ${result.rssi} dBm',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : const Color(0xFF858793),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: isConnecting ? null : onConnect,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3ED598),
              foregroundColor: const Color(0xFF09211C),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: isConnecting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'connect'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedDeviceCard extends StatelessWidget {
  const _ConnectedDeviceCard({
    required this.isDark,
    required this.device,
    required this.onHome,
    required this.onDisconnect,
  });

  final bool isDark;
  final BluetoothDevice device;
  final VoidCallback onHome;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12161E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF3ED598).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF3ED598).withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_connected_rounded,
                color: Color(0xFF3ED598),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              device.advName.isEmpty ? 'Drumly Kit' : device.advName,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF20222D),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'device_connected_ready'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF777985),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onHome,
                icon: const Icon(Icons.home_rounded),
                label: Text('return_home'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3ED598),
                  foregroundColor: const Color(0xFF09211C),
                ),
              ),
            ),
            TextButton(
              onPressed: onDisconnect,
              child: Text(
                'disconnectAndScanAgain'.tr(),
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      );
}

class _BluetoothError extends StatelessWidget {
  const _BluetoothError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text('refresh'.tr())),
          ],
        ),
      );
}

class _EmptyScanState extends StatelessWidget {
  const _EmptyScanState({
    required this.isDark,
    required this.isScanning,
    required this.onScan,
  });

  final bool isDark;
  final bool isScanning;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF3ED598).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                isScanning
                    ? Icons.bluetooth_searching_rounded
                    : Icons.bluetooth_disabled_rounded,
                color: const Color(0xFF3ED598),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isScanning ? 'searching_for_kit'.tr() : 'noDevicesFound'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF20222D),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isScanning ? 'keep_kit_nearby'.tr() : 'bluetooth_scan_help'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.48)
                    : const Color(0xFF777985),
                height: 1.4,
              ),
            ),
            if (!isScanning) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.radar_rounded),
                label: Text('scan_again'.tr()),
              ),
            ],
          ],
        ),
      );
}
