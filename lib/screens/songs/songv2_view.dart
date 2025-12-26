import 'package:confetti/confetti.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/screens/player/songv2_player_view.dart';
import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/screens/songs/songv2_viewmodel.dart';
import 'package:drumly/shared/app_gradients.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongV2View extends StatefulWidget {
  const SongV2View({super.key});

  @override
  State<SongV2View> createState() => _SongV2ViewState();
}

class _SongV2ViewState extends State<SongV2View> {
  late final SongV2ViewModel vm;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ConfettiController _confettiController;
  String _lastSearch = '';
  bool _isGridView = false;
  late final UserProvider userProvider;
  SharedPreferences? _prefs;
  final Map<String, bool> _unlockCache = {};

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProvider>(context, listen: false);
    vm = SongV2ViewModel();
    vm.init(context);
    _initPrefs();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));

    vm.addListener(() {
      if (vm.songs.isNotEmpty && _prefs != null) {
        _preloadUnlockStates(vm.songs);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.fetchInitialSongs();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
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

  /// � Initialize SharedPreferences
  void _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// �🔐 Lock check - synchronous with cache
  bool _isSongLockedSync(SongV2Model song, bool isBluetoothConnected) {
    if (!song.isLocked || isBluetoothConnected) {
      return false;
    }

    final assignedSongs = userProvider.userModel?.assignedSongIds ?? [];
    if (assignedSongs.contains(song.songv2Id)) {
      return false;
    }

    if (_unlockCache.containsKey(song.songv2Id)) {
      return !(_unlockCache[song.songv2Id] ?? false);
    }

    return true;
  }

  void _preloadUnlockStates(List<SongV2Model> songs) {
    if (_prefs == null) return;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const twoHoursInMs = 2 * 60 * 60 * 1000;

    for (final song in songs) {
      final unlockTimeKey = 'unlock_time_${song.songv2Id}';
      final unlockTime = _prefs!.getInt(unlockTimeKey);

      if (unlockTime != null) {
        final timeElapsed = currentTime - unlockTime;
        // ✅ Her seferinde zamana göre kontrol et - 2 saat sonra tekrar kilitlensin
        _unlockCache[song.songv2Id] = timeElapsed <= twoHoursInMs;

        // Clean up expired unlocks
        if (timeElapsed > twoHoursInMs) {
          _prefs!.remove(unlockTimeKey);
        }
      } else {
        _unlockCache[song.songv2Id] = false;
      }
    }
  }

  Future<void> _saveUnlockTime(String songv2Id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final unlockTimeKey = 'unlock_time_$songv2Id';
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await _prefs!.setInt(unlockTimeKey, currentTime);
    _unlockCache[songv2Id] = true;
  }

  void _onUnlockTap(SongV2Model song) async {
    final success = await showAdConsentSnackBar(context, song.songv2Id);

    if (success) {
      await _saveUnlockTime(song.songv2Id);
      
      // Confetti efekti başlat
      _confettiController.play();
      
      if (mounted) setState(() {});
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query != _lastSearch) {
        _lastSearch = query;
        vm.clearSongs();
        if (query.isEmpty) {
          vm.fetchInitialSongs();
        } else {
          vm.fetchInitialSongsWithQuery(query: query);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider<SongV2ViewModel>.value(
      value: vm,
      child: Consumer<SongV2ViewModel>(
        builder: (context, vm, _) => Scaffold(
            body: Stack(
              children: [
                DecoratedBox(
                  decoration: AppDecorations.backgroundDecoration(isDarkMode),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _buildModernHeader(context, isDarkMode),
                        Expanded(
                          child: _buildMainContent(vm, isConnected, bluetoothBloc, isDarkMode),
                        ),
                      ],
                    ),
                  ),
                ),
                // Confetti Widget
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: 1.57, // radians - downwards
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.05,
                    numberOfParticles: 50,
                    maxBlastForce: 100,
                    minBlastForce: 80,
                    gravity: 0.3,
                    colors: const [
                      Colors.green,
                      Colors.blue,
                      Colors.pink,
                      Colors.orange,
                      Colors.purple,
                      Colors.yellow,
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isDarkMode) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            Row(
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    tooltip: _isGridView ? 'List View' : 'Grid View',
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                        : const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.library_music_rounded,
                      color: isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF4F46E5),
                    ),
                    onPressed: () => Navigator.pushNamed(context, '/requested-songs'),
                    tooltip: 'My Song Requests',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSearchBar(isDarkMode),
          ],
        ),
      );

  Widget _buildSearchBar(bool isDarkMode) => DecoratedBox(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'search_songs'.tr(),
            hintStyle: TextStyle(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );

  Widget _buildMainContent(
    SongV2ViewModel vm,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    bool isDarkMode,
  ) {
    if (vm.songs.isEmpty && !vm.isLoading) {
      return _buildEmptyState(isDarkMode);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollEndNotification &&
            _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
            vm.hasMore &&
            !vm.isLoading) {
          vm.fetchMoreSongs();
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'All Songs',
              isDarkMode,
              showCount: true,
              count: vm.songs.length,
            ),
            const SizedBox(height: 8),
            _isGridView
                ? _buildSongsGrid(vm.songs, isConnected, bluetoothBloc, vm, isDarkMode)
                : _buildSongsList(vm.songs, isConnected, bluetoothBloc, vm, isDarkMode),
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool isDarkMode, {
    bool showCount = false,
    int count = 0,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            if (showCount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _buildSongsList(
    List<SongV2Model> songs,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongV2ViewModel vm,
    bool isDarkMode,
  ) =>
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isLocked = _isSongLockedSync(song, isConnected);
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

  Widget _buildSongsGrid(
    List<SongV2Model> songs,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongV2ViewModel vm,
    bool isDarkMode,
  ) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isLocked = _isSongLockedSync(song, isConnected);
          return _buildGridSongCard(
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

  Widget _buildModernSongCard(
    BuildContext context,
    SongV2Model song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongV2ViewModel vm,
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                        color: isDarkMode ? Colors.white : Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${song.artist} – ${song.title}',
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
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.speed_rounded,
                      label: '${song.bpm} BPM',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      label: '${(song.durationMs / 1000 / 60).floor()}:${((song.durationMs / 1000) % 60).floor().toString().padLeft(2, '0')}',
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildGridSongCard(
    BuildContext context,
    SongV2Model song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongV2ViewModel vm,
    bool isLocked,
    bool isDarkMode,
  ) =>
      GestureDetector(
        onTap: () => _onSongTap(song, isConnected, bluetoothBloc, vm, isLocked),
        child: DecoratedBox(
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with lock overlay  
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          colors: isDarkMode
                              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                              : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isLocked)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

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

  Widget _buildEmptyState(bool isDarkMode) => Container(
        padding: const EdgeInsets.all(40),
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
              _lastSearch.isNotEmpty ? 'no_songs_found'.tr() : 'empty'.tr(),
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
                _lastSearch.isNotEmpty
                    ? 'search_not_found_desc'.tr()
                    : 'Explore amazing songs and beats',
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

  void _onSongTap(
    SongV2Model song,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongV2ViewModel vm,
    bool isLocked,
  ) {
    if (isLocked) {
      _onUnlockTap(song);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongV2PlayerView(songv2Id: song.songv2Id),
        ),
      );
    }
  }
}
