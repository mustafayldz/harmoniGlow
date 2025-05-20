import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/provider/app_provider.dart';
import 'package:drumly/screens/my_drum/drum_model.dart';
import 'package:drumly/screens/my_drum/drum_painter.dart';
import 'package:drumly/screens/my_drum/drum_painter_classic.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/shared/send_data.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DrumAdjustment extends StatefulWidget {
  const DrumAdjustment({super.key});

  @override
  DrumAdjustmentState createState() => DrumAdjustmentState();
}

class DrumAdjustmentState extends State<DrumAdjustment> {
  late AppProvider appProvider;

  List<DrumModel>? drumParts = [];
  DrumModel? currentDrumPart;
  Offset? _tapPosition;
  bool isClassic = false;

  @override
  void initState() {
    super.initState();
    appProvider = Provider.of<AppProvider>(context, listen: false);
    checkSavedRgbValues();
  }

  void checkSavedRgbValues() async {
    isClassic = appProvider.isClassic;
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

  void onPartClicked(BluetoothBloc bluetoothBloc, String partName) {
    sendLightsIndividually(bluetoothBloc, partName: partName);

    if (drumParts != null) {
      currentDrumPart = drumParts!.firstWhere(
        (element) => element.name == partName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    final imagePath = appProvider.isClassic
        ? 'assets/images/cdrum.png'
        : 'assets/images/edrum.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: GestureDetector(
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
                    isClassic
                        ? DrumPainterClassic(
                            bluetoothBloc: bluetoothBloc,
                            onTapPart: onPartClicked,
                            imageSize: Size(imageWidth, imageHeight),
                            partColors: drumParts,
                            tapPosition: _tapPosition,
                          ).detectTap(localPosition)
                        : DrumPainter(
                            bluetoothBloc: bluetoothBloc,
                            onTapPart: onPartClicked,
                            imageSize: Size(imageWidth, imageHeight),
                            partColors: drumParts,
                            tapPosition: _tapPosition,
                          ).detectTap(localPosition);
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          imagePath,
                        ),
                      ),
                      CustomPaint(
                        painter: isClassic
                            ? DrumPainterClassic(
                                tapPosition: _tapPosition,
                                onTapPart: onPartClicked,
                                imageSize: Size(imageWidth, imageHeight),
                                partColors: drumParts,
                                bluetoothBloc: bluetoothBloc,
                              )
                            : DrumPainter(
                                tapPosition: _tapPosition,
                                onTapPart: onPartClicked,
                                imageSize: Size(imageWidth, imageHeight),
                                partColors: drumParts,
                                bluetoothBloc: bluetoothBloc,
                              ),
                        child: SizedBox(
                          width: imageWidth,
                          height: imageHeight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: currentDrumPart != null
                          ? Column(
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
                            )
                          : SizedBox(
                              child: Column(
                                spacing: 10,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        sendLightsIndividually(bluetoothBloc);
                                      },
                                      child: const Text(
                                        'Test individual LEDs',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        sendTestLightsInGroups(
                                          bluetoothBloc,
                                          2,
                                        );
                                      },
                                      child: const Text('Test (2 LEDs)'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        turnOnAllLightsRainbow(
                                          bluetoothBloc,
                                        );
                                      },
                                      child: const Text(
                                        'Rainbow',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        turnOffAllLights(bluetoothBloc);
                                      },
                                      child: const Text(
                                        'Turn Off All Lights',
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Brightness Levels',
                                  ),
                                  Row(
                                    spacing: 5,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          setBrightness(bluetoothBloc, 1);
                                        },
                                        child: const Text('1'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setBrightness(bluetoothBloc, 2);
                                        },
                                        child: const Text('2'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setBrightness(bluetoothBloc, 3);
                                        },
                                        child: const Text('3'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setBrightness(bluetoothBloc, 4);
                                        },
                                        child: const Text('4'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setBrightness(bluetoothBloc, 5);
                                        },
                                        child: const Text('5'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Fonksiyonlar:

  Future<void> sendLightsIndividually(
    BluetoothBloc bluetoothBloc, {
    String? partName,
  }) async {
    if (partName != null) {
      final DrumModel? drumPart = drumParts?.firstWhere(
        (element) => element.name == partName,
        orElse: () => DrumModel(name: partName, led: 0, rgb: [0, 0, 0]),
      );

      if (drumPart != null && drumPart.led != 0) {
        final List<int> data = [drumPart.led!, ...drumPart.rgb!];
        await SendData().sendHexData(bluetoothBloc, data);
      } else {
        debugPrint('Drum part "$partName" not found or invalid LED');
      }
    } else {
      for (int i = 1; i < 9; i++) {
        final DrumModel drumPart = drumParts!.firstWhere(
          (element) => element.led == i,
          orElse: () => DrumModel(name: 'Unknown', led: i, rgb: [0, 0, 0]),
        );

        final List<int> data = [i, ...drumPart.rgb!];
        await SendData().sendHexData(bluetoothBloc, data);
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  Future<void> sendTestLightsInGroups(
    BluetoothBloc bluetoothBloc,
    int groupSize,
  ) async {
    final List<DrumModel> parts = drumParts ?? [];

    for (int i = 0; i < parts.length; i += groupSize) {
      final List<int> data = [];

      for (int j = 0; j < groupSize; j++) {
        if (i + j >= parts.length) break;

        final DrumModel drumPart = parts[i + j];

        data.add(drumPart.led!);
        data.addAll(drumPart.rgb!);
      }

      await SendData().sendHexData(bluetoothBloc, data);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> turnOffAllLights(BluetoothBloc bloc) async {
    await SendData().sendHexData(bloc, [0x00]);
  }

  Future<void> turnOnAllLightsRainbow(BluetoothBloc bloc) async {
    await SendData().sendHexData(bloc, [0xFD]);
  }

  Future<void> setBrightness(BluetoothBloc bloc, int level) async {
    if (level < 1) level = 1;
    if (level > 5) level = 5;
    await SendData().sendHexData(bloc, [0xFE, level]);
  }
}
