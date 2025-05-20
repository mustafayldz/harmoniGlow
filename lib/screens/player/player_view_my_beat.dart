import 'dart:async';

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/countdown.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BeatMakerPlayerView extends StatefulWidget {
  const BeatMakerPlayerView(this.songModel, {super.key});
  final BeatMakerModel songModel;

  @override
  State<BeatMakerPlayerView> createState() => _BeatMakerPlayerViewState();
}

class _BeatMakerPlayerViewState extends State<BeatMakerPlayerView> {
  final List<String> _currentDrumParts = [];
  final List<int> _currentLedData = [];
  final Set<int> _sentNoteIndices = {};
  Duration _prevTime = Duration.zero;
  Timer? _timer;
  int _msCounter = 0;
  bool _isPlaying = false;
  double playerSpeed = 1.0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNoteSync() {
    final bluetoothBloc = context.read<BluetoothBloc>();
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

  Future<void> _applySpeedAndReset(double newSpeed) async {
    setState(() {
      playerSpeed = newSpeed;
      _timer?.cancel();
      _startNoteSync();
    });
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            SizedBox(
              height: size.height * 0.3,
              child: _currentDrumParts.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          _currentDrumParts.join(', '),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(Icons.remove_circle_outline, () async {
                    playerSpeed = (playerSpeed - 0.25).clamp(0.25, 2.0);
                    await _applySpeedAndReset(playerSpeed);
                  }),
                  _controlButton(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    () async {
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                      if (_isPlaying) {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Countdown(),
                        ).whenComplete(() async {
                          _startNoteSync();
                        });
                      }
                    },
                    iconSize: 52,
                  ),
                  _controlButton(Icons.add_circle, () async {
                    playerSpeed = (playerSpeed + 0.25).clamp(0.25, 2.0);
                    await _applySpeedAndReset(playerSpeed);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
