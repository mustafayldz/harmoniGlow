import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/device/device_bloc.dart';
import 'package:harmoniglow/blocs/device/device_event.dart';
import 'package:harmoniglow/enums.dart';
import 'package:harmoniglow/mock_service/api_service.dart';
import 'package:harmoniglow/models/traning_model.dart';
import 'package:harmoniglow/shared/countdown.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({
    super.key,
  });

  @override
  TrainingPageState createState() => TrainingPageState();
}

class TrainingPageState extends State<TrainingPage> {
  MockApiService apiService = MockApiService();
  PlaybackState playbackState = PlaybackState.stopped;
  int? currentBeatIndex;
  TraningModel? currentBeat;
  List<String>? beatNames;

  @override
  void initState() {
    super.initState();
    beatNames = apiService.fetchAllBeatNames();
  }

  Future<void> fetchBeat(int index) async {
    // Store the LoadingBloc in a local variable to avoid using context across await gaps
    final deviceBloc = context.read<DeviceBloc>();

    try {
      await apiService.fetchBeatData(beatIndex: index).then((value) {
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
        child: ListView(
          children: [
            const SizedBox(height: 20),

            // Exercise List
            const Text(
              "Exercises",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: currentBeat != null
                  ? 300.0
                  : MediaQuery.of(context).size.height - 200,
              child: ListView.builder(
                itemCount: beatNames!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(beatNames![index]),
                    trailing: const Icon(Icons.music_note),
                    onTap: () => selectBeat(index),
                  );
                },
              ),
            ),

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
                        "Selected Beat: ${currentBeat!.name}",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text("Rhythm: ${currentBeat!.rhythm}"),
                      const SizedBox(height: 10),
                      Text("Total Time: ${currentBeat!.totalTime} seconds"),
                      const SizedBox(height: 10),

                      // Metronome Slider
                      Text("Metronome BPM: ${currentBeat!.bpm!.toInt()}"),
                      Slider(
                        value: currentBeat!.bpm!.toDouble(),
                        min: 50,
                        max: 250,
                        onChanged: (value) {
                          setState(() {
                            currentBeat!.bpm = value.toInt();
                          });
                          // Update the DeviceBloc with the new beat data
                          // Update the DeviceBloc with the new beat data
                          deviceBloc.add(
                            UpdateBeatDataEvent(
                              currentBeat!,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Play/Pause/Stop Buttons
            Center(
              child: currentBeat != null
                  ? _buildPlaybackControls(context, deviceBloc)
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  void selectBeat(int index) {
    fetchBeat(index);
  }

  Widget _buildPlaybackControls(BuildContext context, DeviceBloc deviceBloc) {
    return Row(
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
                    builder: (BuildContext context) {
                      return const Countdown();
                    },
                  );
                  setState(() {
                    playbackState = PlaybackState.playing;
                  });
                  deviceBloc.add(StartSendingEvent(context));
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
                    playbackState = PlaybackState.stopped;
                  });
                  deviceBloc.add(StopSendingEvent(context));
                }
              : null,
        ),
      ],
    );
  }
}
