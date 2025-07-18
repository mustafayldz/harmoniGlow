import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/screens/player/player_view_youtube.dart';
import 'package:drumly/screens/songs/songs_viewmodel.dart';
import 'package:drumly/screens/songs/songs_model.dart';
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
    _lazyBox = Hive.lazyBox(Constants.lockSongBox);
    vm.fetchInitialSongsWithCache(context);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(
              'songs'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Modern Search Section
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'searchBySong'.tr(),
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _onSearchPressed(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                            ),
                            child: IconButton(
                              onPressed: _onSearchPressed,
                              icon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Songs List
                  Expanded(
                    child: vm.songs.isEmpty && !vm.isLoading
                        ? _buildEmptyState()
                        : _buildSongsList(vm, isConnected, bluetoothBloc),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.music_note,
                size: 64,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'empty'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore amazing songs and beats',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildSongsList(
    SongViewModel vm,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
  ) =>
      ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vm.songs.length + (vm.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= vm.songs.length) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          final song = vm.songs[index];
          return _buildModernSongCard(song, isConnected, bluetoothBloc, vm);
        },
      );

  Widget _buildModernSongCard(
    SongModel song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _onSongTap(song, isConnected, bluetoothBloc, vm),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Song Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Song Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              child: Text(
                                vm.formatDuration(song.durationSeconds),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (song.bpm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.2),
                                ),
                                child: Text(
                                  '${song.bpm} BPM',
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: IconButton(
                          onPressed: () => _onPlayTap(song),
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      // Sadece kilitli şarkılarda ve henüz unlock edilmemişse unlock butonu göster
                      if (song.isLocked && !_isUnlocked(song.songId)) ...[
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => _onUnlockTap(song),
                            icon: const Icon(
                              Icons.lock_open,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  bool _isUnlocked(String? songId) {
    if (songId == null) return false;
    return _lazyBox.containsKey(songId);
  }

  void _onPlayTap(SongModel song) async {
    final fullSong = await vm.fetchSongDetail(song.songId ?? '');
    if (fullSong != null && mounted) {
      // Eğer şarkı kilitsiz ise bluetooth verisi gönder
      if (!song.isLocked || _isUnlocked(song.songId)) {
        final bluetoothBloc = context.read<BluetoothBloc>();
        final state = bluetoothBloc.state;
        final isConnected = state.isConnected;

        if (isConnected) {
          await SendData().sendHexData(bluetoothBloc, [1]);
        }
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.95,
        ),
        builder: (context) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: DraggableScrollableSheet(
                    initialChildSize: 1.0,
                    minChildSize: 0.3,
                    expand: false,
                    builder: (context, scrollCtrl) =>
                        YoutubeSongPlayer(song: fullSong),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).whenComplete(() async {
        // Eğer şarkı kilitsiz ise bluetooth stop verisi gönder
        if (!song.isLocked || _isUnlocked(song.songId)) {
          final bluetoothBloc = context.read<BluetoothBloc>();
          final state = bluetoothBloc.state;
          final isConnected = state.isConnected;

          if (isConnected) {
            await SendData().sendHexData(bluetoothBloc, [0]);
          }
        }
      });
    }
  }

  void _onUnlockTap(SongModel song) async {
    final success = await showAdConsentSnackBar(context, song.songId ?? '');
    if (success) {
      await _lazyBox.put(song.songId ?? '', true);
      setState(() {});
    }
  }

  void _onSongTap(
    SongModel song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
  ) async {
    // Eğer şarkı API'den kilitsiz geliyorsa veya kullanıcı unlock etmişse player'a git
    if (!song.isLocked || _isUnlocked(song.songId)) {
      final fullSong = await vm.fetchSongDetail(song.songId ?? '');
      if (fullSong != null && mounted) {
        // Bluetooth bağlıysa veri gönder
        if (isConnected) {
          await SendData().sendHexData(bluetoothBloc, [1]);
        }

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.95,
          ),
          builder: (context) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A1A2E),
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: DraggableScrollableSheet(
                      initialChildSize: 1.0,
                      minChildSize: 0.3,
                      expand: false,
                      builder: (context, scrollCtrl) =>
                          YoutubeSongPlayer(song: fullSong),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).whenComplete(() async {
          // Bluetooth bağlıysa stop verisi gönder
          if (isConnected) {
            await SendData().sendHexData(bluetoothBloc, [0]);
          }
        });
      }
    } else {
      // Şarkı kilitli, unlock işlemi yap
      _onUnlockTap(song);
    }
  }
}
