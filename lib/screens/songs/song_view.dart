// 📁 song_view.dart - TAMAMEN DÜZELTİLMİŞ VERSİYON

import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/player/player_view_youtube.dart';
import 'package:drumly/screens/songs/songs_model.dart';
import 'package:drumly/screens/songs/songs_viewmodel.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongView extends StatefulWidget {
  const SongView({super.key});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> {
  late final SongViewModel vm;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _lastSearch = '';

  @override
  void initState() {
    super.initState();
    vm = SongViewModel();
    vm.init(context);
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

  /// 🔐 KILIT DURUMU KONTROLÜ - Tüm kurallar burada
  Future<bool> _isSongLocked(SongModel song, bool isBluetoothConnected) async {
    // 📱 1. API'den gelen şarkı zaten kilitsiz ise -> KİLİTSİZ
    if (!song.isLocked) return false;

    // 🔵 2. Bluetooth bağlı ise -> KİLİTSİZ
    if (isBluetoothConnected) return false;

    // ⏰ 3. Shared Preferences'dan 2 saatlik unlock kontrolü
    return !(await _hasValidUnlock(song.songId));
  }

  /// ⏰ 2 saatlik unlock kontrolü
  Future<bool> _hasValidUnlock(String? songId) async {
    if (songId == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final unlockTimeKey = 'unlock_time_$songId';
    final unlockTime = prefs.getInt(unlockTimeKey);

    if (unlockTime == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final twoHoursInMs = 2 * 60 * 60 * 1000; // 2 saat

    // 2 saat geçti mi kontrol et
    if (currentTime - unlockTime > twoHoursInMs) {
      // Süresi dolmuş, temizle
      await prefs.remove(unlockTimeKey);
      return false;
    }

    return true; // Hala geçerli
  }

  /// 🎁 Rewarded reklam sonrası unlock kaydet
  Future<void> _saveUnlockTime(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockTimeKey = 'unlock_time_$songId';
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(unlockTimeKey, currentTime);
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
        itemCount: vm.songs.length + (vm.hasMore ? 1 : 0),
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

          // 🔐 FUTURE BUILDER ile kilit durumu kontrolü
          return FutureBuilder<bool>(
            future: _isSongLocked(song, isConnected),
            builder: (context, snapshot) {
              final isLocked =
                  snapshot.data ?? song.isLocked; // Default: API'den gelen

              return _buildModernSongCard(
                song,
                isConnected,
                bluetoothBloc,
                vm,
                isLocked,
              );
            },
          );
        },
      );

  Widget _buildModernSongCard(
    SongModel song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
    bool isLocked,
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
            onTap: () =>
                _onSongTap(song, isConnected, bluetoothBloc, vm, isLocked),
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
                          '${song.artist ?? 'unknown'.tr()} – ${song.title ?? '—'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
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
                            if (song.bpm != null &&
                                song.durationSeconds != null)
                              const SizedBox(width: 8),
                            if (song.durationSeconds != null)
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔐 Lock butonu - sadece kilitli şarkılar için
                      if (isLocked)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: IconButton(
                            onPressed: () => _onUnlockTap(song),
                            icon: const Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      // ▶️ Play butonu - kilitsiz şarkılar için
                      if (!isLocked)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: IconButton(
                            onPressed: () => _onPlayTap(
                              song,
                              isConnected,
                              bluetoothBloc,
                              vm,
                            ),
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// 🎁 Rewarded reklam göster ve unlock yap
  void _onUnlockTap(SongModel song) async {
    final success = await showAdConsentSnackBar(context, song.songId ?? '');
    if (success && song.songId != null) {
      // 2 saatlik unlock zamanını kaydet
      await _saveUnlockTime(song.songId!);

      // UI'ı güncelle
      setState(() {});
    }
  }

  /// ▶️ Play butonu tap
  void _onPlayTap(
    SongModel song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
  ) async {
    await SendData().sendHexData(
      bluetoothBloc,
      splitToBytes(100),
    );

    final fullSong = await vm.fetchSongDetail(song.songId ?? '');
    if (fullSong == null) {
      showClassicSnackBar(
        context,
        tr('error_loading_song_detail'),
      );
      return;
    }

    if (mounted) {
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
        await SendData().sendHexData(bluetoothBloc, [0]);
      });
    }
  }

  /// 🎵 Şarkı tap - ana giriş noktası
  void _onSongTap(
    SongModel song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
    bool isLocked,
  ) async {
    if (isLocked) {
      // Kilitli şarkı - unlock için reklam göster
      _onUnlockTap(song);
    } else {
      // Kilitsiz şarkı - direkt player'a git
      _onPlayTap(song, isConnected, bluetoothBloc, vm);
    }
  }
}
