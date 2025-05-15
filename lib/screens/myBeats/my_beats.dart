import 'package:drumly/constants.dart';
import 'package:drumly/hive/models/beat_maker_model.dart';
import 'package:drumly/shared/common_functions.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
    final box = await Hive.openBox<BeatMakerModel>(Constants.beatRecordsBox);
    final beats = box.values.toList();
    final keys = box.keys.toList();

    setState(() {
      _beats = beats;
      _beatKeys = keys;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Beats'),
        ),
        body: _beats.isEmpty
            ? const Center(child: Text('No beats found'))
            : ListView.builder(
                itemCount: _beats.length,
                itemBuilder: (context, index) {
                  final beat = _beats[index];
                  final key = _beatKeys[index];

                  return Dismissible(
                    key: Key(beat.beatId ?? key.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      final box = await Hive.openBox<BeatMakerModel>(
                        Constants.beatRecordsBox,
                      );
                      await box.delete(key);

                      setState(() {
                        _beats.removeAt(index);
                        _beatKeys.removeAt(index);
                      });

                      showClassicSnackBar(
                        context,
                        'Beat deleted',
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(beat.title ?? 'No title'),
                        subtitle: Text(
                          '${beat.genre ?? ''} • ${beat.bpm ?? 0} BPM',
                        ),
                        trailing: Text('${beat.durationSeconds ?? 0}s'),
                        children: [
                          if (beat.notes == null || beat.notes!.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No notes recorded'),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: beat.notes!.map((note) {
                                  final leds = note.led.join(', ');
                                  return ListTile(
                                    dense: true,
                                    title: Text('LED: $leds'),
                                    subtitle: Text(
                                      'Started: ${note.sM}ms • Ended: ${note.eM}ms',
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
}
