import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/models/drum_model.dart';
import 'package:harmoniglow/screens/setting/drum_painter.dart';
import 'package:harmoniglow/shared/send_data.dart';

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
    await StorageService.getDrumPartsBulk().then(
      (List<DrumModel>? drumParts) {
        if (drumParts != null) {
          setState(() {
            this.drumParts = drumParts;
          });
        }
      },
    );

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
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();

    return Scaffold(
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
                            if (currentDrumPart != null)
                              Column(
                                children: [
                                  SizedBox(
                                    height: 30,
                                    width: double.infinity,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          '${currentDrumPart!.name}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                currentDrumPart = null;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ColorPicker(
                                    onColorChanged: (Color color) async {
                                      setState(() {
                                        currentDrumPart!.rgb = [
                                          color.red8bit,
                                          color.green8bit,
                                          color.blue8bit,
                                        ];
                                      });
                                      await StorageService.saveDrumPart(
                                        currentDrumPart!.led.toString(),
                                        currentDrumPart!,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            if (currentDrumPart == null)
                              Column(
                                children: [
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendTestLights(bluetoothBloc);
                                    },
                                    child:
                                        const Text('Test Lights individually'),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendTestLightsInPairs(bluetoothBloc, 2);
                                    },
                                    child:
                                        const Text('Test Lights 2 at a time'),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendTestLightsInPairs(bluetoothBloc, 3);
                                    },
                                    child:
                                        const Text('Test Lights 3 at a time'),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendTestLightsInPairs(bluetoothBloc, 4);
                                    },
                                    child:
                                        const Text('Test Lights 4 at a time'),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      sendTestLightsInPairs(bluetoothBloc, 5);
                                    },
                                    child:
                                        const Text('Test Lights 5 at a time'),
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

  void sendTestLights(BluetoothBloc bluetoothBloc) async {
    debugPrint('--------------------Test Lights start-------------------');

    for (var i = 0; i < 8; i++) {
      final DrumModel drumPart = drumParts!.firstWhere(
        (element) => element.led == i,
        orElse: () => DrumModel(name: 'Unknown', led: i, rgb: [0, 0, 0]),
      );

      final List<int> data = [
        i,
        drumPart.rgb![0],
        drumPart.rgb![1],
        drumPart.rgb![2],
      ];

      debugPrint('Sending Data: $data');

      await SendData().sendHexData(bluetoothBloc, data);

      // Wait for 2 seconds before sending the next set of data
      await Future.delayed(const Duration(seconds: 2));
    }

    debugPrint('--------------------Test Lights completed-------------------');
  }

  void sendTestLightsInPairs(
    BluetoothBloc bluetoothBloc,
    int numberofPair,
  ) async {
    debugPrint('--------------------Test Lights start-------------------');

    for (var i = 0; i < 8; i += numberofPair) {
      final List<int> data = [];

      for (var j = 0; j < numberofPair; j++) {
        if (i + j >= 8) break; // Prevent out-of-bounds errors

        final DrumModel drumPart = drumParts!.firstWhere(
          (element) => element.led == (i + j),
          orElse: () =>
              DrumModel(name: 'Unknown', led: (i + j), rgb: [0, 0, 0]),
        );

        data.add((i + j));
        data.addAll(drumPart.rgb!);
      }

      debugPrint('Sending Data: $data');

      await SendData().sendHexData(bluetoothBloc, data);

      // Wait for 2 seconds before sending the next pair
      await Future.delayed(const Duration(seconds: 2));
    }

    debugPrint('--------------------Test Lights completed-------------------');
  }
}
