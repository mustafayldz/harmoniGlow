import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/models/drum_model.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:harmoniglow/shared/custom_button.dart';

class RgbLedsScreen extends StatefulWidget {
  const RgbLedsScreen({super.key});

  @override
  RgbLedsScreenState createState() => RgbLedsScreenState();
}

class RgbLedsScreenState extends State<RgbLedsScreen> {
  List<Color> _currentColors = []; // To store color for each DrumModel
  List<DrumModel>? loadedLedData = [];

  @override
  void initState() {
    super.initState();
    checkSavedRgbValues();
  }

  // Load saved RGB values
  void checkSavedRgbValues() async {
    loadedLedData = await StorageService.getDrumPartsBulk();
    _currentColors = loadedLedData?.map((drum) {
          return Color.fromRGBO(
            drum.rgb?[0] ?? 0,
            drum.rgb?[1] ?? 0,
            drum.rgb?[2] ?? 0,
            1.0,
          );
        }).toList() ??
        [];
    setState(() {});
    loadedLedData = await StorageService.getDrumPartsBulk();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RGB LED Drum Controller'),
      ),
      body: ListView.builder(
        itemCount: loadedLedData?.length ?? 0,
        itemBuilder: (context, index) {
          DrumModel drumPart = loadedLedData![index];
          String drumName = drumPart.name ?? 'Unknown';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drumName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ColorPicker(
                    pickerColor: _currentColors[index],
                    onColorChanged: (Color color) {
                      setState(() {
                        _currentColors[index] = color;
                      });
                    },
                    pickerAreaHeightPercent: 0.8,
                    pickerAreaBorderRadius:
                        const BorderRadius.all(Radius.circular(10.0)),
                    displayThumbColor: true,
                    labelTypes: const [],
                    enableAlpha: false,
                  ),
                  GestureDetector(
                    onTap: () async {
                      await _sendColorData(drumPart, _currentColors[index]);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Shine ${drumPart.led}. light',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DeleteAccount(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendColorData(DrumModel drumPart, Color color) async {
    final bluetoothBloc = context.read<BluetoothBloc>();
    DrumModel updatedDrumPart = DrumModel(
      led: drumPart.led,
      name: drumPart.name,
      rgb: [color.red, color.green, color.blue],
    );

    await StorageService.saveDrumPart(drumPart.led.toString(), updatedDrumPart);

    Map<String, dynamic> batchMessage = {
      'notes': [drumPart.led],
      'rgb': [
        [color.red, color.green, color.blue]
      ],
    };

    final String jsonString = '${jsonEncode(batchMessage)}\n';
    final List<int> data = utf8.encode(jsonString);

    await _sendLongData(bluetoothBloc, data);
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Countdown();
      },
    );

    // Turn off the light
    Map<String, dynamic> offMessage = {
      'notes': [drumPart.led],
      'rgb': [
        [0, 0, 0]
      ],
    };

    final String offJsonString = '${jsonEncode(offMessage)}\n';
    final List<int> offData = utf8.encode(offJsonString);

    await _sendLongData(bluetoothBloc, offData);
  }

  Future<void> _sendLongData(BluetoothBloc bloc, List<int> data) async {
    final device = bloc.state.connectedDevice;
    int mtuSize = 20;
    try {
      mtuSize = await device!.mtu.first - 5;
    } catch (error) {
      debugPrint('Error fetching MTU size, using default 20 bytes: $error');
    }

    for (int offset = 0; offset < data.length; offset += mtuSize) {
      final int end =
          (offset + mtuSize < data.length) ? offset + mtuSize : data.length;
      final List<int> chunk = data.sublist(offset, end);

      try {
        // Ensure the characteristic supports writing
        if (bloc.state.characteristic!.properties.write) {
          await bloc.state.characteristic!.write(chunk);
          debugPrint('Chunk sent successfully, offset: $offset');
        } else {
          debugPrint('Error: Characteristic does not support writing.');
        }
      } catch (error) {
        debugPrint('Error sending chunk at offset $offset: $error');
      }
    }
  }
}
