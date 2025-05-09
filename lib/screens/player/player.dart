import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/player/volume.dart';
import 'package:harmoniglow/screens/songs/songs_model.dart';
import 'package:harmoniglow/shared/common_functions.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:harmoniglow/shared/send_data.dart';
import 'package:just_audio/just_audio.dart';

class PlayerView extends StatefulWidget {
  const PlayerView(this.songModel, {super.key, this.isTraning = false});
  final bool isTraning;
  final SongModel songModel;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double playerSpeed = 1.0;

  late final StreamSubscription<PlayerState> _playerStateSub;

  // ➊ Gönderilen not indekslerini tutacak set
  List<int> curretnData = [];
  Set<int> _sentNoteIndices = {};

  // ➋ ledlerin yanma suresini tutacak değişken
  int ledDuration = 100;
  static const int baseLedDuration = 100; // ms at 1× speed

  // ➌ gönderilen notların drum part’larını tutacak liste
  final List<String> sentDrumParts = [];
  Color rondomColor = Colors.black;

  // ➍ önceki pozisyonu tutacak değişken
  Duration prevPos = Duration.zero;
  Duration start = Duration.zero;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAudio(context);
    });
  }

  Future<void> _initAudio(BuildContext context) async {
    try {
      // 1) PlayerState akışını dinle
      _playerStateSub = _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {});
      });

      // 2) URL’i yükle
      await _player.setUrl(widget.songModel.fileUrl!);
      _duration = _player.duration ?? Duration.zero;
      if (mounted) setState(() {});

      // 3) Position akışını dinle
      _listenPosition();

      // 4) proccessing state’i dinle
      _player.processingStateStream.listen((state) async {
        if (state == ProcessingState.completed) {
          if (widget.isTraning) {
            await _player.seek(Duration.zero);
            setState(() {
              prevPos = Duration.zero;
              start = Duration.zero;
              _sentNoteIndices = {};
            });
            await _player.play();
          } else {
            await _player.seek(Duration.zero);
            await _player.stop();
            setState(() {
              prevPos = Duration.zero;
              start = Duration.zero;
              _sentNoteIndices = {};
              sentDrumParts.clear();
            });
          }
        }
      });
    } catch (e, stack) {
      debugPrint('Audio load hata: $e\n$stack');
    }
  }

  void _listenPosition() {
    final bluetoothBloc = context.read<BluetoothBloc>();

    _player
        .createPositionStream(minPeriod: const Duration(milliseconds: 10))
        .listen((pos) async {
      if (!mounted) {
        debugPrint('❌ PlayerView dispose edildi');
        return;
      }

      for (var note in widget.songModel.notes!) {
        final idx = note.i;
        start = Duration(milliseconds: note.sM);

        // ➋ Önceki pozisyon < start ≤ güncel pozisyon ve daha önce tetiklenmemişse
        if (prevPos < start &&
            pos >= start &&
            !_sentNoteIndices.contains(idx)) {
          // ➌ Bu not artık gönderildi
          _sentNoteIndices.add(idx);

          // ➍ curretnData’yı hazırla
          curretnData.clear();
          sentDrumParts.clear();
          for (int drumPart in note.led) {
            if (drumPart <= 0 || drumPart > 8) continue;
            final drum = await StorageService.getDrumPart(drumPart.toString());
            if (drum?.led == null || drum?.rgb == null) continue;
            sentDrumParts.add(drum!.name!);
            curretnData.add(drum.led!);
            curretnData.addAll(drum.rgb!);
            rondomColor = getRandomDarkColor();
          }

          // ➎ Veriyi Bluetooth üzerinden gönder
          debugPrint('► Note $idx tetiklendi: $curretnData');
          await SendData().sendHexData(bluetoothBloc, curretnData);
        }
      }

      // ➏ PrevPos’u güncelle ve UI’ı yenile
      prevPos = pos;
      if (mounted) {
        setState(() => _position = pos);
      }
    });
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _player.stop();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
    final Size size = MediaQuery.of(context).size;
    final bluetoothBloc = context.read<BluetoothBloc>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              height: size.height * 0.3,
              child: sentDrumParts.isNotEmpty
                  ? Center(
                      child: Text(
                        sentDrumParts.join(', '),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: rondomColor,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    )
                  : Container(
                      width: 200,
                      height: 200,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
            ),
            const Spacer(),
            Text(
              widget.songModel.title ?? 'Unknown Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.songModel.artist ?? 'Unknown Artist',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Slider(
                    max: _duration.inSeconds.toDouble(),
                    value: _position.inSeconds
                        .clamp(0, _duration.inSeconds)
                        .toDouble(),
                    onChanged: (value) {
                      _player.seek(Duration(seconds: value.toInt()));
                    },
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
            const SizedBox(height: 20),
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
                    _player.playing ? Icons.pause : Icons.play_arrow,
                    () async {
                      if (_player.playing) {
                        await _player.pause();
                        await SendData().sendHexData(bluetoothBloc, [0]);
                      } else {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Countdown(),
                        ).whenComplete(() async {
                          if (mounted) {
                            await _player.play();
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
            ModernVolumeButtons(player: _player),
          ],
        ),
      ),
    );
  }

  Future<void> _applySpeedAndReset(
    BluetoothBloc bluetoothBloc,
    double newSpeed,
  ) async {
    await _player.stop();

    await _player.setSpeed(newSpeed);

    final int ledDuration = (baseLedDuration / newSpeed).round();
    await SendData().sendHexData(bluetoothBloc, splitToBytes(ledDuration));
  }

  Color getRandomDarkColor() {
    Color color;
    do {
      color = Color.fromARGB(
        255,
        Random().nextInt(256), // Red 0–255
        Random().nextInt(256), // Green 0–255
        Random().nextInt(256), // Blue 0–255
      );
    } while (color.computeLuminance() > 0.3);
    return color;
  }
}
