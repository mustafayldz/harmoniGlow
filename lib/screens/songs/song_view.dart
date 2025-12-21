import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/screens/player/player_view_youtube.dart';
import 'package:drumly/models/songs_model.dart';
import 'package:drumly/screens/songs/songs_viewmodel.dart';
import 'package:drumly/shared/app_gradients.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

class SongView extends StatefulWidget {
  const SongView({super.key});

  @override
  State<SongView> createState() => _SongViewState();
}

class _SongViewState extends State<SongView> {
  late final SongViewModel vm;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ConfettiController _confettiController;
  String _lastSearch = '';
  bool _isGridView = false;
  late final UserProvider userProvider;
  
  // 🚀 OPTIMIZATION: Cache SharedPreferences and unlock states
  SharedPreferences? _prefs;
  final Map<String, bool> _unlockCache = {};

  @override
  void initState() {
    super.initState();

    userProvider = Provider.of<UserProvider>(context, listen: false);
    vm = SongViewModel();
    vm.init(context);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));

    // 🚀 OPTIMIZATION: Initialize SharedPreferences once
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _prefs = await SharedPreferences.getInstance();
      vm.fetchInitialSongsWithCache(context);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
    _unlockCache.clear();
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

  /// 🔐 KILIT DURUMU KONTROLÜ - Optimized with caching
  /// Synchronous check using cached values
  bool _isSongLockedSync(SongModel song, bool isBluetoothConnected) {
    // Eğer şarkı zaten kilitsizse veya Bluetooth bağlıysa -> kilitsiz
    if (!song.isLocked || isBluetoothConnected) {
      return false;
    }

    // Eğer kullanıcıya atanmış şarkılar arasında varsa -> kilitsiz
    final assignedSongs = userProvider.userModel?.assignedSongIds ?? [];
    if (assignedSongs.contains(song.songId)) {
      return false;
    }

    // Check cache first
    final songId = song.songId;
    if (songId != null && _unlockCache.containsKey(songId)) {
      final isUnlocked = _unlockCache[songId] ?? false;
      return !isUnlocked;
    }

    // Default to locked, will be updated when cache is populated
    return true;
  }

  /// 🚀 OPTIMIZATION: Batch load unlock states for visible songs
  void _preloadUnlockStates(List<SongModel> songs) {
    if (_prefs == null) return;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    const twoHoursInMs = 2 * 60 * 60 * 1000;
    
    for (final song in songs) {
      final songId = song.songId;
      if (songId == null || _unlockCache.containsKey(songId)) continue;
      
      final unlockTimeKey = 'unlock_time_$songId';
      final unlockTime = _prefs!.getInt(unlockTimeKey);
      
      if (unlockTime != null) {
        final timeElapsed = currentTime - unlockTime;
        _unlockCache[songId] = timeElapsed <= twoHoursInMs;
        
        // Clean up expired unlocks
        if (timeElapsed > twoHoursInMs) {
          _prefs!.remove(unlockTimeKey);
        }
      } else {
        _unlockCache[songId] = false;
      }
    }
  }

  /// 🎁 Rewarded reklam sonrası unlock kaydet
  Future<void> _saveUnlockTime(String songId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final unlockTimeKey = 'unlock_time_$songId';
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await _prefs!.setInt(unlockTimeKey, currentTime);
    // Update cache immediately
    _unlockCache[songId] = true;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query != _lastSearch) {
        _lastSearch = query;
        vm.clearSongs();
        if (query.isEmpty) {
          // Boş arama - tüm şarkıları getir
          vm.fetchInitialSongsWithCache(context);
        } else {
          // Arama terimi var - filtrelenmiş sonuçları getir
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

    return ChangeNotifierProvider<SongViewModel>.value(
      value: vm,
      child: Consumer<SongViewModel>(
        builder: (context, vm, _) {
          // 🚀 OPTIMIZATION: Preload unlock states when songs change
          if (vm.songs.isNotEmpty) {
            _preloadUnlockStates(vm.songs);
          }
          if (vm.popularSongs.isNotEmpty) {
            _preloadUnlockStates(vm.popularSongs);
          }
          
          return Stack(
            children: [
              Scaffold(
                body: DecoratedBox(
                  decoration: AppDecorations.backgroundDecoration(isDarkMode),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Modern App Bar + Search
                        _buildModernHeader(context, isDarkMode),

                        // Main Content - No Tabs
                        Expanded(
                          child: _buildMainContent(
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
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isDarkMode) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          children: [
            // App Bar Row
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
                // Grid/List Toggle
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isGridView
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                    tooltip: _isGridView ? 'List View' : 'Grid View',
                  ),
                ),
                const SizedBox(width: 8),
                // My Requests Button
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
                      color: isDarkMode
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF4F46E5),
                    ),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/requested-songs'),
                    tooltip: 'My Song Requests',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Bar + Request Button Row
            _buildSearchBar(isDarkMode),
          ],
        ),
      );

  /// 🔍 Modern Search Bar
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      );

  /// 📱 Main Content - New Layout
  Widget _buildMainContent(
    SongViewModel vm,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    bool isDarkMode,
  ) {
    if (vm.songs.isEmpty &&
        vm.popularSongs.isEmpty &&
        !vm.isLoading &&
        !vm.isLoadingPopular) {
      return _buildEmptyState(isDarkMode);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollEndNotification &&
            _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200 &&
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
            // Popular Songs Section (Horizontal)
            if (vm.popularSongs.isNotEmpty) ...[
              _buildSectionHeader('Popular Songs', isDarkMode),
              const SizedBox(height: 8),
              _buildHorizontalSongsList(
                vm.popularSongs,
                isConnected,
                bluetoothBloc,
                vm,
                isDarkMode,
              ),
              const SizedBox(height: 16),
            ],

            // All Songs Section
            _buildSectionHeader(
              vm.popularSongs.isNotEmpty ? 'More Songs' : 'All Songs',
              isDarkMode,
              showCount: true,
              count: vm.songs.length,
            ),
            const SizedBox(height: 8),

            // Grid or List View
            _isGridView
                ? _buildSongsGrid(
                    vm.songs,
                    isConnected,
                    bluetoothBloc,
                    vm,
                    isDarkMode,
                  )
                : _buildSongsList(
                    vm.songs,
                    isConnected,
                    bluetoothBloc,
                    vm,
                    isDarkMode,
                  ),

            // Loading indicator
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 80), // Bottom padding
          ],
        ),
      ),
    );
  }

  /// 🎵 Horizontal Songs List for Popular Songs
  Widget _buildHorizontalSongsList(
    List<SongModel> songs,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
    bool isDarkMode,
  ) =>
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            // 🚀 OPTIMIZATION: Use synchronous cached check instead of FutureBuilder
            final isLocked = _isSongLockedSync(song, isConnected);
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: _buildHorizontalSongCard(
                context,
                song,
                isConnected,
                bluetoothBloc,
                vm,
                isLocked,
                isDarkMode,
              ),
            );
          },
        ),
      );

  /// 📱 Horizontal Song Card
  Widget _buildHorizontalSongCard(
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
            borderRadius: BorderRadius.circular(16),
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
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                          : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Music icon
                      const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      // Lock overlay
                      if (isLocked)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Info section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: 12,
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

  /// 📱 Songs Grid
  Widget _buildSongsGrid(
    List<SongModel> songs,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
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
          // 🚀 OPTIMIZATION: Use synchronous cached check instead of FutureBuilder
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

  /// 📱 Grid Song Card
  Widget _buildGridSongCard(
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
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                          : [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Music icon
                      const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      // Lock overlay
                      if (isLocked)
                        DecoratedBox(
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
                    ],
                  ),
                ),
              ),
              // Info section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title ?? 'Unknown',
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
                        song.artist ?? 'Unknown Artist',
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

  /// 📱 Songs List (Vertical)
  Widget _buildSongsList(
    List<SongModel> songs,
    bool isConnected,
    BluetoothBloc bluetoothBloc,
    SongViewModel vm,
    bool isDarkMode,
  ) =>
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          // 🚀 OPTIMIZATION: Use synchronous cached check instead of FutureBuilder
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

  /// 🚫 Empty State - Training tarzı
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
            // Song Request Button (only show when search has no results)
            if (_lastSearch.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSongRequestButton(isDarkMode),
            ],
          ],
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
      // 2 dakikalık unlock zamanını kaydet
      await _saveUnlockTime(song.songId!);

      // Confetti efekti başlat
      _confettiController.play();

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

  /// 🎵 Section Header Widget
  Widget _buildSectionHeader(
    String title,
    bool isDarkMode, {
    bool showCount = false,
    int count = 0,
  }) =>
      Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            if (showCount) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  /// 🎵 Song Request Button
  Widget _buildSongRequestButton(bool isDarkMode) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: ElevatedButton.icon(
          onPressed: () => _onSongRequestTap(),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDarkMode ? const Color(0xFF4F46E5) : const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
          label: Text(
            'request_song'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  /// 🎵 Song Request Navigation
  void _onSongRequestTap() {
    Navigator.pushNamed(
      context,
      '/song-request',
      arguments: {
        'searchQuery': _lastSearch,
      },
    );
  }
}
