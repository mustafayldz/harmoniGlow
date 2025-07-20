import 'dart:async';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/player/drum_part_badge.dart';
import 'package:drumly/screens/player/player_shared.dart';
import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class PlayerView extends StatefulWidget {
  const PlayerView(this.songModel, {super.key, this.hideTimeControls = false});
  final TraningModel songModel;
  final bool
      hideTimeControls; // Süre göstergesi ve progress bar'ı gizlemek için

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  final AudioPlayer _player = AudioPlayer();
  late AppProvider appProvider;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double playerSpeed = 1.0;

  Color? turtleColor;
  Color? rabbitColor;

  bool showSpeedText = false;
  Timer? _speedTextTimer;

  late final StreamSubscription<PlayerState> _playerStateSub;
  List<int> curretnData = [];
  final Set<int> _sentNoteIndices = {};
  static const int baseLedDuration = 100;
  final List<String> sentDrumParts = [];
  Color rondomColor = Colors.black;
  Duration prevPos = Duration.zero;

  @override
  void initState() {
    super.initState();
    appProvider = Provider.of<AppProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAudio();
    });
  }

  Future<void> _initAudio() async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: widget.songModel.title!);

      _playerStateSub = _player.playerStateStream.listen((_) {
        if (mounted) setState(() {});
      });

      await _player.setUrl(widget.songModel.fileUrl!);
      _duration = _player.duration ?? Duration.zero;

      if (mounted) setState(() {});
      _listenPosition();

      _player.processingStateStream.listen((state) async {
        if (state == ProcessingState.completed) {
          // Şarkı bitti - loop yapmak yerine durdur
          await _player.seek(Duration.zero);
          setState(() {
            prevPos = Duration.zero;
            _sentNoteIndices.clear();
          });
          // await _player.play(); // Bu satırı kaldırarak loop'u durdur
        }
      });
    } catch (e, stack) {
      debugPrint('Audio load error: $e\n$stack');
    }
  }

  void _listenPosition() {
    final bluetoothBloc = context.read<BluetoothBloc>();

    _player
        .createPositionStream(minPeriod: const Duration(milliseconds: 10))
        .listen((pos) async {
      if (!mounted) return;

      for (var note in widget.songModel.notes!) {
        final idx = note.i;
        final start = Duration(milliseconds: note.sM);

        if (prevPos < start &&
            pos >= start &&
            !_sentNoteIndices.contains(idx)) {
          _sentNoteIndices.add(idx);

          curretnData.clear();
          sentDrumParts.clear();

          for (int drumPart in note.led) {
            if (drumPart <= 0 || drumPart > 8) continue;
            final drum = await StorageService.getDrumPart(drumPart.toString());
            if (drum?.led == null || drum?.rgb == null) continue;
            sentDrumParts.add(drum!.name!);
            curretnData.add(drum.led!);
            curretnData.addAll(drum.rgb!);
            rondomColor = getRandomColor(appProvider.isDarkMode);
          }

          debugPrint('► Note $idx triggered: $curretnData');
          await SendData().sendHexData(bluetoothBloc, curretnData);
        }
      }

      prevPos = pos;
      setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _player.stop();
    _speedTextTimer?.cancel();
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
    await _player.setSpeed(playerSpeed);
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
                height: screenSize.height * 0.05,
              ),
              sentDrumParts.isNotEmpty || _player.playing
                  ? DrumOverlayView(
                      selectedParts: sentDrumParts,
                      highlightColor: rondomColor,
                    )
                  : Lottie.asset(
                      'assets/animation/drummer.json',
                      fit: BoxFit.fitWidth,
                    ),
              const Spacer(),
              Text(
                widget.songModel.title ?? 'Unknown Title',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              if (!widget.hideTimeControls) // Süre kontrollerini gizle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Slider(
                        max: _duration.inSeconds.toDouble(),
                        value: _position.inSeconds
                            .clamp(0, _duration.inSeconds)
                            .toDouble(),
                        onChanged: (value) =>
                            _player.seek(Duration(seconds: value.toInt())),
                        allowedInteraction: SliderInteraction.tapAndSlide,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position)),
                          Text(_formatDuration(_duration)),
                        ],
                      ),
                    ],
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
                      onPressed: () => _onTurtlePressed(bluetoothBloc),
                      backgroundColor: turtleColor,
                    ),
                    controlButton(
                      icon: _player.playing ? Icons.pause : Icons.play_arrow,
                      onPressed: () async {
                        if (_player.playing) {
                          await _player.pause();
                          await SendData().sendHexData(bluetoothBloc, [0]);
                        } else {
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Countdown(),
                          );
                          if (mounted) await _player.play();
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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
