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
  List<DrumModel>? loadedLedData = [];
  DrumModel? selectedDrumPart;
  Color _selectedColor = Colors.white;

  @override
  void initState() {
    super.initState();
    checkSavedRgbValues();
  }

  // Load saved RGB values
  void checkSavedRgbValues() async {
    loadedLedData = await StorageService.getDrumPartsBulk();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RGB LED Drum Controller'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16),
              child: DropdownButton<DrumModel>(
                isExpanded: true,
                hint: const Text('Select Drum Part',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                value: selectedDrumPart,
                onChanged: (DrumModel? newValue) {
                  setState(() {
                    selectedDrumPart = newValue;
                    if (newValue != null) {
                      _selectedColor = Color.fromRGBO(
                        newValue.rgb?[0] ?? 0,
                        newValue.rgb?[1] ?? 0,
                        newValue.rgb?[2] ?? 0,
                        1.0,
                      );
                    }
                  });
                },
                items: loadedLedData
                    ?.map<DropdownMenuItem<DrumModel>>((DrumModel drum) {
                  return DropdownMenuItem<DrumModel>(
                    value: drum,
                    child: Text(
                      drum.name ?? 'Unknown',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (selectedDrumPart != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 32),
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
                                    Radius.circular(10.0)),
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                label: 'Shine and Save',
                                onPress: () async {
                                  await _sendColorData(
                                      selectedDrumPart!, _selectedColor);
                                },
                                color: _selectedColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
