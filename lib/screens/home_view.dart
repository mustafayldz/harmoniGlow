import 'package:drumly/adMob/ad_view.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/screens/beat_maker/beat_maker_view.dart';
import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:drumly/screens/my_beats/my_beats_view.dart';
import 'package:drumly/screens/my_drum/drum_adjustment.dart';
import 'package:drumly/screens/my_drum/drum_model.dart';
import 'package:drumly/screens/settings/setting_view.dart';
import 'package:drumly/screens/songs/song_view.dart';
import 'package:drumly/screens/training/traning_view.dart';
import 'package:drumly/services/local_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<_CardData> _cards = [];

  @override
  void initState() {
    super.initState();
    _checkLocalStorage();
    _initCards();
  }

  void _initCards() {
    _cards = [
      _CardData(
        key: 'training',
        title: 'training'.tr(),
        subtitle: 'trainWithMusic'.tr(),
        color: Colors.greenAccent,
        emoji: '🎯',
      ),
      _CardData(
        key: 'songs',
        title: 'songs'.tr(),
        subtitle: 'discoverSongs'.tr(),
        color: Colors.pinkAccent,
        emoji: '🎤',
      ),
      _CardData(
        key: 'my beats',
        title: 'myBeats'.tr(),
        subtitle: 'listenToBeats'.tr(),
        color: Colors.purpleAccent,
        emoji: '🎼',
      ),
      _CardData(
        key: 'my drum',
        title: 'myDrum'.tr(),
        subtitle: 'adjustDrum'.tr(),
        color: Colors.blueAccent,
        emoji: '🥁',
      ),
      _CardData(
        key: 'beat maker',
        title: 'beatMaker'.tr(),
        subtitle: 'createBeats'.tr(),
        color: Colors.red,
        emoji: '🎛️',
      ),
      _CardData(
        key: 'settings',
        title: 'settings'.tr(),
        subtitle: '',
        color: Colors.teal,
        emoji: '⚙️',
      ),
    ];
  }

  Future<void> _checkLocalStorage() async {
    final savedData = await StorageService.getDrumPartsBulk();
    if (savedData == null) {
      await StorageService.saveDrumPartsBulk(
        DrumParts.drumParts.entries
            .map((e) => DrumModel.fromJson(e.value))
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;
    final deviceName = state.connectedDevice?.advName ?? 'Unknown Device';

    // Rebuild localized cards when language changes
    _initCards();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildBluetoothBanner(isConnected, deviceName),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final destination = _getDestination(card.key, isConnected);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleTap(
                        context,
                        card.key,
                        isConnected,
                        destination,
                      ),
                      child: _buildCard(card),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothBanner(bool connected, String deviceName) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FindDevicesView()),
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: connected ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: connected ? Colors.green : Colors.red,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: connected ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                connected ? 'connectedToDevice'.tr() : 'disconnected'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: connected ? Colors.green[800] : Colors.red[800],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildCard(_CardData card) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: card.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (card.subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        card.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _getDestination(String key, bool isConnected) {
    switch (key) {
      case 'training':
        return const TrainingView();
      case 'songs':
        return const SongView();
      case 'my drum':
        return isConnected ? const DrumAdjustment() : const FindDevicesView();
      case 'beat maker':
        return const BeatMakerView();
      case 'settings':
        return const SettingView();
      case 'my beats':
        return const MyBeatsView();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleTap(
    BuildContext context,
    String key,
    bool isConnected,
    Widget destination,
  ) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: key.replaceAll(' ', '_'));
      if (!context.mounted) return;

      if (!isConnected && key == 'songs') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdView(
              onAdFinished: () async {
                if (!context.mounted) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SongView()),
                );
              },
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      }
    } catch (e, st) {
      debugPrint('Navigation error: $e\n$st');
    }
  }
}

class _CardData {
  const _CardData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.emoji,
  });

  final String key;
  final String title;
  final String subtitle;
  final Color color;
  final String emoji;
}
