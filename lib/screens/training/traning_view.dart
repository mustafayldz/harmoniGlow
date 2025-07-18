import 'package:drumly/screens/training/trraning_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/player/player_view.dart';
import 'package:drumly/screens/training/traning_viewmodel.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:drumly/shared/enums.dart';
import 'package:easy_localization/easy_localization.dart';

class TrainingView extends StatefulWidget {
  const TrainingView({super.key});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView>
    with SingleTickerProviderStateMixin {
  late final TrainingViewModel _viewModel;
  late final TabController _tabController;
  final List<TrainingLevel> trainingLevels = TrainingLevel.values;
  final Set<String> _loadingLevels = {};

  @override
  void initState() {
    super.initState();
    _viewModel = TrainingViewModel();
    _viewModel.context = context;

    _tabController = TabController(length: trainingLevels.length, vsync: this);

    // Sadece beginner seviyesini yükle
    _viewModel.initBeginnerLevel();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      final selectedLevel = trainingLevels[_tabController.index].name;
      final alreadyLoaded = _viewModel.isLevelLoaded(selectedLevel);
      if (!alreadyLoaded && !_loadingLevels.contains(selectedLevel)) {
        _loadingLevels.add(selectedLevel);
        _viewModel.fetchBeats(level: selectedLevel, reset: true).then((_) {
          _loadingLevels.remove(selectedLevel);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider<TrainingViewModel>.value(
      value: _viewModel,
      child: Scaffold(
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
                // Modern App Bar
                _buildModernAppBar(context, isDarkMode),

                // Modern Tab Bar
                _buildModernTabBar(context, isDarkMode),

                // Content
                Expanded(
                  child: _TrainingBody(
                    levels: trainingLevels,
                    tabController: _tabController,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                'training'.tr(),
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

  Widget _buildModernTabBar(BuildContext context, bool isDarkMode) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
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
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          unselectedLabelColor: isDarkMode
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: trainingLevels
              .map(
                (level) => Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(capitalizeFirst(level.name.tr())),
                  ),
                ),
              )
              .toList(),
        ),
      );
}

class _TrainingBody extends StatelessWidget {
  const _TrainingBody({required this.levels, required this.tabController});
  final List<TrainingLevel> levels;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingViewModel>();
    final bluetoothBloc = context.read<BluetoothBloc>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (vm.loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: TabBarView(
        controller: tabController,
        children: levels.map((level) {
          final levelName = level.name;
          final levelBeats = vm.getBeatsForLevel(levelName);

          if (levelBeats.isEmpty && !vm.loading) {
            return _buildEmptyState(isDarkMode);
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              // Enhanced scroll optimization with hasMoreData check
              if (scrollInfo is ScrollEndNotification &&
                  !vm.loading &&
                  vm.hasMoreData(
                    levelName,
                  ) && // Check if more data is available
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200) {
                // Only load if we have some beats already (prevents initial empty state from triggering)
                if (levelBeats.isNotEmpty) {
                  debugPrint('🔄 Loading more beats for level: $levelName');
                  vm.fetchBeats(level: levelName);
                } else {
                  debugPrint(
                    '🚫 Empty beat list, skipping load more for level: $levelName',
                  );
                }
              } else if (scrollInfo is ScrollEndNotification &&
                  !vm.hasMoreData(levelName)) {
                debugPrint(
                  '✋ No more data available for level: $levelName, skipping request',
                );
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                await vm.fetchBeats(level: levelName, reset: true);
              },
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: levelBeats.length +
                    (vm.loading ? 1 : 0), // Add loading indicator
                itemBuilder: (context, index) {
                  // Show loading indicator at the bottom
                  if (index >= levelBeats.length) {
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

                  final beat = levelBeats[index];
                  return _buildModernBeatCard(
                    context,
                    beat,
                    vm,
                    bluetoothBloc,
                    isDarkMode,
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

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
              'No Training Songs',
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
                'Training songs for this level will be loaded automatically.',
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

  Widget _buildModernBeatCard(
    BuildContext context,
    TraningModel beat,
    TrainingViewModel vm,
    bluetoothBloc,
    bool isDarkMode,
  ) =>
      GestureDetector(
        onTap: () async {
          final beatNotes = await vm.getBeatById(beat.beatId!);

          await SendData().sendHexData(bluetoothBloc, splitToBytes(100));
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                              PlayerView(beatNotes),
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
        },
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
                        Icons.play_arrow_rounded,
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
                            beat.title ?? 'unknownTitle'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Training Song',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.black.withValues(alpha: 0.7),
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
                    if (beat.bpm != null)
                      _buildInfoChip(
                        icon: Icons.speed_rounded,
                        label: '${beat.bpm} BPM',
                        isDarkMode: isDarkMode,
                      ),
                    if (beat.bpm != null && beat.durationSeconds != null)
                      const SizedBox(width: 12),
                    if (beat.durationSeconds != null)
                      _buildInfoChip(
                        icon: Icons.timer_outlined,
                        label: vm.formatDuration(beat.durationSeconds),
                        isDarkMode: isDarkMode,
                      ),
                  ],
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
}
