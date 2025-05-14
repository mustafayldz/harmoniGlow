import 'dart:async';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/myDrum/drum_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class BeatMakerViewmodel {
  final StorageService storageService = StorageService();

  final Map<String, String> drumSounds = {
    'Hi-Hat': 'assets/sounds/open_hihat.wav',
    'Crash Cymbal': 'assets/sounds/crash_2.wav',
    'Ride Cymbal': 'assets/sounds/ride_1.wav',
    'Snare Drum': 'assets/sounds/snare_hard.wav',
    'Tom 1': 'assets/sounds/tom_1.wav',
    'Tom 2': 'assets/sounds/tom_2.wav',
    'Tom Floor': 'assets/sounds/tom_floor.wav',
    'Kick Drum': 'assets/sounds/kick.wav',
  };

  final Map<String, AudioPlayer> _players =
      {}; // Her parça için bir player saklanır

  Future<void> playSound(BuildContext context, String drumPart) async {
    final path = drumSounds[drumPart];
    if (path == null) return;

    print('Playing sound for $drumPart: $path');

    // Player varsa al, yoksa oluştur ve sakla
    final player = _players.putIfAbsent(drumPart, () => AudioPlayer());

    try {
      // Çalmadan önce sıfırla
      await player.stop();
      await player.setAsset(path);
      await sendLighttoDevice(context, drumPart, context.read<BluetoothBloc>());
      await player.play();
    } catch (e) {
      debugPrint('Error playing $drumPart: $e');
    }
  }

  // Uygulama kapanırken veya işin bittiğinde tüm player'ları temizle
  Future<void> disposeAll() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }

  Future<void> sendLighttoDevice(
    BuildContext context,
    String drumPart,
    BluetoothBloc bluetoothBloc,
  ) async {
    final bluetoothBloc = context.read<BluetoothBloc>();

    // Drum partına göre LED değerini belirle
    final DrumModel? model =
        await StorageService.getDrumPart(getDrumPartId(drumPart).toString());

    print('Drum part: $drumPart');
    print('Model: $model');
    print('ID: ${model?.name}');
    print('LED: ${model?.led}');
    print('RGB: ${model?.rgb}');

    final List<int> data = [model!.led!, ...model.rgb!];
    await SendData().sendHexData(bluetoothBloc, data);
  }
}
