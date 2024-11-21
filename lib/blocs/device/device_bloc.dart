import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/constants.dart';
import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/models/drum_model.dart';

import 'device_event.dart';
import 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  DeviceBloc() : super(DeviceState()) {
    on<StartSendingEvent>(_onStartSending);
    on<PauseSendingEvent>(_onPauseSending);
    on<StopSendingEvent>(_onStopSending);
    on<UpdateBeatDataEvent>(_onUpdateBeatData);
  }

  Future<void> _onUpdateBeatData(
      UpdateBeatDataEvent event, Emitter<DeviceState> emit) async {
    emit(state.copyWith(
        trainModel: event.beatData,
        startIndex: 0,
        isSending: false,
        playbackState: PlaybackState.stopped));
  }

  Future<void> _onStartSending(
      StartSendingEvent event, Emitter<DeviceState> emit) async {
    try {
      if (state.playbackState == PlaybackState.playing) {
        // Pause the playback if already playing
        emit(state.copyWith(
            playbackState: PlaybackState.paused,
            isSending: false,
            trainModel: state.trainModel,
            startIndex: state.startIndex));
        return;
      }

      // Update state to indicate that we are starting or resuming playback
      final updatedState = state.copyWith(
          trainModel: state.trainModel, // Ensure trainModel is retained
          playbackState: PlaybackState.playing,
          isSending: true);
      emit(updatedState);

      // Await the message sending and handle potential errors
      await _sendMessage(event.context, emit);
    } catch (e) {
      // Revert the state if sending fails
      final revertedState = state.copyWith(
        trainModel: state.trainModel, // Ensure trainModel is retained
        playbackState: PlaybackState.stopped,
        isSending: false,
      );
      emit(revertedState);
      debugPrint('Emitting state after error occurred: $revertedState');
    }
  }

  Future<void> _onPauseSending(
      PauseSendingEvent event, Emitter<DeviceState> emit) async {
    emit(state.copyWith(
        playbackState: PlaybackState.paused,
        startIndex: state.startIndex,
        isSending: false,
        trainModel: state.trainModel));
  }

  Future<void> _onStopSending(
      StopSendingEvent event, Emitter<DeviceState> emit) async {
    final bluetoothBloc = event.context.read<BluetoothBloc>();

    Map<String, dynamic> batchMessage = {
      'notes': [99],
      'rgb': [
        [0, 0, 0]
      ],
    };

    final String jsonString = '${jsonEncode(batchMessage)}\n';
    final List<int> data = utf8.encode(jsonString);

    emit(state.copyWith(
      playbackState: PlaybackState.stopped,
      isSending: state.isSending,
      startIndex: 0,
      trainModel: state.trainModel,
    ));

    await _sendLongData(bluetoothBloc, data);
  }

  Future<void> _sendMessage(
      BuildContext context, Emitter<DeviceState> emit) async {
    final bluetoothBloc = context.read<BluetoothBloc>();

    int bpm = state.trainModel?.bpm ?? 60;
    int timeInterval = (60000 ~/ bpm);
    int startIndex = (state.startIndex != 0) ? state.startIndex : 0;

    for (int index = startIndex;
        index < (state.trainModel?.notes?.length ?? 0);
        index++) {
      if (state.playbackState != PlaybackState.playing) {
        return;
      }

      var note = state.trainModel!.notes![index];
      List<List<int>> rgbValues = [];

      // Iterate through each drum part in the current note
      for (int drumPart in note) {
        if (drumPart == 99) {
          // If the note is 99, set RGB to [0, 0, 0] (turn off the light)
          rgbValues.add([0, 0, 0]);
        } else {
          // Otherwise, fetch the RGB value from local storage
          String drumName =
              DrumParts.drumParts[drumPart.toString()]?['name'] as String;
          DrumModel? drumParta = await StorageService.getDrumPart(drumName);
          List<int> rgb = drumParta?.rgb ?? [0, 0, 0];
          rgbValues.add(rgb);
        }
      }

      Map<String, dynamic> batchMessage = {
        'notes': note,
        'rgb': rgbValues,
      };

      print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
      print(batchMessage);
      print("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");

      final String jsonString = '${jsonEncode(batchMessage)}\n';
      final List<int> data = utf8.encode(jsonString);

      emit(state.copyWith(
        playbackState: state.playbackState,
        isSending: state.isSending,
        startIndex: index,
        trainModel: state.trainModel,
      ));

      final startTime = DateTime.now();
      await _sendLongData(bluetoothBloc, data);
      final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;

      if (elapsedTime < timeInterval) {
        await Future.delayed(
            Duration(milliseconds: timeInterval - elapsedTime));
      }
    }

    emit(state.copyWith(
        playbackState: PlaybackState.stopped,
        isSending: false,
        trainModel: state.trainModel,
        startIndex: 0,
        connected: true));
  }

  Future<void> _sendLongData(BluetoothBloc bloc, List<int> data) async {
    final device = bloc.state.connectedDevice;
    int mtuSize = 20;
    try {
      mtuSize = await device!.mtu.first - 5;
    } catch (error) {
      debugPrint('Error fetching MTU size, using default 20 bytes: $error');
    }

    for (int offset = 0; offset < data.length; offset += mtuSize) {
      final int end =
          (offset + mtuSize < data.length) ? offset + mtuSize : data.length;
      final List<int> chunk = data.sublist(offset, end);

      try {
        // Ensure the characteristic supports writing
        if (bloc.state.characteristic!.properties.write) {
          await bloc.state.characteristic!.write(chunk);
          debugPrint('Chunk sent successfully, offset: $offset');
        } else {
          debugPrint('Error: Characteristic does not support writing.');
        }
      } catch (error) {
        debugPrint('Error sending chunk at offset $offset: $error');
      }
    }
  }
}
