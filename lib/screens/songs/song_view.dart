import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/hive/db_service.dart';
import 'package:drumly/screens/player/player_view_youtube.dart';
import 'package:drumly/screens/songs/songs_viewmodel.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

class SongView extends StatefulWidget {
  const SongView({super.key});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> {
  late final SongViewModel vm;
  late final LazyBox _lazyBox;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    vm = SongViewModel();
    vm.init(context);
    vm.fetchInitialSongsWithCache(context);
    cleanExpiredRecords();
    _lazyBox = Hive.lazyBox(Constants.lockSongBox);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        vm.hasMore &&
        !vm.isLoading) {
      vm.fetchMoreSongs();
    }
  }

  Future<bool> _isUnlocked(String songId) async => _lazyBox.containsKey(songId);

  void _onSearchPressed() {
    final query = _searchController.text.trim();
    if (query != _lastSearch) {
      _lastSearch = query;
      vm.clearSongs();
      vm.fetchInitialSongsWithQuery(query: query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;

    return ChangeNotifierProvider<SongViewModel>.value(
      value: vm,
      child: Consumer<SongViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(title: const Text('songs').tr()),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'searchBySong'.tr(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (_) => _onSearchPressed(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _onSearchPressed,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: vm.songs.isEmpty && !vm.isLoading
                    ? Center(
                        child: Image.asset(
                          'assets/images/empty/song_empty.png',
                          width: MediaQuery.of(context).size.width * 0.8,
                          fit: BoxFit.contain,
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: vm.songs.length + (vm.hasMore ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (index >= vm.songs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final song = vm.songs[index];
                          final songId = song.songId.toString();

                          return FutureBuilder<bool>(
                            future: _isUnlocked(songId),
                            builder: (context, snapshot) {
                              final isUnlocked = snapshot.data ?? false;
                              final showLock = (song.isLocked && !isUnlocked) &&
                                  !isConnected;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    if (showLock) {
                                      await showAdConsentSnackBar(
                                        context,
                                        song.songId!,
                                      ).then((value) async {
                                        if (value == true) {
                                          setState(() {
                                            vm.fetchInitialSongsWithCache(
                                              context,
                                            );
                                          });
                                        }
                                      });
                                    } else {
                                      await SendData().sendHexData(
                                        bluetoothBloc,
                                        splitToBytes(100),
                                      );

                                      // ✅ Şarkı detayını çekiyoruz
                                      final fullSong = await vm
                                          .fetchSongDetail(song.songId!);
                                      if (fullSong == null) {
                                        showClassicSnackBar(
                                          context,
                                          tr('error_loading_song_detail'),
                                        );
                                        return;
                                      }

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
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                            child: ColoredBox(
                                              color:
                                                  theme.scaffoldBackgroundColor,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 4,
                                                    margin: const EdgeInsets
                                                        .symmetric(vertical: 8),
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
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.9,
                                                    child:
                                                        DraggableScrollableSheet(
                                                      initialChildSize: 1.0,
                                                      minChildSize: 0.3,
                                                      expand: false,
                                                      builder: (
                                                        context,
                                                        scrollCtrl,
                                                      ) =>
                                                          YoutubeSongPlayer(
                                                        song:
                                                            fullSong, // ✅ Detaylı veri
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
                                                '${song.artist ?? 'unknown'.tr()} – ${song.title ?? '—'}',
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
                                                      label: Text(
                                                        '${song.bpm} BPM',
                                                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}
