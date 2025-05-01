import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/device/device_bloc.dart';
import 'package:harmoniglow/blocs/device/device_event.dart';
import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/screens/songs/songs_model.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:just_audio/just_audio.dart';

class PlayerView extends StatefulWidget {
  const PlayerView(this.songModel, {super.key});
  final SongModel songModel;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  late final StreamSubscription<PlayerState> _playerStateSub;
  late final StreamSubscription<Duration> _positionSub;

  PlaybackState playbackState = PlaybackState.stopped;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // 1) PlayerState akışını dinle
      _playerStateSub = _player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          // state’e bağlı UI güncellemesi
        });
      });

      // 2) URL’i yükle
      await _player.setUrl(widget.songModel.fileUrl!);
      _duration = _player.duration ?? Duration.zero;
      if (mounted) setState(() {});

      // 3) Position akışını dinle
      _positionSub = _player.positionStream.listen((pos) {
        if (!mounted) return;
        print('position: $pos');
        setState(() {
          // position’a bağlı UI güncellemesi
          _position = pos;
        });
      });
    } catch (e, stack) {
      debugPrint('Audio load hata: $e\n$stack');
    }
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _positionSub.cancel();
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
    final deviceBloc = context.read<DeviceBloc>();
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
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: _controlButton(
                  _player.playing ? Icons.pause : Icons.play_arrow, () async {
                if (_player.playing) {
                  await _player.pause();
                  pause(deviceBloc);
                } else {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Countdown(),
                  ).whenComplete(() {
                    if (mounted) {
                      _player.play();
                      play(context, deviceBloc);
                    }
                  });
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> play(
    BuildContext context,
    DeviceBloc deviceBloc,
  ) async {
    if (widget.songModel.notes!.isEmpty) return;
    playbackState = PlaybackState.playing;
    deviceBloc.add(StartSendingEvent(context, false));
  }

  void pause(
    DeviceBloc deviceBloc,
  ) {
    if (playbackState == PlaybackState.playing) {
      playbackState = PlaybackState.paused;
      deviceBloc.add(PauseSendingEvent());
    }
  }
}
