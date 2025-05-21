import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/my_beats/my_beats_viewmodel.dart';
import 'package:drumly/screens/player/player_view_my_beat.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyBeatsView extends StatefulWidget {
  const MyBeatsView({super.key});

  @override
  State<MyBeatsView> createState() => _MyBeatsViewState();
}

class _MyBeatsViewState extends State<MyBeatsView> {
  late final MyBeatsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MyBeatsViewModel();
    viewModel.loadBeats();
  }

  Future<void> _openPlayerSheet(
    BluetoothBloc bluetoothBloc,
    beat,
  ) async {
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
                    builder: (context, scrollCtrl) => BeatMakerPlayerView(beat),
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

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();

    return ChangeNotifierProvider<MyBeatsViewModel>.value(
      value: viewModel,
      child: Consumer<MyBeatsViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: AppBar(
            title: const Text('My Beats').tr(),
          ),
          body: vm.beats.isEmpty
              ? Center(
                  child: Image.asset(
                    'assets/images/empty/my_beats_empty.png',
                    width: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: vm.beats.length,
                  itemBuilder: (context, index) {
                    final beat = vm.beats[index];
                    final key = vm.beatKeys[index];

                    return GestureDetector(
                      onTap: () => _openPlayerSheet(bluetoothBloc, beat),
                      child: Dismissible(
                        key: Key(beat.beatId ?? key.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await vm.deleteBeatAt(index);
                          showClassicSnackBar(context, 'Beat deleted'.tr());
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        beat.title ?? 'No title'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      '${beat.bpm ?? 0} BPM',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${beat.genre ?? 'Unknown genre'.tr()} • ${beat.durationSeconds ?? 0}s',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Created: ${DateFormat.yMMMd().format(beat.createdAt)}'
                                        .tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
