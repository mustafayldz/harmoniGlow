import 'package:drumly/screens/training/traning_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/player/player_view.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:provider/provider.dart';

class TrainingView extends StatelessWidget {
  const TrainingView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<TrainingViewModel>(
        create: (_) => TrainingViewModel(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Training'),
            centerTitle: true,
          ),
          body: const _TrainingBody(),
        ),
      );
}

class _TrainingBody extends StatefulWidget {
  const _TrainingBody();

  @override
  State<_TrainingBody> createState() => _TrainingBodyState();
}

class _TrainingBodyState extends State<_TrainingBody> {
  @override
  void initState() {
    super.initState();
    final vm = context.read<TrainingViewModel>();
    vm.context = context;
    vm.fetchBeats();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();

    return Consumer<TrainingViewModel>(
      builder: (context, vm, _) {
        final beats = vm.beats;
        final genres = vm.genres;
        final height = MediaQuery.of(context).size.height;

        // 🎯 Empty state: beats listesi boşsa
        if (beats.isEmpty) {
          return Center(
            child: Image.asset(
              'assets/images/empty/traning_empty.png',
              width: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.contain,
            ),
          );
        }

        // ✅ Beats varsa: genre filtresi + beat listesi
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
                          genres[i].name ?? 'Unnamed',
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
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? Colors.grey[600]
                                                : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.9,
                                      child: DraggableScrollableSheet(
                                        initialChildSize: 1.0,
                                        minChildSize: 0.3,
                                        expand: false,
                                        builder: (context, scrollCtrl) =>
                                            PlayerView(
                                          beat,
                                          isTraning: true,
                                        ),
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
                                    beat.title ?? 'Unknown Title',
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
                                            vm.formatDuration(
                                              beat.durationSeconds,
                                            ),
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
      },
    );
  }
}
