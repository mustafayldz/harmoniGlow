// Base event class

import 'package:flutter/material.dart';
import 'package:harmoniglow/screens/songs/songs_model.dart';

abstract class DeviceEvent {}

// Event for starting data sending
class StartSendingEvent extends DeviceEvent {
  StartSendingEvent(this.context, this.isTest);
  final BuildContext context;
  final bool isTest;
}

// Event for pausing data sending
class PauseSendingEvent extends DeviceEvent {}

// Event for stopping data sending
class StopSendingEvent extends DeviceEvent {
  StopSendingEvent(this.context);
  final BuildContext context;
}

class UpdateBeatDataEvent extends DeviceEvent {
  UpdateBeatDataEvent(this.beatData);
  final SongModel beatData;
}
