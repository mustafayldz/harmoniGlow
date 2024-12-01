import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/device/device_bloc.dart';
import 'package:harmoniglow/blocs/device/device_event.dart';
import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/mock_service/api_service.dart';
import 'package:harmoniglow/models/traning_model.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({
    super.key,
  });

  @override
  TrainingPageState createState() => TrainingPageState();
}

class TrainingPageState extends State<TrainingPage> {
  final MockApiService apiService = MockApiService();
  final AudioPlayer player = AudioPlayer();
  PlaybackState playbackState = PlaybackState.stopped;
  List<TraningModel>? beats = [];
  TraningModel? currentBeat;
  int currentBeatIndex = -1;
  List<String>? beatGenres;
  int selectedBeatGenreIndex = 0;
  bool isExpanded = false;

  int isPlayingIndex = -1;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    setBeat();
  }

  Future<void> setBeat() async {
    beats = await apiService.fetchAllBeats();
    beatGenres = apiService.fetchAllBeatGenres();
    setState(() {});
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> fetchBeat(int index) async {
    final deviceBloc = context.read<DeviceBloc>();
    playbackState = PlaybackState.stopped;

    try {
      final value = await apiService.fetchBeatData(beatIndex: index);
      setState(() {
        currentBeat = value;
        deviceBloc.add(UpdateBeatDataEvent(value));
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _togglePlayStop(int index) async {
    if (isPlaying) {
      setState(() {
        isPlaying = !isPlaying;
        isPlayingIndex = -1;
      });
      await player.stop();
      await player.seek(const Duration());
    } else {
      setState(() {
        isPlaying = !isPlaying;
        isPlayingIndex = index;
        isExpanded = true;
        currentBeatIndex = index;
      });
      await fetchBeat(index);
      await player.setUrl(currentBeat!.url!);
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceBloc = context.read<DeviceBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            // Select genre of beats
            SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.07,
              child: ListView.builder(
                itemCount: (beatGenres?.length ?? 0) + 1,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  bool isSelected = selectedBeatGenreIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.all(
                            isSelected ? Colors.blue[200] : Colors.grey[200]),
                      ),
                      onPressed: () async {
                        try {
                          setState(() {
                            selectedBeatGenreIndex = index;
                            currentBeatIndex = -1;
                            isExpanded = false;
                            currentBeat = null;
                          });
                          if (index == 0) {
                            beats = await apiService.fetchAllBeats();
                          } else {
                            beats = await apiService
                                .fetchBeatsByGenre(beatGenres![index - 1]);
                          }
                        } catch (e) {
                          debugPrint(e.toString());
                        }
                      },
                      child: Text(index == 0 ? 'All' : beatGenres![index - 1]),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Exercise List
            Expanded(
              child: ListView.builder(
                itemCount: beats?.length ?? 0,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 4,
                    child: Column(
                      children: [
                        ListTile(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  beats![index].name!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async =>
                                    await _togglePlayStop(index),
                                icon: Icon(isPlayingIndex == index && isPlaying
                                    ? Icons.stop
                                    : Icons.play_arrow),
                                label: Text(isPlayingIndex == index && isPlaying
                                    ? 'Stop'
                                    : 'Listen Beat'),
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      isPlayingIndex == index && isPlaying
                                          ? Colors.red
                                          : Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                ),
                              )
                            ],
                          ),
                          onTap: () async {
                            if (currentBeatIndex == index) {
                              // Toggle the expansion state
                              isExpanded = !isExpanded;
                            } else {
                              // Expand new beat and collapse previous one
                              currentBeatIndex = index;
                              isExpanded = true;
                              await fetchBeat(index);
                            }
                            setState(() {});
                          },
                        ),
                        AnimatedCrossFade(
                          firstChild: Container(),
                          secondChild: currentBeatIndex == index
                              ? Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8.0),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.blueAccent,
                                          Colors.lightBlueAccent
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Column(
                                      children: [
                                        StreamBuilder<DurationState>(
                                          stream: _durationStateStream,
                                          builder: (context, snapshot) {
                                            final durationState = snapshot.data;
                                            final position =
                                                durationState?.position ??
                                                    Duration.zero;
                                            final duration =
                                                durationState?.duration ??
                                                    Duration.zero;

                                            return Column(
                                              children: [
                                                Slider(
                                                  min: 0,
                                                  thumbColor: Colors.white,
                                                  max: duration.inMilliseconds
                                                      .toDouble(),
                                                  value: position.inMilliseconds
                                                      .clamp(
                                                          0,
                                                          duration
                                                              .inMilliseconds)
                                                      .toDouble(),
                                                  onChanged: (value) {
                                                    player.seek(Duration(
                                                        milliseconds:
                                                            value.toInt()));
                                                  },
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(formatDuration(
                                                          position)),
                                                      Text(formatDuration(
                                                          duration)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const Divider(
                                          color: Colors.white,
                                          thickness: 2,
                                        ),
                                        const Text(
                                          "Start Lighting",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "BPM: ${beats![index].bpm!.toInt()}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Slider(
                                              value:
                                                  beats![index].bpm!.toDouble(),
                                              min: 50,
                                              max: 250,
                                              onChanged: (value) {
                                                setState(() {
                                                  beats![index].bpm =
                                                      value.toInt();
                                                });
                                                deviceBloc.add(
                                                    UpdateBeatDataEvent(
                                                        beats![index]));
                                              },
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.white54,
                                            ),
                                          ],
                                        ),
                                        _buildPlaybackControls(
                                            context, deviceBloc),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(BuildContext context, DeviceBloc deviceBloc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Play button: Enabled when stopped or paused
        IconButton(
          icon: const Icon(Icons.play_arrow, size: 60),
          color: Colors.green,
          onPressed: playbackState == PlaybackState.stopped ||
                  playbackState == PlaybackState.paused ||
                  currentBeat!.notes!.isNotEmpty
              ? () async {
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Countdown();
                    },
                  );
                  setState(() {
                    playbackState = PlaybackState.playing;
                  });
                  deviceBloc.add(StartSendingEvent(context, true));
                }
              : null,
        ),
        // Pause button: Enabled when playing
        IconButton(
          icon: const Icon(Icons.pause, size: 60),
          color: Colors.orange,
          onPressed: playbackState == PlaybackState.playing
              ? () {
                  setState(() {
                    playbackState = PlaybackState.paused;
                  });
                  deviceBloc.add(PauseSendingEvent());
                }
              : null,
        ),
        // Stop button: Enabled when playing or paused
        IconButton(
          icon: const Icon(Icons.stop, size: 60),
          color: Colors.red,
          onPressed: playbackState == PlaybackState.playing ||
                  playbackState == PlaybackState.paused
              ? () {
                  setState(() {
                    playbackState = PlaybackState.stopped;
                  });
                  deviceBloc.add(StopSendingEvent(context));
                }
              : null,
        ),
      ],
    );
  }

  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration?, Duration?, DurationState>(
          player.positionStream, player.durationStream, (position, duration) {
        return DurationState(
            position: position ?? Duration.zero,
            duration: duration ?? Duration.zero);
      });

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }
}

class DurationState {
  final Duration position;
  final Duration duration;

  DurationState({required this.position, required this.duration});
}
