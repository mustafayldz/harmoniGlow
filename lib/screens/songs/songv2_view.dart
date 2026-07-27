import 'package:confetti/confetti.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/screens/player/songv2_player_view.dart';
import 'package:drumly/models/songv2_model.dart';
import 'package:drumly/screens/songs/songv2_viewmodel.dart';
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
        ConfettiController(duration: const Duration(milliseconds: 900));

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
            _scrollController.position.maxScrollExtent - 320 &&
        vm.hasMore &&
        !vm.isLoading) {
      vm.fetchMoreSongs();
    }
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool _isSongLockedSync(SongV2Model song, bool isBluetoothConnected) {
    if (!song.isLocked || isBluetoothConnected) return false;

    final assignedSongs = userProvider.userModel?.assignedSongIds ?? [];
    if (assignedSongs.contains(song.songv2Id)) return false;

    if (_unlockCache.containsKey(song.songv2Id)) {
      return !(_unlockCache[song.songv2Id] ?? false);
    }
    return true;
  }

  void _preloadUnlockStates(List<SongV2Model> songs) {
    if (_prefs == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    const twoHours = 2 * 60 * 60 * 1000;

    for (final song in songs) {
      final key = 'unlock_time_${song.songv2Id}';
      final unlockTime = _prefs!.getInt(key);

      if (unlockTime != null) {
        final elapsed = now - unlockTime;
        _unlockCache[song.songv2Id] = elapsed <= twoHours;

        if (elapsed > twoHours) {
          _prefs!.remove(key);
        }
      } else {
        _unlockCache[song.songv2Id] = false;
      }
    }
  }

  Future<void> _saveUnlockTime(String songv2Id) async {
    _prefs ??= await SharedPreferences.getInstance();
    final key = 'unlock_time_$songv2Id';
    await _prefs!.setInt(key, DateTime.now().millisecondsSinceEpoch);
    _unlockCache[songv2Id] = true;
  }

  void _onUnlockTap(SongV2Model song) async {
    final ok = await showAdConsentSnackBar(context, song.songv2Id);
    if (ok) {
      await _saveUnlockTime(song.songv2Id);
      _confettiController.play();
      if (mounted) setState(() {});
    }
  }

  void _onSearchChanged(String query) {
    if (query == _lastSearch) return;

    setState(() => _lastSearch = query);

    vm.clearSongs();
    if (query.isEmpty) {
      vm.fetchInitialSongs();
    } else {
      vm.fetchInitialSongsWithQuery(query: query);
    }
  }

  String _durationText(int durationMs) {
    final totalSeconds = (durationMs / 1000).floor();
    final m = (totalSeconds / 60).floor();
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ✅ Sade responsive helper
  double _scale(double w) => (w / 390).clamp(0.85, 1.20);

  double _sz(double base, double sc, {double? min, double? max}) {
    final v = base * sc;
    if (min != null && v < min) return min;
    if (max != null && v > max) return max;
    return v;
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
        builder: (context, vm, _) {
          final visibleSongs = vm.songs;
          return Scaffold(
            body: Stack(
              children: [
                ColoredBox(
                  color: isDarkMode
                      ? const Color(0xFF070A10)
                      : const Color(0xFFF5F6F8),
                  child: SafeArea(
                    bottom: false,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        final sc = _scale(w);

                        final hp = _sz(12, sc, min: 10, max: 20);
                        final gap = _sz(10, sc, min: 8, max: 14);

                        // ✅ grid kolon hesabı (dinamik, ama basit)
                        final targetTileW = _sz(175, sc, min: 150, max: 230);
                        final cols = (w / targetTileW).floor().clamp(2, 6);

                        // ✅ overflow-proof: kart yüksekliği sabit (scale’li)
                        final gridExtent = _sz(164, sc, min: 154, max: 184);

                        final headerTitle = _sz(22, sc, min: 20, max: 28);
                        final headerIcon = _sz(22, sc, min: 20, max: 26);

                        final searchFont = _sz(14, sc, min: 13, max: 16);
                        final listTitle = _sz(15, sc, min: 13.5, max: 17);

                        return CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(hp, 14, hp, 0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.white
                                                    .withValues(alpha: 0.07)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isDarkMode
                                                  ? Colors.white.withValues(
                                                      alpha: 0.09,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.06,
                                                    ),
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.arrow_back_rounded,
                                              color: isDarkMode
                                                  ? Colors.white.withValues(
                                                      alpha: 0.88,
                                                    )
                                                  : const Color(0xFF252733),
                                              size: headerIcon - 1,
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                        SizedBox(width: gap),
                                        Expanded(
                                          child: Text(
                                            'songs'.tr(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: headerTitle,
                                              fontWeight: FontWeight.w900,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : const Color(0xFF171820),
                                              letterSpacing: -0.7,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.white
                                                    .withValues(alpha: 0.07)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isDarkMode
                                                  ? Colors.white.withValues(
                                                      alpha: 0.09,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.06,
                                                    ),
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              _isGridView
                                                  ? Icons.view_list_rounded
                                                  : Icons.grid_view_rounded,
                                              color: isDarkMode
                                                  ? Colors.white.withValues(
                                                      alpha: 0.88,
                                                    )
                                                  : const Color(0xFF252733),
                                              size: headerIcon - 1,
                                            ),
                                            onPressed: () => setState(
                                              () => _isGridView = !_isGridView,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: _sz(12, sc, min: 8, max: 16),
                                    ),
                                    _buildSearchBar(isDarkMode, searchFont),
                                    SizedBox(
                                      height: _sz(10, sc, min: 8, max: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(hp, 6, hp, 6),
                                child: Row(
                                  children: [
                                    Text(
                                      'all_songs'.tr(),
                                      style: TextStyle(
                                        fontSize: _sz(16, sc, min: 14, max: 18),
                                        fontWeight: FontWeight.w800,
                                        color: isDarkMode
                                            ? Colors.white
                                            : const Color(0xFF171820),
                                        letterSpacing: -0.35,
                                      ),
                                    ),
                                    SizedBox(
                                      width: _sz(10, sc, min: 8, max: 12),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            _sz(12, sc, min: 10, max: 14),
                                        vertical: _sz(6, sc, min: 5, max: 7),
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.white
                                                .withValues(alpha: 0.07)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: isDarkMode
                                              ? Colors.white
                                                  .withValues(alpha: 0.08)
                                              : Colors.black
                                                  .withValues(alpha: 0.05),
                                        ),
                                      ),
                                      child: Text(
                                        '${visibleSongs.length}',
                                        style: TextStyle(
                                          fontSize:
                                              _sz(13, sc, min: 12, max: 14),
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode
                                              ? Colors.white
                                                  .withValues(alpha: 0.85)
                                              : Colors.black
                                                  .withValues(alpha: 0.80),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (visibleSongs.isEmpty && !vm.isLoading)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildEmptyState(isDarkMode, sc),
                              )
                            else ...[
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: hp),
                                sliver: _isGridView
                                    ? _buildSongsGrid(
                                        songs: visibleSongs,
                                        isConnected: isConnected,
                                        bluetoothBloc: bluetoothBloc,
                                        isDarkMode: isDarkMode,
                                        cols: cols,
                                        spacing: gap,
                                        mainExtent: gridExtent,
                                        sc: sc,
                                      )
                                    : _buildSongsList(
                                        songs: visibleSongs,
                                        isConnected: isConnected,
                                        bluetoothBloc: bluetoothBloc,
                                        isDarkMode: isDarkMode,
                                        sc: sc,
                                        listTitleFont: listTitle,
                                      ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 80),
                                  child: vm.isLoading
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirection: 1.57,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.06,
                    numberOfParticles: 40,
                    maxBlastForce: 90,
                    minBlastForce: 65,
                    gravity: 0.25,
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
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode, double fontSize) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              isDarkMode ? Colors.white.withValues(alpha: 0.065) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.09)
                : Colors.black.withValues(alpha: 0.055),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.14 : 0.045),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: fontSize,
          ),
          decoration: InputDecoration(
            hintText: 'search_songs'.tr(),
            hintStyle: TextStyle(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.50)
                  : Colors.black.withValues(alpha: 0.50),
              fontSize: fontSize,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.9),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.70)
                          : Colors.black.withValues(alpha: 0.70),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          ),
        ),
      );

  SliverList _buildSongsList({
    required List<SongV2Model> songs,
    required bool isConnected,
    required BluetoothBloc bluetoothBloc,
    required bool isDarkMode,
    required double sc,
    required double listTitleFont,
  }) =>
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = songs[index];
            final isLocked = _isSongLockedSync(song, isConnected);

            return Padding(
              padding: EdgeInsets.only(bottom: _sz(12, sc, min: 10, max: 14)),
              child: _buildModernSongCard(
                context: context,
                song: song,
                isConnected: isConnected,
                bluetoothBloc: bluetoothBloc,
                isLocked: isLocked,
                isDarkMode: isDarkMode,
                sc: sc,
                titleFont: listTitleFont,
              ),
            );
          },
          childCount: songs.length,
        ),
      );

  SliverGrid _buildSongsGrid({
    required List<SongV2Model> songs,
    required bool isConnected,
    required BluetoothBloc bluetoothBloc,
    required bool isDarkMode,
    required int cols,
    required double spacing,
    required double mainExtent,
    required double sc,
  }) =>
      SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final song = songs[index];
            final isLocked = _isSongLockedSync(song, isConnected);

            return _buildGridSongCard(
              context: context,
              song: song,
              isConnected: isConnected,
              bluetoothBloc: bluetoothBloc,
              isLocked: isLocked,
              isDarkMode: isDarkMode,
              sc: sc,
            );
          },
          childCount: songs.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisExtent: mainExtent,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
      );

  Widget _buildModernSongCard({
    required BuildContext context,
    required SongV2Model song,
    required bool isConnected,
    required BluetoothBloc bluetoothBloc,
    required bool isLocked,
    required bool isDarkMode,
    required double sc,
    required double titleFont,
  }) =>
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () =>
              _onSongTap(song, isConnected, bluetoothBloc, vm, isLocked),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: EdgeInsets.all(_sz(14, sc, min: 13, max: 17)),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.13 : 0.04,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: _sz(52, sc, min: 48, max: 58),
                  height: _sz(52, sc, min: 48, max: 58),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(
                      alpha: isDarkMode ? 0.20 : 0.11,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.play_arrow_rounded,
                    color: isDarkMode
                        ? const Color(0xFFB8B0FF)
                        : const Color(0xFF6C5CE7),
                    size: _sz(23, sc, min: 21, max: 26),
                  ),
                ),
                SizedBox(width: _sz(13, sc, min: 11, max: 16)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleFont,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF171820),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: _sz(12, sc, min: 11, max: 13),
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.46)
                              : const Color(0xFF171820).withValues(alpha: 0.48),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          _buildInfoChip(
                            icon: Icons.speed_rounded,
                            label: '${song.bpm} BPM',
                            isDarkMode: isDarkMode,
                            sc: sc,
                          ),
                          SizedBox(width: _sz(7, sc, min: 6, max: 9)),
                          _buildInfoChip(
                            icon: Icons.timer_outlined,
                            label: _durationText(song.durationMs),
                            isDarkMode: isDarkMode,
                            sc: sc,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: _sz(8, sc, min: 6, max: 10)),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.22),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildGridSongCard({
    required BuildContext context,
    required SongV2Model song,
    required bool isConnected,
    required BluetoothBloc bluetoothBloc,
    required bool isLocked,
    required bool isDarkMode,
    required double sc,
  }) =>
      GestureDetector(
        onTap: () => _onSongTap(song, isConnected, bluetoothBloc, vm, isLocked),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(_sz(20, sc, min: 18, max: 22)),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDarkMode ? 0.13 : 0.04,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_sz(20, sc, min: 18, max: 22)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _sz(62, sc, min: 56, max: 68),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(
                            alpha: isDarkMode ? 0.20 : 0.10,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: _sz(38, sc, min: 34, max: 44),
                            height: _sz(38, sc, min: 34, max: 44),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.music_note_rounded,
                              size: _sz(21, sc, min: 19, max: 24),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.55),
                            child: Center(
                              child: Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: _sz(24, sc, min: 20, max: 30),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(_sz(8, sc, min: 6, max: 12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _sz(12, sc, min: 11, max: 14),
                            fontWeight: FontWeight.w800,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF171820),
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _sz(11, sc, min: 10, max: 13),
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.46)
                                : const Color(0xFF171820)
                                    .withValues(alpha: 0.48),
                            height: 1.05,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoChip(
                                icon: Icons.speed_rounded,
                                label: '${song.bpm} BPM',
                                isDarkMode: isDarkMode,
                                sc: sc,
                              ),
                            ),
                            SizedBox(width: _sz(6, sc, min: 6, max: 10)),
                            _buildInfoChip(
                              icon: Icons.timer_outlined,
                              label: _durationText(song.durationMs),
                              isDarkMode: isDarkMode,
                              sc: sc,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required double sc,
  }) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: _sz(6, sc, min: 5, max: 8),
          vertical: _sz(3, sc, min: 2, max: 4),
        ),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFFF2F1F8),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: _sz(11.5, sc, min: 10, max: 13),
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.60)
                  : Colors.black.withValues(alpha: 0.60),
            ),
            SizedBox(width: _sz(3, sc, min: 2, max: 5)),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _sz(11, sc, min: 10, max: 12.5),
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.65)
                      : Colors.black.withValues(alpha: 0.65),
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState(bool isDarkMode, double sc) => Container(
        padding: EdgeInsets.all(_sz(32, sc, min: 24, max: 44)),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(_sz(26, sc, min: 20, max: 34)),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(
                  alpha: isDarkMode ? 0.18 : 0.10,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.library_music_rounded,
                size: _sz(48, sc, min: 42, max: 56),
                color: isDarkMode
                    ? const Color(0xFFB8B0FF)
                    : const Color(0xFF6C5CE7),
              ),
            ),
            SizedBox(height: _sz(18, sc, min: 14, max: 22)),
            Text(
              _lastSearch.isNotEmpty ? 'no_songs_found'.tr() : 'empty'.tr(),
              style: TextStyle(
                fontSize: _sz(22, sc, min: 18, max: 26),
                fontWeight: FontWeight.w900,
                color: isDarkMode ? Colors.white : const Color(0xFF171820),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _sz(10, sc, min: 8, max: 14)),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _sz(40, sc, min: 24, max: 56),
              ),
              child: Text(
                _lastSearch.isNotEmpty
                    ? 'search_not_found_desc'.tr()
                    : 'Explore amazing songs and beats',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _sz(15, sc, min: 13, max: 17),
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.70)
                      : Colors.black.withValues(alpha: 0.70),
                ),
              ),
            ),
            if (_lastSearch.isNotEmpty) ...[
              SizedBox(height: _sz(20, sc, min: 16, max: 24)),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/song-request',
                  arguments: _lastSearch,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: EdgeInsets.symmetric(
                    horizontal: _sz(22, sc, min: 18, max: 28),
                    vertical: _sz(13, sc, min: 11, max: 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'request_song'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
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
