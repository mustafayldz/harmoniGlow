import 'package:drumly/adMob/ad_service.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/mock_service/local_service.dart';
import 'package:drumly/screens/bluetooth/find_devices.dart';
import 'package:drumly/screens/myDrum/drum_adjustment.dart';
import 'package:drumly/screens/myDrum/drum_model.dart';
import 'package:drumly/screens/settings/setting_view.dart';
import 'package:drumly/screens/songs/song_view_new.dart';
import 'package:drumly/screens/training/traning_view.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    checkLocalStorage();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  checkLocalStorage() async {
    final savedData = await StorageService.getDrumPartsBulk();
    if (savedData == null) {
      await StorageService.saveDrumPartsBulk(
        DrumParts.drumParts.entries
            .map((e) => DrumModel.fromJson(e.value))
            .toList(),
      );
    }
  }

  final List<_CardData> _cards = const [
    _CardData(
      title: 'Training',
      subtitle: 'Train with your own music',
      backgroundColor: Colors.greenAccent,
      emoji: '🥁',
    ),
    _CardData(
      title: 'Songs',
      subtitle: 'Discover and train with your favorite songs',
      backgroundColor: Colors.pinkAccent,
      emoji: '🎤',
    ),
    _CardData(
      title: 'MY DRUM',
      subtitle: 'Adjust your drum settings',
      backgroundColor: Colors.blueAccent,
      emoji: '🥁',
    ),
    _CardData(
      title: 'Settings',
      subtitle: '',
      backgroundColor: Colors.blueAccent,
      emoji: '⚙️',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;

    final isConnected = state.isConnected;
    final deviceName = state.connectedDevice?.advName ?? 'Unknown Device';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FindDevicesScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected ? Colors.green : Colors.red,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth_disabled,
                        color: isConnected ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isConnected
                            ? 'Connected to $deviceName'
                            : 'Disconnected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              isConnected ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Opacity(
                        opacity: _opacity.value,
                        child: SlideTransition(
                          position: _slide,
                          child: Transform.translate(
                            offset: Offset(0, -15.0 * index), // stacked effect
                            child: child,
                          ),
                        ),
                      ),
                      child: _buildHabitCard(
                        context,
                        isConnected,
                        title: card.title,
                        subtitle: card.subtitle,
                        backgroundColor: card.backgroundColor,
                        emoji: card.emoji,
                        destination: getDestination(
                          card.title,
                          isConnected,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getDestination(String title, bool isConnected) {
    switch (title) {
      case 'Training':
        return const TrainingView();
      case 'Songs':
        return const SongView();
      case 'MY DRUM':
        return isConnected ? const DrumAdjustment() : const FindDevicesScreen();
      case 'Settings':
        return const SettingView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHabitCard(
    BuildContext context,
    bool isConnected, {
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required String emoji,
    required Widget destination,
  }) =>
      GestureDetector(
        onTap: () async {
          print("TAP: $title");

          try {
            debugPrint('Tapped: $title');
            await FirebaseAnalytics.instance.logEvent(name: title);

            // If not connected and tapping “Songs”, show an interstitial ad first
            if (!isConnected && title == 'Songs') {
              await AdService.instance.showInterstitialAd();
            }

            // Decide which screen to push:
            final Widget screenToPush = !isConnected && title == 'MY DRUM'
                ? const FindDevicesScreen() // otherwise, go to pairing
                : destination; // connected or post‐ad “Songs”

            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screenToPush),
            );
          } catch (e, st) {
            debugPrint('Navigation error: $e\n$st');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          subtitle,
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
        ),
      );
}

class _CardData {
  const _CardData({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.emoji,
  });
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final String emoji;
}
