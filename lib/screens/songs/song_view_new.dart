import 'package:flutter/material.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/screens/player/player_new.dart';
import 'package:harmoniglow/screens/songs/songs_viewmodel.dart';
import 'package:harmoniglow/shared/common_functions.dart';
import 'package:harmoniglow/shared/send_data.dart';
import 'package:provider/provider.dart';

/// A modern, card-based list of songs
class SongView extends StatefulWidget {
  const SongView({super.key});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> {
  late final SongViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = SongViewModel();
    vm.fetchSongs();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    return ChangeNotifierProvider<SongViewModel>.value(
      value: vm,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Songs'),
        ),
        body: Consumer<SongViewModel>(
          builder: (context, vm, _) {
            final songs = vm.songListNew;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      await SendData().sendHexData(
                        bluetoothBloc,
                        splitToBytes(100),
                      );
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        // give the sheet a rounded top
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => FractionallySizedBox(
                          // set height to 95% of screen
                          heightFactor: 0.95,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: DraggableScrollableSheet(
                              initialChildSize: 1.0,
                              minChildSize: 0.3,
                              expand: false,
                              builder: (context, scrollCtrl) => PlayerView(
                                song,
                              ),
                            ),
                          ),
                        ),
                      ).whenComplete(() async {
                        await SendData().sendHexData(bluetoothBloc, [0]);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${song.artist ?? 'Unknown Artist'} - ${song.title ?? 'Unknown Title'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (song.bpm != null) ...[
                                      Chip(
                                        label: Text('${song.bpm} BPM'),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (song.durationSeconds != null) ...[
                                      Chip(
                                        label: Text(
                                          vm.formatDuration(
                                            song.durationSeconds,
                                          ),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
