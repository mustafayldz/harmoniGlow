import 'dart:async';
// import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/screens/setting/drum_model.dart';
import 'package:harmoniglow/shared/send_data.dart';

import 'package:harmoniglow/blocs/device/device_event.dart';
import 'package:harmoniglow/blocs/device/device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  DeviceBloc() : super(DeviceState()) {
    on<StartSendingEvent>(_onStartSending);
    on<PauseSendingEvent>(_onPauseSending);
    on<StopSendingEvent>(_onStopSending);
    on<UpdateBeatDataEvent>(_onUpdateBeatData);
  }

  Future<void> _onUpdateBeatData(
    UpdateBeatDataEvent event,
    Emitter<DeviceState> emit,
  ) async {
    emit(
      state.copyWith(
        trainModel: event.beatData,
        startIndex: 0,
        isSending: false,
        playbackState: PlaybackState.stopped,
      ),
    );
  }

  Future<void> _onStartSending(
    StartSendingEvent event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      if (state.playbackState == PlaybackState.playing) {
        // Pause the playback if already playing
        emit(
          state.copyWith(
            playbackState: PlaybackState.paused,
            isSending: false,
            trainModel: state.trainModel,
            startIndex: state.startIndex,
          ),
        );
        return;
      }

      // Update state to indicate that we are starting or resuming playback
      final updatedState = state.copyWith(
        trainModel: state.trainModel, // Ensure trainModel is retained
        playbackState: PlaybackState.playing,
        isSending: true,
      );
      emit(updatedState);

      // Await the message sending and handle potential errors
      await _sendMessage(event, emit);
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
    PauseSendingEvent event,
    Emitter<DeviceState> emit,
  ) async {
    emit(
      state.copyWith(
        playbackState: PlaybackState.paused,
        startIndex: state.startIndex,
        isSending: false,
        trainModel: state.trainModel,
      ),
    );
  }

  Future<void> _onStopSending(
    StopSendingEvent event,
    Emitter<DeviceState> emit,
  ) async {
    final bluetoothBloc = event.context.read<BluetoothBloc>();

    await SendData().sendHexData(bluetoothBloc, [0x00]);

    emit(
      state.copyWith(
        playbackState: PlaybackState.stopped,
        isSending: false,
        startIndex: 0,
        trainModel: state.trainModel,
      ),
    );
  }

  Future<void> _sendMessage(
    StartSendingEvent event,
    Emitter<DeviceState> emit,
  ) async {
    final bluetoothBloc = event.context.read<BluetoothBloc>();

    final int bpm = state.trainModel?.bpm ?? 60;
    final int timeInterval = (60000 ~/ bpm); // her vuruş arası süre
    int startIndex = state.startIndex != 0 ? state.startIndex : 0;

    do {
      for (int index = startIndex;
          index < (state.trainModel?.notes?.length ?? 0);
          index++) {
        if (state.playbackState != PlaybackState.playing) {
          return;
        }

        final note = state.trainModel!.notes![index];
        final List<int> data = [];

        for (int drumPart in note) {
          if (drumPart <= 0 || drumPart > 8) continue;

          final DrumModel? drum =
              await StorageService.getDrumPart(drumPart.toString());
          if (drum == null || drum.led == null || drum.rgb == null) continue;

          data.add(drum.led!);
          data.addAll(drum.rgb!);
        }

        if (data.isNotEmpty) {
          await SendData().sendHexData(bluetoothBloc, data);
        }

        emit(
          state.copyWith(
            playbackState: state.playbackState,
            isSending: state.isSending,
            startIndex: index,
            trainModel: state.trainModel,
          ),
        );

        await Future.delayed(Duration(milliseconds: timeInterval));
      }

      startIndex = 0;
    } while (event.isTest);

    await SendData().sendHexData(bluetoothBloc, [0x00]);

    emit(
      state.copyWith(
        playbackState: PlaybackState.stopped,
        isSending: false,
        trainModel: state.trainModel,
        startIndex: 0,
        connected: true,
      ),
    );
  }
}
