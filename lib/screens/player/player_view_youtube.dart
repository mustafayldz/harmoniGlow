import 'dart:async';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/player/drum_part_badge.dart';
import 'package:drumly/screens/player/player_shared.dart';
import 'package:drumly/screens/songs/songs_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeSongPlayer extends StatefulWidget {
  const YoutubeSongPlayer({
    required this.song,
    super.key,
  });

  final SongModel song;

  @override
  YoutubeSongPlayerState createState() => YoutubeSongPlayerState();
}

class YoutubeSongPlayerState extends State<YoutubeSongPlayer> {
  late final YoutubePlayerController _controller;
  late AppProvider appProvider;

  int _currentMs = 0;
  int _prevMs = 0;
  double playerSpeed = 1.0;
  static const int baseLedDuration = 100; // ms at 1× speed

  // Note‑trigger state
  final Set<int> _sentNoteIndices = {};
  final List<int> _currentData = [];
  final List<String> _sentDrumParts = [];
  Color _randomColor = Colors.black;

  Color? turtleColor;
  Color? rabbitColor;

  bool showSpeedText = false;
  Timer? _speedTextTimer;

  @override
  void initState() {
    appProvider = Provider.of<AppProvider>(context, listen: false);
    super.initState();

    // Extract the video ID from URL (or assume URL is already the ID)
    final vid = YoutubePlayer.convertUrlToId(widget.song.fileUrl!) ??
        widget.song.fileUrl!;
    _controller = YoutubePlayerController(
      initialVideoId: vid,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        hideControls: true,
        disableDragSeek: true,
      ),
    );

    // Listen for every frame update
    _controller.addListener(() {
      // rebuild whenever anything about the player changes:
      setState(() {});
      _onPlayerValueChange();
    });
  }

  void _onPlayerValueChange() {
    final pos = _controller.value.position.inMilliseconds;
    if (pos == _currentMs) return;

    _currentMs = pos;
    _processPosition(_currentMs);
    _prevMs = _currentMs;
  }

  Future<void> _processPosition(int ms) async {
    final bluetoothBloc = context.read<BluetoothBloc>();

    for (final note in widget.song.notes!) {
      final idx = note.i;
      final startMs = note.sM;

      if (_prevMs < startMs &&
          ms >= startMs &&
          !_sentNoteIndices.contains(idx)) {
        // mark it sent
        _sentNoteIndices.add(idx);

        // prepare data
        _currentData.clear();
        _sentDrumParts.clear();
        for (final drumPart in note.led) {
          if (drumPart < 1 || drumPart > 8) continue;
          final drum = await StorageService.getDrumPart(drumPart.toString());
          if (drum?.led == null || drum?.rgb == null) continue;
          _sentDrumParts.add(drum!.name!);
          _currentData.add(drum.led!);
          _currentData.addAll(drum.rgb!);
        }
        _randomColor = getRandomColor(appProvider.isDarkMode);

        // send over Bluetooth
        await SendData().sendHexData(bluetoothBloc, _currentData);
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerValueChange);
    _controller.dispose();
    super.dispose();
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

  void _onTurtlePressed(BluetoothBloc bluetoothBloc) async {
    if (playerSpeed > 0.5) {
      playerSpeed = (playerSpeed - 0.25).clamp(0.5, 1.5);
      await _applySpeedAndReset(bluetoothBloc);
      _updateButtonColors();
      _showSpeedTextTemporarily();
    }
  }

  void _onRabbitPressed(BluetoothBloc bluetoothBloc) async {
    if (playerSpeed < 1.5) {
      playerSpeed = (playerSpeed + 0.25).clamp(0.5, 1.5);
      await _applySpeedAndReset(bluetoothBloc);
      _updateButtonColors();
      _showSpeedTextTemporarily();
    }
  }

  Future<void> _applySpeedAndReset(BluetoothBloc bluetoothBloc) async {
    _controller.pause();
    _controller.setPlaybackRate(playerSpeed);
    final int ledDuration = (baseLedDuration / playerSpeed).round();
    await SendData().sendHexData(bluetoothBloc, splitToBytes(ledDuration));
    _updateButtonColors();
    _showSpeedTextTemporarily();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bluetoothBloc = context.read<BluetoothBloc>();
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            children: [
              SizedBox(
                height: screenSize.height * 0.04,
              ),

              // 1️⃣ Display triggered drum parts
              _sentDrumParts.isNotEmpty || _controller.value.isPlaying
                  ? DrumOverlayView(
                      selectedParts: _sentDrumParts,
                      highlightColor: _randomColor,
                    )
                  : Lottie.asset(
                      'assets/animation/drummer.json',
                      fit: BoxFit.fitWidth,
                    ),

              const Spacer(),

              // 2️⃣ Video player
              SizedBox(
                height: screenSize.height * 0.15,
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                ),
              ),

              SizedBox(
                height: screenSize.height * 0.05,
              ),

              // 3️⃣ Basic play / pause buttons

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    controlButton(
                      imagePath: 'assets/images/icons/turtle.png',
                      onPressed: () => _onTurtlePressed(bluetoothBloc),
                      backgroundColor: turtleColor,
                    ),
                    controlButton(
                      icon: _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      onPressed: () async {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                          await SendData().sendHexData(bluetoothBloc, [0]);
                        } else {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Countdown(),
                          ).whenComplete(() async {
                            if (mounted) {
                              _controller.play();
                            }
                          });
                        }
                      },
                      iconSize: 52,
                    ),
                    controlButton(
                      imagePath: 'assets/images/icons/rabbit.png',
                      onPressed: () => _onRabbitPressed(bluetoothBloc),
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
