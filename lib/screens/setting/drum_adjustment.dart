import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/models/drum_model.dart';
import 'package:harmoniglow/screens/setting/drum_painter.dart';
import 'package:harmoniglow/shared/custom_button.dart';

class DrumAdjustment extends StatefulWidget {
  const DrumAdjustment({super.key});

  @override
  DrumAdjustmentState createState() => DrumAdjustmentState();
}

class DrumAdjustmentState extends State<DrumAdjustment> {
  List<DrumModel>? drumParts = [];
  DrumModel? currentDrumPart;
  Color _selectedColor = Colors.red;
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

  Future<void> _saveAdjustments() async {
    final DrumModel updatedDrumPart = DrumModel(
      led: currentDrumPart!.led,
      name: currentDrumPart!.name,
      rgb: [
        _selectedColor.r.toInt(),
        _selectedColor.g.toInt(),
        _selectedColor.b.toInt(),
      ],
    );

    await StorageService.saveDrumPart(
        currentDrumPart!.led.toString(), updatedDrumPart);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: Center(
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
                            ColorPicker(
                              pickerColor: _selectedColor,
                              onColorChanged: (Color color) {
                                setState(() {
                                  _selectedColor = color;
                                });
                              },
                              pickerAreaHeightPercent: 0.6,
                              enableAlpha: false,
                              displayThumbColor: true,
                              labelTypes: const [],
                              pickerAreaBorderRadius: const BorderRadius.all(
                                Radius.circular(10.0),
                              ),
                            ),
                            const SizedBox(height: 5),
                            CustomButton(
                              label: 'Shine and Save',
                              onPress: () async {
                                await _saveAdjustments();
                              },
                              color: _selectedColor,
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
      );
}
