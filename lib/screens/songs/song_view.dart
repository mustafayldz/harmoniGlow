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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider<SongViewModel>.value(
      value: vm,
      child: Consumer<SongViewModel>(
        builder: (context, vm, _) => Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        const Color(0xFF0F172A), // Dark slate
                        const Color(0xFF1E293B), // Lighter slate
                        const Color(0xFF334155), // Even lighter
                      ]
                    : [
                        const Color(0xFFF8FAFC), // Light gray
                        const Color(0xFFE2E8F0), // Slightly darker
                        const Color(0xFFCBD5E1), // Even darker
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Modern App Bar (Training tarzı)
                  _buildModernAppBar(context, isDarkMode),

                  // Modern Search Section (Training tarzı)
                  _buildModernSearchSection(context, isDarkMode),

                  // Songs List
                  Expanded(
                    child: vm.songs.isEmpty && !vm.isLoading
                        ? _buildEmptyState(isDarkMode)
                        : _buildSongsList(
                            vm,
                            isConnected,
                            bluetoothBloc,
                            isDarkMode,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Modern App Bar - Training tarzı
  Widget _buildModernAppBar(BuildContext context, bool isDarkMode) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'songs'.tr(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );

  /// 🔍 Modern Search Section - Training tarzı
  Widget _buildModernSearchSection(BuildContext context, bool isDarkMode) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'searchBySong'.tr(),
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
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
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _onSearchPressed,
                icon: Icon(
                  Icons.search_rounded,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );

  /// 🎵 Empty State - Training tarzı
  Widget _buildEmptyState(bool isDarkMode) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.music_note_rounded,
                size: 64,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'empty'.tr(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Explore amazing songs and beats',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );

  /// 📝 Songs List - Training tarzı
  Widget _buildSongsList(
    SongViewModel vm,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    bool isDarkMode,
  ) =>
      NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo is ScrollEndNotification &&
              !vm.isLoading &&
              vm.hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            vm.fetchMoreSongs();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: vm.songs.length + (vm.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= vm.songs.length) {
              return Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              );
            }

            final song = vm.songs[index];

            // 🔐 FUTURE BUILDER ile kilit durumu kontrolü
            return FutureBuilder<bool>(
              future: _isSongLocked(song, isConnected),
              builder: (context, snapshot) {
                final isLocked = snapshot.data ?? song.isLocked;

                return _buildModernSongCard(
                  context,
                  song,
                  isConnected,
                  bluetoothBloc,
                  vm,
                  isLocked,
                  isDarkMode,
                );
              },
            );
          },
        ),
      );

  /// 🎵 Modern Song Card - Training tarzı
  Widget _buildModernSongCard(
    BuildContext context,
    SongModel song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
    bool isLocked,
    bool isDarkMode,
  ) =>
      GestureDetector(
        onTap: () => _onSongTap(song, isConnected, bluetoothBloc, vm, isLocked),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color(0xFF1E293B).withValues(alpha: 0.8),
                      const Color(0xFF334155).withValues(alpha: 0.6),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.9),
                      const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Song Icon/Image
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : Icons.play_arrow_rounded,
                        color: isDarkMode ? Colors.white : Colors.black,
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info Chips
                Row(
                  children: [
                    if (song.bpm != null)
                      _buildInfoChip(
                        icon: Icons.speed_rounded,
                        label: '${song.bpm} BPM',
                        isDarkMode: isDarkMode,
                      ),
                    if (song.bpm != null && song.durationSeconds != null)
                      const SizedBox(width: 12),
                    if (song.durationSeconds != null)
                      _buildInfoChip(
                        icon: Icons.timer_outlined,
                        label: vm.formatDuration(song.durationSeconds),
                        isDarkMode: isDarkMode,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  /// 🏷️ Info Chip - Training tarzı
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          final theme = Theme.of(context);
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: ColoredBox(
              color: theme.scaffoldBackgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[600]
                          : Colors.grey[300],
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
          );
        },
      ).whenComplete(() async {
        await SendData().sendHexData(bluetoothBloc, [0]);
      });
    }
  }

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
