import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/screens/player/player_view_my_beat.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class MyBeatsView extends StatefulWidget {
  const MyBeatsView({super.key});

  @override
  State<MyBeatsView> createState() => _MyBeatsViewState();
}

class _MyBeatsViewState extends State<MyBeatsView> {
  List<BeatMakerModel> _beats = [];
  List<dynamic> _beatKeys = [];

  @override
  void initState() {
    super.initState();
    _loadBeats();
  }

  Future<void> _loadBeats() async {
    final lazyBox = Hive.lazyBox<BeatMakerModel>(Constants.beatRecordsBox);

// tüm key'leri al
    final keys = lazyBox.keys.toList();

// değerleri async olarak getir
    final beats = <BeatMakerModel>[];
    for (var key in keys) {
      final beat = await lazyBox.get(key);
      if (beat != null) beats.add(beat);
    }

    setState(() {
      _beats = beats;
      _beatKeys = keys;
    });
  }

  Future<void> _openPlayerSheet(
    BluetoothBloc bluetoothBloc,
    BeatMakerModel beat,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Beats'),
      ),
      body: _beats.isEmpty
          ? const Center(child: Text('No beats found'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: _beats.length,
              itemBuilder: (context, index) {
                final beat = _beats[index];
                final key = _beatKeys[index];

                return GestureDetector(
                  onTap: () async {
                    await _openPlayerSheet(bluetoothBloc, beat);
                  },
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
                      final lazyBox = Hive.lazyBox<BeatMakerModel>(
                        Constants.beatRecordsBox,
                      );
                      final key = _beatKeys[index];

                      await lazyBox.delete(key);

                      setState(() {
                        _beats.removeAt(index);
                        _beatKeys.removeAt(index);
                      });

                      showClassicSnackBar(context, 'Beat deleted');
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    beat.title ?? 'No title',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  '${beat.bpm ?? 0} BPM',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${beat.genre ?? 'Unknown genre'} • ${beat.durationSeconds ?? 0}s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Created: ${DateFormat.yMMMd().format(beat.createdAt)}',
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
    );
  }
}
