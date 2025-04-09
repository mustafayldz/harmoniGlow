import 'dart:math';

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

  void onPartClicked(BluetoothBloc bluetoothBloc, String partName) {
    debugPrint('$partName ---------------------clicked!');

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
                    DrumPainter(
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
                          drumImagePath,
                        ),
                      ),
                      CustomPaint(
                        painter: DrumPainter(
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
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        sendLightsIndividually(bluetoothBloc);
                                      },
                                      child: const Text(
                                        'Test Each LED Individually',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        sendTestLightsInGroups(
                                          bluetoothBloc,
                                          2,
                                        );
                                      },
                                      child:
                                          const Text('Test 2 LEDs at a Time'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        turnOffAllLights(bluetoothBloc);
                                      },
                                      child: const Text('Turn Off All Lights'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setAllLightsWhite(
                                          bluetoothBloc,
                                          [0xFF, 0xFF, 0xFF],
                                        );
                                      },
                                      child:
                                          const Text('Turn All Lights White'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setAllLightsWhite(
                                          bluetoothBloc,
                                          [0xFF, 0x00, 0x00],
                                        );
                                      },
                                      child: const Text('Turn All Lights Red'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setAllLightsWhite(
                                          bluetoothBloc,
                                          [0x00, 0xFF, 0x00],
                                        );
                                      },
                                      child:
                                          const Text('Turn All Lights Green'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        startCustomAnimation(bluetoothBloc);
                                      },
                                      child: const Text('Run Custom Animation'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        triggerFullFlashAnimation(
                                          bluetoothBloc,
                                        );
                                      },
                                      child: const Text('Flashing Animation'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setBrightness(bluetoothBloc, 1);
                                      },
                                      child: const Text('Set Brightness to 1'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setBrightness(bluetoothBloc, 2);
                                      },
                                      child: const Text('Set Brightness to 2'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setBrightness(bluetoothBloc, 3);
                                      },
                                      child: const Text('Set Brightness to 3'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setBrightness(bluetoothBloc, 4);
                                      },
                                      child: const Text('Set Brightness to 4'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setBrightness(bluetoothBloc, 5);
                                      },
                                      child: const Text('Set Brightness to 5'),
                                    ),
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
    await SendData().sendHexData(bloc, [0x00, 0x00, 0x00, 0x00]);
  }

  Future<void> setAllLightsWhite(BluetoothBloc bloc, List<int> color) async {
    await SendData().sendHexData(bloc, [0x0C, color[0], color[1], color[2]]);
  }

  Future<void> startCustomAnimation(BluetoothBloc bloc) async {
    await SendData().sendHexData(bloc, [0xFB, 0x00, 0x00, 0x00]);
  }

  Future<void> yesil(BluetoothBloc bloc) async {
    await SendData().sendHexData(bloc, [0x0C, 0x00, 0xFF, 0x00]);
  }

  Future<void> triggerFullFlashAnimation(BluetoothBloc bloc) async {
    final random = Random();
    final ledCount = 8;

    // 1️⃣ Rastgele renklerle tüm LED'leri yak
    final activeLeds = <List<int>>[];
    for (int i = 1; i <= ledCount; i++) {
      final r = random.nextInt(256);
      final g = random.nextInt(256);
      final b = random.nextInt(256);
      final cmd = [i, r, g, b];
      activeLeds.add(cmd);
      await SendData().sendHexData(bloc, cmd);
    }

    // 2️⃣ 5 saniye bekle
    await Future.delayed(const Duration(seconds: 5));

    // 3️⃣ Sırayla her LED’i flash animasyonla kapat
    for (final cmd in activeLeds) {
      final ledId = cmd[0];
      final r = cmd[1], g = cmd[2], b = cmd[3];

      for (int j = 0; j < 3; j++) {
        await SendData().sendHexData(bloc, [ledId, r, g, b]); // Aç
        await Future.delayed(const Duration(milliseconds: 100));
        await SendData().sendHexData(bloc, [ledId, 0x00, 0x00, 0x00]); // Kapat
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<void> setBrightness(BluetoothBloc bloc, int level) async {
    if (level < 1) level = 1;
    if (level > 5) level = 5;
    await SendData().sendHexData(bloc, [0xFE, level, 0x00, 0x00]);
  }
}
