import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/models/drum_model.dart';
import 'package:harmoniglow/screens/setting/drum_painter.dart';

class DrumAdjustment extends StatefulWidget {
  const DrumAdjustment({super.key});

  @override
  DrumAdjustmentState createState() => DrumAdjustmentState();
}

class DrumAdjustmentState extends State<DrumAdjustment> {
  List<DrumModel>? drumParts = [];
  DrumModel? currentDrumPart;
  Offset? _tapPosition;
  final String drumImagePath = 'assets/images/drum.png';

  @override
  void initState() {
    super.initState();
    checkSavedRgbValues();
  }

  void checkSavedRgbValues() async {
    drumParts = await StorageService.getDrumPartsBulk();
    for (var element in drumParts!) {
      debugPrint('Loaded: ${element.name} - ${element.led} - ${element.rgb} ');
    }
  }

  void onPartClicked(String partName) {
    debugPrint('$partName ---------------------clicked!');

    if (drumParts != null) {
      currentDrumPart = drumParts!.firstWhere(
        (element) => element.name == partName,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Center(
          child: GestureDetector(
            onTap: () => setState(() {
              currentDrumPart = null;
            }),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double imageWidth = constraints.maxWidth * 0.8;
                final double imageHeight = imageWidth * 0.6;
                return Column(
                  children: [
                    GestureDetector(
                      onTapUp: (TapUpDetails details) {
                        final RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        final Offset localPosition =
                            renderBox.globalToLocal(details.globalPosition);

                        setState(() {
                          _tapPosition = localPosition;
                        });
                        DrumPainter(
                          tapPosition: _tapPosition,
                          onTapPart: onPartClicked,
                          imageSize: Size(imageWidth, imageHeight),
                          partColors: drumParts,
                        ).detectTap(localPosition);
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              drumImagePath,
                            ),
                          ),
                          CustomPaint(
                            painter: DrumPainter(
                              tapPosition: _tapPosition,
                              onTapPart: onPartClicked,
                              imageSize: Size(imageWidth, imageHeight),
                              partColors: drumParts,
                            ),
                            child: SizedBox(
                              width: imageWidth,
                              height: imageHeight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              if (currentDrumPart != null)
                                Column(
                                  children: [
                                    Text(
                                      '${currentDrumPart!.name}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ColorPicker(
                                      onColorChanged: (Color color) async {
                                        await StorageService.saveDrumPart(
                                          currentDrumPart!.led.toString(),
                                          currentDrumPart!,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
}
