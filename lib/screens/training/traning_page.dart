import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/device/device_bloc.dart';
import 'package:harmoniglow/blocs/device/device_event.dart';
import 'package:harmoniglow/mock_service/api_service.dart';
import 'package:harmoniglow/screens/songs/songs_model.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:just_audio/just_audio.dart';

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
  List<SongModel>? beats = [];
  List<SongModel>? beatsOriginal = [];
  SongModel? currentBeat;
  int currentBeatIndex = -1;
  List<String>? beatGenres;
  int selectedBeatGenreIndex = 0;
  bool isExpanded = false;

  int isPlayingIndex = -1;
  bool isPlaying = false;
  bool isLighting = false;

  @override
  void initState() {
    super.initState();
    setBeat();
  }

  Future<void> setBeat() async {
    beats = await apiService.fetchAllBeats();
    beatsOriginal = beats;
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
                  final bool isSelected = selectedBeatGenreIndex == index;
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
                          isSelected ? Colors.blue[200] : Colors.grey[200],
                        ),
                      ),
                      onPressed: () async {
                        try {
                          setState(() {
                            selectedBeatGenreIndex = index;
                            currentBeatIndex = -1;
                            isExpanded = false;
                            currentBeat = null;
                            isPlaying = false;
                            isPlayingIndex = -1;
                          });
                          await player.stop();

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
                itemBuilder: (context, index) => Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          beats![index].title!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          if (currentBeatIndex == index) {
                            isExpanded = !isExpanded;
                          } else {
                            currentBeatIndex = index;
                            isExpanded = true;
                            await fetchBeat(index);
                          }
                          setState(() {});
                        },
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: currentBeatIndex == index
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              beats![index].bpm = 60;
                                            });
                                            deviceBloc.add(
                                              UpdateBeatDataEvent(
                                                beats![index],
                                              ),
                                            );
                                          },
                                          child: const Text('Easy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              beats![index].bpm =
                                                  beatsOriginal![index].bpm;
                                            });
                                            deviceBloc.add(
                                              UpdateBeatDataEvent(
                                                beats![index],
                                              ),
                                            );
                                          },
                                          child: const Text('Normal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              beats![index].bpm = 120;
                                            });
                                            deviceBloc.add(
                                              UpdateBeatDataEvent(
                                                beats![index],
                                              ),
                                            );
                                          },
                                          child: const Text('Hard'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (!isLighting) {
                                          deviceBloc.add(
                                            UpdateBeatDataEvent(
                                              beats![index],
                                            ),
                                          );
                                          startLigthning(
                                            context,
                                            deviceBloc,
                                            index,
                                          );
                                        } else {
                                          stopLigthning(
                                            context,
                                            deviceBloc,
                                            index,
                                          );
                                        }

                                        setState(() {
                                          isLighting = !isLighting;
                                        });
                                      },
                                      icon: Icon(
                                        isLighting
                                            ? Icons.highlight_off
                                            : Icons.flash_on,
                                      ),
                                      label: Text(
                                        isLighting
                                            ? 'Stop Lighting'
                                            : 'Start Lighting',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isLighting
                                            ? Colors.red.shade600
                                            : Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                        crossFadeState: isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePlayStop(int index) async {
    debugPrint('🎵 Playing beat: ${beats![index].title}');

    if (isPlayingIndex == index && isPlaying) {
      // Eğer şu an çalmakta olan beat'e tekrar tıklandıysa durdur
      setState(() {
        isPlaying = false;
        isPlayingIndex = -1;
      });
      await player.stop();
    } else {
      // Yeni bir beat'e tıklandıysa veya daha önce durdurulmuşsa
      setState(() {
        isPlaying = true;
        isPlayingIndex = index;
      });

      await player.setUrl(beats![index].fileUrl!);
      await player.setLoopMode(LoopMode.off); // sadece bir kere çal
      await player.play();

      // Beat bittikten sonra durumu sıfırla
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            isPlaying = false;
            isPlayingIndex = -1;
          });
        }
      });
    }
  }

  Future<void> startLigthning(
    BuildContext context,
    DeviceBloc deviceBloc,
    int index,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Countdown(),
    );

    deviceBloc.add(StartSendingEvent(context, true));
    await _togglePlayStop(index);
  }

  void stopLigthning(
    BuildContext context,
    DeviceBloc deviceBloc,
    int index,
  ) async {
    deviceBloc.add(StopSendingEvent(context));
    await _togglePlayStop(index);
  }
}
