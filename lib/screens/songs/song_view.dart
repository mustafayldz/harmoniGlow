import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/hive/db_service.dart';
import 'package:drumly/screens/player/player_view_youtube.dart';
import 'package:drumly/screens/songs/songs_viewmodel.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

/// A modern, card-based list of songs
class SongView extends StatefulWidget {
  const SongView({super.key});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> {
  late final SongViewModel vm;
  late final LazyBox _lazyBox;

  @override
  void initState() {
    super.initState();
    vm = SongViewModel();
    vm.fetchSongs(context);
    cleanExpiredRecords();

    _lazyBox = Hive.lazyBox(Constants.lockSongBox); // LazyBox olarak alıyoruz
  }

  Future<bool> _isUnlocked(String songId) async => _lazyBox.containsKey(songId);

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;

    return ChangeNotifierProvider<SongViewModel>.value(
      value: vm,
      child: Consumer<SongViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(title: const Text('Songs')),
          body: vm.songList.isEmpty
              ? Center(
                  child: Image.asset(
                    'assets/images/empty/song_empty.png',
                    width: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: vm.songList.length,
                  itemBuilder: (_, index) {
                    final songs = vm.songListNew;
                    final song = songs[index];
                    final songId = song.songId.toString();

                    return FutureBuilder<bool>(
                      future: _isUnlocked(songId),
                      builder: (context, snapshot) {
                        final isUnlocked = snapshot.data ?? false;
                        final showLock =
                            (song.isLocked && !isUnlocked) && !isConnected;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              if (showLock) {
                                showAdConsentSnackBar(
                                  context,
                                  song.songId!,
                                );
                              } else {
                                await SendData().sendHexData(
                                  bluetoothBloc,
                                  splitToBytes(100),
                                );

                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (context) {
                                    final theme = Theme.of(context);
                                    return ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: ColoredBox(
                                        color: theme.scaffoldBackgroundColor,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 4,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.grey[600]
                                                    : Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  2,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.9,
                                              child: DraggableScrollableSheet(
                                                initialChildSize: 1.0,
                                                minChildSize: 0.3,
                                                expand: false,
                                                builder:
                                                    (context, scrollCtrl) =>
                                                        YoutubeSongPlayer(
                                                  song: song,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ).whenComplete(() async {
                                  await SendData()
                                      .sendHexData(bluetoothBloc, [0]);
                                });
                              }
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${song.artist ?? 'Unknown'} – ${song.title ?? '—'}',
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
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (song.durationSeconds !=
                                                null) ...[
                                              Chip(
                                                label: Text(
                                                  vm.formatDuration(
                                                    song.durationSeconds,
                                                  ),
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (showLock)
                                    const Icon(Icons.lock, size: 32),
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
      ),
    );
  }
}
