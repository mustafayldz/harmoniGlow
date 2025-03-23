import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/screens/bluetooth/find_devices.dart';
import 'package:harmoniglow/screens/setting/drum_adjustment.dart';
import 'package:harmoniglow/screens/shuffle/shuffle_mode.dart';
import 'package:harmoniglow/screens/songs/songs.dart';
import 'package:harmoniglow/screens/training/traning_page.dart';

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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final List<_CardData> _cards = const [
    _CardData(
      title: 'Training',
      subtitle: 'Train with your own music',
      backgroundColor: Colors.greenAccent,
      emoji: '🎧',
      destination: TrainingPage(),
    ),
    _CardData(
      title: 'Songs',
      subtitle: 'Discover and train with your favorite songs',
      backgroundColor: Colors.pinkAccent,
      emoji: '🎵',
      destination: SongPage(),
    ),
    _CardData(
      title: 'Shuffle Mode',
      subtitle: 'Train with random music types',
      backgroundColor: Colors.orangeAccent,
      emoji: '🔀',
      destination: ShuffleMode(),
    ),
    _CardData(
      title: 'Settings',
      subtitle: '',
      backgroundColor: Colors.blueAccent,
      emoji: '⚙️',
      destination: DrumAdjustment(),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildConnectionStatus(context),
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
                              offset:
                                  Offset(0, -15.0 * index), // stacked effect
                              child: child,
                            ),
                          ),
                        ),
                        child: _buildHabitCard(
                          context,
                          title: card.title,
                          subtitle: card.subtitle,
                          backgroundColor: card.backgroundColor,
                          emoji: card.emoji,
                          destination: card.destination,
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

  Widget _buildConnectionStatus(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;

    final isConnected = state.isConnected;
    final deviceName = state.connectedDevice?.advName ?? 'Unknown Device';

    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FindDevicesScreen()),
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
              isConnected ? 'Connected to $deviceName' : 'Disconnected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isConnected ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required String emoji,
    required Widget destination,
  }) =>
      GestureDetector(
        onTap: () {
          FirebaseAnalytics.instance.logEvent(name: title);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
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
    required this.destination,
  });
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final String emoji;
  final Widget destination;
}
