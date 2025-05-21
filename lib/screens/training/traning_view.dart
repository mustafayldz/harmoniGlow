import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/player/player_view.dart';
import 'package:drumly/screens/training/traning_viewmodel.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TrainingView extends StatefulWidget {
  const TrainingView({super.key});

  @override
  State<TrainingView> createState() => _TrainingViewState();
}

class _TrainingViewState extends State<TrainingView> {
  late final TrainingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TrainingViewModel();
    _viewModel.context = context;
    _viewModel.fetchBeats(); // ✅ Verileri ilk açılışta çek
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<TrainingViewModel>.value(
        value: _viewModel,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Training').tr(),
            centerTitle: true,
          ),
          body: const _TrainingBody(),
        ),
      );
}

class _TrainingBody extends StatelessWidget {
  const _TrainingBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingViewModel>();
    final bluetoothBloc = context.read<BluetoothBloc>();
    final beats = vm.beats;
    final genres = vm.genres;
    final height = MediaQuery.of(context).size.height;

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (beats.isEmpty) {
      return Center(
        child: Image.asset(
          'assets/images/empty/traning_empty.png',
          width: MediaQuery.of(context).size.width * 0.8,
          fit: BoxFit.contain,
        ),
      );
    }

    return Column(
      children: [
        if (genres.isNotEmpty)
          SizedBox(
            height: height * 0.06,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              itemBuilder: (_, i) {
                final isSelected = vm.selectedGenreIndex == i;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.grey[200] : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => vm.selectGenre(i),
                    child: Text(
                      genres[i].name ?? 'Unnamed'.tr(),
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: beats.length,
            itemBuilder: (context, index) {
              final beat = beats[index];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await SendData().sendHexData(
                      bluetoothBloc,
                      splitToBytes(100),
                    );

                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
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
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.grey[600]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.9,
                                  child: DraggableScrollableSheet(
                                    initialChildSize: 1.0,
                                    minChildSize: 0.3,
                                    expand: false,
                                    builder: (context, scrollCtrl) =>
                                        PlayerView(beat, isTraning: true),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                beat.title ?? 'Unknown Title'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (beat.bpm != null) ...[
                                    Chip(
                                      label: Text('${beat.bpm} BPM'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (beat.durationSeconds != null) ...[
                                    Chip(
                                      label: Text(
                                        vm.formatDuration(beat.durationSeconds),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
