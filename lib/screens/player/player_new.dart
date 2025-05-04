import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/songs/songs_model.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:harmoniglow/shared/send_data.dart';
import 'package:just_audio/just_audio.dart';

class PlayerViewNew extends StatefulWidget {
  const PlayerViewNew(this.songModel, {super.key});
  final SongModelNew songModel;

  @override
  State<PlayerViewNew> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerViewNew> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double playerSpeed = 1.0;

  late final StreamSubscription<PlayerState> _playerStateSub;
  // late final StreamSubscription<Duration> _positionSub;

  PlaybackState playbackState = PlaybackState.stopped;

  List<int> curretnData = [];

  // ➊ Gönderilen not indekslerini tutacak set
  final Set<int> _sentNoteIndices = {};

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
    } catch (e, stack) {
      debugPrint('Audio load hata: $e\n$stack');
    }
  }

  void _listenPosition() {
    final bluetoothBloc = context.read<BluetoothBloc>();
    Duration prevPos = Duration.zero;

    _player
        // ➊ Her 50ms’de bir pozisyon al
        .createPositionStream(minPeriod: const Duration(milliseconds: 50))
        .listen((pos) async {
      if (!mounted) return;

      for (var note in widget.songModel.notes!) {
        final idx = note.i;
        final start = Duration(milliseconds: note.sM);

        // ➋ Önceki pozisyon < start ≤ güncel pozisyon ve daha önce tetiklenmemişse
        if (prevPos < start &&
            pos >= start &&
            !_sentNoteIndices.contains(idx)) {
          // ➌ Bu not artık gönderildi
          _sentNoteIndices.add(idx);

          // ➍ curretnData’yı hazırla
          curretnData.clear();
          for (int drumPart in note.led) {
            if (drumPart <= 0 || drumPart > 8) continue;
            final drum = await StorageService.getDrumPart(drumPart.toString());
            if (drum?.led == null || drum?.rgb == null) continue;
            curretnData.add(drum!.led!);
            curretnData.addAll(drum.rgb!);
          }

          // ➎ Veriyi Bluetooth üzerinden gönder
          print('► Note $idx tetiklendi: $curretnData');
          await SendData().sendHexData(bluetoothBloc, curretnData);
        }
      }

      // ➏ PrevPos’u güncelle ve UI’ı yenile
      prevPos = pos;
      setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    // _positionSub.cancel();
    _player.stop();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _controlButton(IconData icon, VoidCallback onPressed) => Container(
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
          icon: Icon(icon, size: 32),
          onPressed: onPressed,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
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
            const SizedBox(height: 32),
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
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
            const Spacer(),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _controlButton(Icons.fast_rewind, () async {
                    if (playerSpeed < 0.5) playerSpeed = 0.5;
                    playerSpeed -= 0.5;
                    await _player.setSpeed(playerSpeed);
                  }),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _controlButton(
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
                  }),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _controlButton(Icons.fast_forward, () async {
                    if (playerSpeed > 2.0) playerSpeed = 2.0;
                    playerSpeed += 0.5;
                    await _player.setSpeed(playerSpeed);
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
