// Base event class

import 'package:flutter/material.dart';
import 'package:harmoniglow/models/traning_model.dart';

abstract class DeviceEvent {}

// Event for starting data sending
class StartSendingEvent extends DeviceEvent {
  final BuildContext context;
  final bool isTest;

  StartSendingEvent(this.context, this.isTest);
}

// Event for pausing data sending
class PauseSendingEvent extends DeviceEvent {}

// Event for stopping data sending
class StopSendingEvent extends DeviceEvent {
  final BuildContext context;

  StopSendingEvent(this.context);
}

class UpdateBeatDataEvent extends DeviceEvent {
  final TraningModel beatData;
  UpdateBeatDataEvent(this.beatData);
}
