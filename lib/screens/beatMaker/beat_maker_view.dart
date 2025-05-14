import 'package:drumly/screens/beatMaker/beat_maker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BeatMakerView extends StatefulWidget {
  const BeatMakerView({super.key});

  @override
  State<BeatMakerView> createState() => _BeatMakerViewState();
}

class _BeatMakerViewState extends State<BeatMakerView> {
  late final BeatMakerViewmodel vm;
  final imagePath = 'assets/images/cdrumflat.png'; // örnek klasik drum

  // Daire merkez koordinatları (yüzdelik olarak, ekran boyutuna göre)
  final List<Offset> circlePositions = [
    const Offset(0.30, 0.60), // Hi-Hat
    const Offset(0.38, 0.20), // Crash
    const Offset(0.69, 0.265), // Ride
    const Offset(0.39, 0.80), // Snare
    const Offset(0.43, 0.48), // Tom1
    const Offset(0.56, 0.45), // Tom2
    const Offset(0.65, 0.75), // Tom Floor
    const Offset(0.50, 0.77), // Kick
  ];

  final Set<int> tappedCircles = {};

  @override
  void initState() {
    super.initState();
    // Ekranı yatay moda zorla
    vm = BeatMakerViewmodel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Dikey moda geri dön
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Beat Maker'),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Stack(
              children: [
                Center(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    width: width * 0.9,
                  ),
                ),
                ...List.generate(circlePositions.length, (index) {
                  final pos = circlePositions[index];
                  final double circleSize = 100;

                  return Positioned(
                    left: width * pos.dx - circleSize / 2,
                    top: height * pos.dy - circleSize / 2,
                    child: GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          vm.playSound(
                            vm.drumSounds.keys.elementAt(index),
                          );
                          tappedCircles.add(index);
                        });
                      },
                      onTapUp: (_) {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          setState(() {
                            tappedCircles.remove(index);
                          });
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tappedCircles.contains(index)
                              ? Colors.blueAccent.withValues(alpha: 0.5)
                              : Colors.transparent,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
}
