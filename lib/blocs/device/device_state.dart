import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/screens/songs/songs_model.dart';

class DeviceState {
  DeviceState({
    this.playbackState = PlaybackState.stopped,
    this.startIndex = 0,
    this.isSending = false,
    this.trainModel,
  });
  final PlaybackState playbackState;
  final int startIndex;
  final bool isSending;
  final SongModel? trainModel;

  DeviceState copyWith({
    bool? connected,
    PlaybackState? playbackState,
    int? startIndex,
    bool? isSending,
    SongModel? trainModel,
  }) =>
      DeviceState(
        playbackState: playbackState ?? this.playbackState,
        startIndex: startIndex ?? this.startIndex,
        isSending: isSending ?? this.isSending,
        trainModel: trainModel,
      );
}
