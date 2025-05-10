import 'dart:async';
import 'dart:math';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/mock_service/local_service.dart';
import 'package:drumly/screens/songs/songs_model.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  int _currentMs = 0;
  int _prevMs = 0;
  double playerSpeed = 1.0;
  static const int baseLedDuration = 100; // ms at 1× speed

  // Note‑trigger state
  final Set<int> _sentNoteIndices = {};
  final List<int> _currentData = [];
  final List<String> _sentDrumParts = [];
  Color _randomColor = Colors.black;

  @override
  void initState() {
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
        _randomColor = _pickRandomDarkColor();

        // send over Bluetooth
        await SendData().sendHexData(bluetoothBloc, _currentData);
      }
    }

    if (mounted) setState(() {});
  }

  Color _pickRandomDarkColor() {
    Color c;
    do {
      c = Color.fromARGB(
        255,
        Random().nextInt(256),
        Random().nextInt(256),
        Random().nextInt(256),
      );
    } while (c.computeLuminance() > 0.3);
    return c;
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerValueChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1️⃣ Video player
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
            ),

            const Spacer(),

            // 2️⃣ Display triggered drum parts
            if (_sentDrumParts.isNotEmpty)
              Center(
                child: Text(
                  _sentDrumParts.join(', '),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _randomColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // 3️⃣ Basic play / pause buttons
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(Icons.remove_circle_outline, () async {
                    playerSpeed = (playerSpeed - 0.25).clamp(0.25, 2.0);
                    await _applySpeedAndReset(bluetoothBloc, playerSpeed);
                  }),
                  _controlButton(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    () async {
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
                  _controlButton(Icons.add_circle, () async {
                    playerSpeed = (playerSpeed + 0.25).clamp(0.25, 2.0);
                    await _applySpeedAndReset(bluetoothBloc, playerSpeed);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applySpeedAndReset(
    BluetoothBloc bluetoothBloc,
    double newSpeed,
  ) async {
    _controller.pause();

    _controller.setPlaybackRate(newSpeed);

    final int ledDuration = (baseLedDuration / newSpeed).round();

    await SendData().sendHexData(bluetoothBloc, splitToBytes(ledDuration));
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
}
