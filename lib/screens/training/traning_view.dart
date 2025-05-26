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
      if (!alreadyLoaded) {
        _viewModel.fetchBeats(level: selectedLevel, reset: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<TrainingViewModel>.value(
        value: _viewModel,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('training').tr(),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: trainingLevels
                  .map(
                    (level) => Tab(
                      child: Text(
                        capitalizeFirst(level.name.tr()),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          body: _TrainingBody(
            levels: trainingLevels,
            tabController: _tabController,
          ),
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

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: tabController,
      children: levels.map((level) {
        final levelName = level.name;
        final levelBeats = vm.getBeatsForLevel(levelName);

        if (levelBeats.isEmpty && !vm.loading) {
          return Center(
            child: Image.asset(
              'assets/images/empty/traning_empty.png',
              width: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo is ScrollEndNotification &&
                scrollInfo.metrics.pixels >=
                    scrollInfo.metrics.maxScrollExtent - 50) {
              vm.fetchBeats(level: levelName);
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: levelBeats.length,
            itemBuilder: (context, index) {
              final beat = levelBeats[index];

              return _buildBeatCard(context, beat, vm, bluetoothBloc);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBeatCard(
    BuildContext context,
    TraningModel beat,
    TrainingViewModel vm,
    bluetoothBloc,
  ) =>
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beat.title ?? 'Unknown Title'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (beat.bpm != null)
                      Chip(
                        label: Text('${beat.bpm} BPM'),
                      ),
                    const SizedBox(width: 8),
                    if (beat.durationSeconds != null)
                      Chip(
                        label: Text(vm.formatDuration(beat.durationSeconds)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
