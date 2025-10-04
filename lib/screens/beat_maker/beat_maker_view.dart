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
  BeatMakerViewmodel? vm;
  bool isRecording = false;
  bool _disposed = false;

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
    _initializeViewModel();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializeViewModel() {
    try {
      vm = BeatMakerViewmodel();
    } catch (e) {
      debugPrint('Error initializing BeatMakerViewmodel: \$e');
    }
  }

  @override
  void dispose() {
    _disposed = true;

    try {
      vm?.disposeAll();
    } catch (e) {
      debugPrint('Error disposing BeatMakerViewmodel: \$e');
    }

    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (e) {
      debugPrint('Error resetting orientation: \$e');
    }

    super.dispose();
  }

  void _safeRecordingToggle() {
    if (_disposed || vm == null) return;

    try {
      setState(() => isRecording = !isRecording);
      if (isRecording) {
        vm!.startRecording();
      } else {
        vm!.stopRecording(context);
      }
    } catch (e) {
      debugPrint('Error toggling recording: \$e');
      if (mounted) {
        setState(() => isRecording = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (vm == null) {
      return Scaffold(
        appBar: AppBar(title: Text('makeYourOwnBeat'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
          try {
            vm?.disposeAll();
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          } catch (e) {
            debugPrint('Error in PopScope callback: \$e');
          }
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
                onTap: _safeRecordingToggle,
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
                  vm: vm!,
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
  Offset? position;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    _loadPosition();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadPosition() async {
    if (_disposed) return;

    try {
      final saved = await StorageService().loadDrumPosition(widget.drumKey);
      if (saved != null && mounted && !_disposed) {
        setState(() => position = saved);
      }
    } catch (e) {
      debugPrint('Error loading drum position for ${widget.drumKey}: \$e');
    }
  }

  Future<void> _savePosition(Offset newPosition) async {
    if (_disposed) return;

    try {
      await StorageService().saveDrumPosition(widget.drumKey, newPosition);
    } catch (e) {
      debugPrint('Error saving drum position for ${widget.drumKey}: \$e');
    }
  }

  void _onTap() {
    if (_disposed) return;

    try {
      widget.vm.playSound(context, widget.drumKey);
    } catch (e) {
      debugPrint('Error playing sound for ${widget.drumKey}: \$e');
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_disposed || position == null) return;

    try {
      final screenSize = MediaQuery.of(context).size;
      final double pieceSize = screenSize.width * widget.scale;

      final Offset newPosition = position! + details.delta;
      final double maxX = screenSize.width - pieceSize;
      final double maxY = screenSize.height - pieceSize;

      final clampedPosition = Offset(
        newPosition.dx.clamp(0.0, maxX),
        newPosition.dy.clamp(0.0, maxY),
      );

      if (mounted && !_disposed) {
        setState(() => position = clampedPosition);
        _savePosition(clampedPosition);
      }
    } catch (e) {
      debugPrint('Error updating drum position for ${widget.drumKey}: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_disposed || position == null) {
      return const SizedBox.shrink();
    }

    final screenSize = MediaQuery.of(context).size;
    final double pieceSize = screenSize.width * widget.scale;

    return Positioned(
      left: position!.dx,
      top: position!.dy,
      child: GestureDetector(
        onTap: _onTap,
        onPanUpdate: _onPanUpdate,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              widget.imagePath,
              semanticLabel: widget.drumKey,
              width: pieceSize,
              height: pieceSize,
              errorBuilder: (context, error, stackTrace) => Container(
                width: pieceSize,
                height: pieceSize,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.music_note,
                  size: pieceSize * 0.5,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Text(
              widget.drumKey.toUpperCase(),
              style: TextStyle(
                fontSize: pieceSize * 0.08,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black54,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
