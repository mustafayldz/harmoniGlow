import 'package:flutter/material.dart';
import 'package:harmoniglow/mock_service/api_service.dart';
import 'package:harmoniglow/models/shuffle_model.dart';

class ShuffleMode extends StatefulWidget {
  const ShuffleMode({super.key});

  @override
  State<ShuffleMode> createState() => _ShuffleModeState();
}

class _ShuffleModeState extends State<ShuffleMode>
    with SingleTickerProviderStateMixin {
  final MockApiService _apiService = MockApiService();

  // State variables
  int? duration;
  double? bpm;
  bool isPlaying = false;
  late AnimationController _controller;
  ShuffleModel? selectedShuffleModel;
  List<ShuffleModel> shuffleList = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..stop();
    getShuffleList(); // Fetch the list on initialization
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> getShuffleList() async {
    final List<ShuffleModel>? fetchedList = await _apiService.getShuffleList();
    if (fetchedList != null) {
      setState(() {
        shuffleList = fetchedList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shuffle Mode'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shuffleList.isNotEmpty)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButtonFormField<ShuffleModel>(
                      value: selectedShuffleModel,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Music Type',
                        labelStyle: TextStyle(fontSize: 16),
                      ),
                      items: shuffleList.map((ShuffleModel model) {
                        return DropdownMenuItem<ShuffleModel>(
                          value: model,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(int.parse(model.color!)),
                                radius: 8,
                              ),
                              const SizedBox(width: 10),
                              Text(model.name!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (ShuffleModel? newValue) {
                        setState(() {
                          selectedShuffleModel = newValue;
                          bpm = newValue?.bpm?.toDouble();
                        });
                      },
                      dropdownColor: Colors.white,
                    ),
                  ),
                )
              else
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
              if (selectedShuffleModel != null) ...[
                AnimatedOpacity(
                  opacity: selectedShuffleModel != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How long will you play? (minutes)',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter duration',
                          ),
                          onChanged: (value) {
                            setState(() {
                              duration = int.tryParse(value);
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        if (duration != null && duration! > 0) ...[
                          Text(
                            'BPM (Beats Per Minute): ${bpm?.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Slider(
                            value: bpm ?? 60,
                            min: 40,
                            max: 200,
                            divisions: 160,
                            label: bpm?.toStringAsFixed(0),
                            onChanged: (value) {
                              setState(() {
                                bpm = value;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isPlaying)
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _PulsePainter(_controller.value,
                                  selectedShuffleModel: selectedShuffleModel!),
                              child: const SizedBox(
                                width: 200,
                                height: 200,
                              ),
                            );
                          },
                        ),
                      GestureDetector(
                        onTap: duration != null && duration! > 0
                            ? () {
                                setState(() {
                                  isPlaying = !isPlaying;
                                  if (isPlaying) {
                                    _controller.repeat();
                                  } else {
                                    _controller.stop();
                                  }
                                });
                              }
                            : null,
                        child: CircleAvatar(
                          radius: 75,
                          backgroundColor: duration != null && duration! > 0
                              ? Color(int.parse(selectedShuffleModel!.color!))
                              : Colors.grey,
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final ShuffleModel selectedShuffleModel;

  _PulsePainter(this.progress, {required this.selectedShuffleModel});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Color(int.parse(selectedShuffleModel.color!))
          .withOpacity(1 - progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final double radius = size.width / 2;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        size.center(Offset.zero),
        radius * progress * i,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
