import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/device/device_bloc.dart';
import 'package:harmoniglow/blocs/device/device_event.dart';
import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/mock_service/api_service.dart';
import 'package:harmoniglow/models/traning_model.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SongPage extends StatefulWidget {
  const SongPage({
    super.key,
  });

  @override
  SongPageState createState() => SongPageState();
}

class SongPageState extends State<SongPage> {
  MockApiService apiService = MockApiService();
  PlaybackState playbackState = PlaybackState.stopped;
  int? currentBeatIndex;
  TraningModel? currentBeat;
  List<String>? beatNames;

  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    beatNames = apiService.fetchAllSongNames();
    _controller = YoutubePlayerController(
      initialVideoId: 'sqoNLQxTuz8',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: true,
        enableCaption: false,
        hideControls: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(listener);
    _controller?.dispose();
    super.dispose();
  }

  void listener() {
    if (_controller != null && mounted) {
      // Check the current player state
      final YoutubePlayerValue playerValue = _controller!.value;

      // Example: Auto-pause the video when it ends
      if (playerValue.playerState == PlayerState.ended) {
        setState(() {
          playbackState = PlaybackState.stopped;
        });
        debugPrint('Video ended. Stopping playback.');
      }
    }
  }

  Future<void> fetchBeat(int index) async {
    // Store the LoadingBloc in a local variable to avoid using context across await gaps
    final deviceBloc = context.read<DeviceBloc>();

    try {
      await apiService.fetchSongData(songIndex: index).then((value) {
        setState(() {
          currentBeatIndex = index;
          currentBeat = value;
          deviceBloc.add(UpdateBeatDataEvent(value));
        });
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceBloc = context.read<DeviceBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drum Training'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Exercise List Title
            const Text(
              'Exercises',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Dynamic List of Exercises
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate the height based on the number of items
                final itemHeight = 60.0; // Approximate height of each ListTile
                final maxListHeight = constraints.maxHeight * 0.5;
                final totalHeight = beatNames!.length * itemHeight;

                return SizedBox(
                  height:
                      totalHeight > maxListHeight ? maxListHeight : totalHeight,
                  child: ListView.builder(
                    itemCount: beatNames?.length ?? 0,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(beatNames![index]),
                      trailing: const Icon(Icons.music_note),
                      onTap: () => selectBeat(index),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Display Selected Beat Information
            if (currentBeat != null)
              Card(
                color: Colors.blue.shade50,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Beat: ${currentBeat!.name}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Rhythm: ${currentBeat!.rhythm}'),
                      const SizedBox(height: 10),
                      Text('Total Time: ${currentBeat!.totalTime} seconds'),
                      const SizedBox(height: 10),
                      Text('Metronome BPM: ${currentBeat!.bpm!.toInt()}'),
                      const SizedBox(height: 10),

                      // Youtube Player
                      if (_controller != null)
                        YoutubePlayer(
                          controller: _controller!,
                          showVideoProgressIndicator: true,
                          progressIndicatorColor: Colors.amber,
                          progressColors: const ProgressBarColors(
                            playedColor: Colors.amber,
                            handleColor: Colors.amberAccent,
                          ),
                          bottomActions: const [
                            CurrentPosition(),
                            ProgressBar(isExpanded: true),
                            RemainingDuration(),
                          ],
                          onReady: () {
                            _controller!.addListener(listener);
                          },
                          onEnded: (metaData) => setState(() {
                            playbackState = PlaybackState.stopped;
                            deviceBloc.add(StopSendingEvent(context));
                          }),
                        ),
                    ],
                  ),
                ),
              ),

            // Play/Pause/Stop Buttons
            if (currentBeat != null)
              Center(
                child: _buildPlaybackControls(context, deviceBloc),
              ),
          ],
        ),
      ),
    );
  }

  void selectBeat(int index) {
    fetchBeat(index);
  }

  Widget _buildPlaybackControls(BuildContext context, DeviceBloc deviceBloc) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Play button: Enabled when stopped or paused
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 30),
            color: Colors.green,
            onPressed: playbackState == PlaybackState.stopped ||
                    playbackState == PlaybackState.paused ||
                    currentBeat!.notes!.isNotEmpty
                ? () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) => const Countdown(),
                    );
                    setState(() {
                      _controller?.play();
                      playbackState = PlaybackState.playing;
                    });
                    deviceBloc.add(StartSendingEvent(context, false));
                  }
                : null,
          ),
          // Pause button: Enabled when playing
          IconButton(
            icon: const Icon(Icons.pause, size: 30),
            color: Colors.orange,
            onPressed: playbackState == PlaybackState.playing
                ? () {
                    setState(() {
                      _controller?.pause();
                      playbackState = PlaybackState.paused;
                    });
                    deviceBloc.add(PauseSendingEvent());
                  }
                : null,
          ),
          // Stop button: Enabled when playing or paused
          IconButton(
            icon: const Icon(Icons.stop, size: 30),
            color: Colors.red,
            onPressed: playbackState == PlaybackState.playing ||
                    playbackState == PlaybackState.paused
                ? () {
                    setState(() {
                      _controller?.seekTo(const Duration(seconds: 0));
                      _controller?.pause();
                      playbackState = PlaybackState.stopped;
                    });
                    deviceBloc.add(StopSendingEvent(context));
                  }
                : null,
          ),
        ],
      );
}
