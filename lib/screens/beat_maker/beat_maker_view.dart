import 'package:drumly/screens/beat_maker/beat_maker_viewmodel.dart';
import 'package:drumly/services/local_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BeatMakerView extends StatefulWidget {
  const BeatMakerView({super.key});

  @override
  State<BeatMakerView> createState() => _BeatMakerViewState();
}

class _BeatMakerViewState extends State<BeatMakerView> {
  late final BeatMakerViewmodel vm;
  bool isRecording = false;

  final List<Map<String, dynamic>> drumPieces = [
    {
      'key': 'Kick Drum',
      'image': 'assets/images/classicDrum/c_kick.png',
      'scale': 0.3,
    },
    {
      'key': 'Tom Floor',
      'image': 'assets/images/classicDrum/c_tom_floor.png',
      'scale': 0.2,
    },
    {
      'key': 'Tom 2',
      'image': 'assets/images/classicDrum/c_tom2.png',
      'scale': 0.15,
    },
    {
      'key': 'Tom 1',
      'image': 'assets/images/classicDrum/c_tom1.png',
      'scale': 0.13,
    },
    {
      'key': 'Snare Drum',
      'image': 'assets/images/classicDrum/c_snare.png',
      'scale': 0.13,
    },
    {
      'key': 'Hi-Hat',
      'image': 'assets/images/classicDrum/c_hihat.png',
      'scale': 0.12,
    },
    {
      'key': 'Crash Cymbal',
      'image': 'assets/images/classicDrum/c_crash.png',
      'scale': 0.17,
    },
    {
      'key': 'Ride Cymbal',
      'image': 'assets/images/classicDrum/c_ride.png',
      'scale': 0.17,
    },
  ];

  @override
  void initState() {
    super.initState();
    vm = BeatMakerViewmodel();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    vm.disposeAll(); // 🎯 player’ları ve timer’ı temizle
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    final initialPositions = [
      Offset(screenWidth * 0.32, screenHeight * 0.30),
      Offset(screenWidth * 0.54, screenHeight * 0.40),
      Offset(screenWidth * 0.48, screenHeight * 0.17),
      Offset(screenWidth * 0.35, screenHeight * 0.20),
      Offset(screenWidth * 0.27, screenHeight * 0.37),
      Offset(screenWidth * 0.16, screenHeight * 0.37),
      Offset(screenWidth * 0.20, screenHeight * 0.03),
      Offset(screenWidth * 0.62, screenHeight * 0.03),
    ];

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          vm.disposeAll(); // 🎯 player’ları ve timer’ı temizle
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('makeYourOwnBeat'.tr()),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  setState(() => isRecording = !isRecording);
                  if (isRecording) {
                    vm.startRecording();
                  } else {
                    vm.stopRecording(context);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.red : Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRecording ? Icons.stop : Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRecording ? 'stop'.tr() : 'record'.tr(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return Center(
                child: Text(
                  'rotateScreen'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Stack(
              children: List.generate(drumPieces.length, (index) {
                final piece = drumPieces[index];
                return DrumPiece(
                  imagePath: piece['image']!,
                  drumKey: piece['key']!,
                  initialPosition: initialPositions[index],
                  vm: vm,
                  scale: piece['scale']!,
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class DrumPiece extends StatefulWidget {
  const DrumPiece({
    required this.imagePath,
    required this.drumKey,
    required this.initialPosition,
    required this.scale,
    required this.vm,
    super.key,
  });

  final String imagePath;
  final String drumKey;
  final Offset initialPosition;
  final double scale;
  final BeatMakerViewmodel vm;

  @override
  State<DrumPiece> createState() => _DrumPieceState();
}

class _DrumPieceState extends State<DrumPiece> {
  late Offset position = widget.initialPosition;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final saved = await StorageService().loadDrumPosition(widget.drumKey);
    if (saved != null && mounted) {
      setState(() => position = saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double pieceSize = screenSize.width * widget.scale;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => widget.vm.playSound(context, widget.drumKey),
        onPanUpdate: (details) async {
          setState(() {
            final Offset newPosition = position + details.delta;
            final double maxX = screenSize.width - pieceSize;
            final double maxY = screenSize.height - pieceSize;

            position = Offset(
              newPosition.dx.clamp(0.0, maxX),
              newPosition.dy.clamp(0.0, maxY),
            );
          });
          await StorageService().saveDrumPosition(widget.drumKey, position);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              widget.imagePath,
              semanticLabel: widget.drumKey,
              width: pieceSize,
              height: pieceSize,
            ),
            Text(
              widget.drumKey.toUpperCase(),
              style: TextStyle(
                fontSize: pieceSize * 0.08,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
