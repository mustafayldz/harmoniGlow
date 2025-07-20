import 'dart:async';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/player/drum_part_badge.dart';
import 'package:drumly/screens/player/player_shared.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class BeatMakerPlayerView extends StatefulWidget {
  const BeatMakerPlayerView(this.songModel, {super.key});
  final BeatMakerModel songModel;

  @override
  State<BeatMakerPlayerView> createState() => _BeatMakerPlayerViewState();
}

class _BeatMakerPlayerViewState extends State<BeatMakerPlayerView> {
  late AppProvider appProvider;
  late BluetoothBloc bluetoothBloc;

  final List<String> _currentDrumParts = [];
  final List<int> _currentLedData = [];
  final Set<int> _sentNoteIndices = {};
  Duration _prevTime = Duration.zero;
  Timer? _timer;
  int _msCounter = 0;
  bool _isPlaying = false;
  double playerSpeed = 1.0;

  bool showSpeedText = false;
  Timer? _speedTextTimer;
  Color? turtleColor;
  Color? rabbitColor;

  Color _randomColor = Colors.black;

  static const int ledDuration = 200; // Default LED duration in milliseconds

  @override
  void initState() {
    super.initState();
    appProvider = Provider.of<AppProvider>(context, listen: false);
    bluetoothBloc = context.read<BluetoothBloc>();
    _updateButtonColors();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speedTextTimer?.cancel();
    super.dispose();
  }

  void _startNoteSync() {
    _timer = Timer.periodic(Duration(milliseconds: (10 / playerSpeed).round()),
        (_) async {
      if (!mounted || !_isPlaying) return;

      for (var note in widget.songModel.notes ?? []) {
        final idx = note.i;
        final start = Duration(milliseconds: note.sM);

        if (_prevTime < start &&
            Duration(milliseconds: _msCounter) >= start &&
            !_sentNoteIndices.contains(idx)) {
          _sentNoteIndices.add(idx);

          _currentDrumParts.clear();
          _currentLedData.clear();

          for (int drumPart in note.led) {
            if (drumPart <= 0 || drumPart > 8) continue;
            final drum = await StorageService.getDrumPart(drumPart.toString());
            if (drum?.led == null || drum?.rgb == null) continue;
            _currentDrumParts.add(drum!.name!);
            _currentLedData.add(drum.led!);
            _currentLedData.addAll(drum.rgb!);
          }

          _randomColor = getRandomColor(appProvider.isDarkMode);

          if (_currentLedData.isNotEmpty) {
            await SendData().sendHexData(bluetoothBloc, _currentLedData);
            if (mounted) setState(() {});
          }
        }
      }

      _prevTime = Duration(milliseconds: _msCounter);
      _msCounter += 10;
    });
  }

  void _updateButtonColors() {
    setState(() {
      turtleColor = null;
      rabbitColor = null;
      if (playerSpeed == 0.5) {
        turtleColor = Colors.deepPurple[900];
      } else if (playerSpeed == 0.75) {
        turtleColor = Colors.deepPurple[300];
      } else if (playerSpeed == 1.25) {
        rabbitColor = Colors.deepPurple[300];
      } else if (playerSpeed == 1.5) {
        rabbitColor = Colors.deepPurple[900];
      }
    });
  }

  void _showSpeedTextTemporarily() {
    setState(() => showSpeedText = true);
    _speedTextTimer?.cancel();
    _speedTextTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => showSpeedText = false);
    });
  }

  void _onTurtlePressed() async {
    if (playerSpeed > 0.5) {
      playerSpeed = (playerSpeed - 0.25).clamp(0.5, 1.5);
      await _applySpeedAndReset();
    }
  }

  void _onRabbitPressed() async {
    if (playerSpeed < 1.5) {
      playerSpeed = (playerSpeed + 0.25).clamp(0.5, 1.5);
      await _applySpeedAndReset();
    }
  }

  Future<void> _applySpeedAndReset() async {
    await SendData().sendHexData(bluetoothBloc, splitToBytes(ledDuration));
    _updateButtonColors();
    _showSpeedTextTemporarily();
    _timer?.cancel();
    if (_isPlaying) _startNoteSync();
  }

  Widget _controlButton(
    IconData icon,
    VoidCallback onPressed, {
    double iconSize = 32,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, size: iconSize, color: Colors.black),
          onPressed: onPressed,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Column(
            children: [
              SizedBox(
                height: screenSize.height * 0.1,
              ),
              _currentDrumParts.isNotEmpty || _isPlaying
                  ? DrumOverlayView(
                      selectedParts: _currentDrumParts,
                      highlightColor: _randomColor,
                    )
                  : Lottie.asset(
                      'assets/animation/drummer.json',
                      fit: BoxFit.fitWidth,
                    ),
              const Spacer(),
              Text(
                widget.songModel.title ?? 'Unknown Title',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: screenSize.height * 0.05,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    controlButton(
                      imagePath: 'assets/images/icons/turtle.png',
                      onPressed: _onTurtlePressed,
                      backgroundColor: turtleColor,
                    ),
                    _controlButton(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      () async {
                        setState(() => _isPlaying = !_isPlaying);
                        if (_isPlaying) {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Countdown(),
                          ).whenComplete(() => _startNoteSync());
                        } else {
                          _timer?.cancel();
                        }
                      },
                      iconSize: 52,
                    ),
                    controlButton(
                      imagePath: 'assets/images/icons/rabbit.png',
                      onPressed: _onRabbitPressed,
                      backgroundColor: rabbitColor,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: screenSize.height * 0.05,
              ),
            ],
          ),
          if (showSpeedText)
            Positioned(
              bottom: 140,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Speed: ${playerSpeed.toStringAsFixed(2)}x',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
