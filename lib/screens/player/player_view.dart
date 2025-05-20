import 'dart:async';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/player/volume.dart';
import 'package:drumly/screens/training/trraning_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class PlayerView extends StatefulWidget {
  const PlayerView(this.songModel, {super.key, this.isTraning = false});
  final bool isTraning;
  final TraningModel songModel;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  final AudioPlayer _player = AudioPlayer();
  late AppProvider appProvider;
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

  // // ➎ check thme dark mode
  // bool isDark = false;

  @override
  void initState() {
    super.initState();
    appProvider = Provider.of<AppProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAudio(context);
    });
  }

  Future<void> _initAudio(BuildContext context) async {
    try {
      // ➊ Firebase Analytics
      await FirebaseAnalytics.instance.logEvent(name: widget.songModel.title!);

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
            rondomColor = getRandomColor(appProvider.isDarkMode);
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
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          sentDrumParts.join(', '),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: rondomColor,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    )
                  : Image.asset(
                      'assets/images/drumly_logo.png',
                      fit: BoxFit.cover,
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
            VolumeButtons(player: _player),
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
}
