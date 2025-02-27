import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/models/drum_model.dart';
import 'package:harmoniglow/shared/countdown.dart';
import 'package:harmoniglow/shared/custom_button.dart';
import 'package:harmoniglow/shared/send_data.dart';

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
  Widget build(BuildContext context) => Scaffold(
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
                  color: Colors.deepPurpleAccent.withValues(alpha: (0.1 * 255)),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(16),
                child: DropdownButton<DrumModel>(
                  isExpanded: true,
                  hint: const Text(
                    'Select Drum Part',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
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
                      ?.map<DropdownMenuItem<DrumModel>>(
                        (DrumModel drum) => DropdownMenuItem<DrumModel>(
                          value: drum,
                          child: Text(
                            drum.name ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
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
                                  pickerAreaBorderRadius:
                                      const BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  label: 'Shine and Save',
                                  onPress: () async {
                                    await _sendColorData(
                                      selectedDrumPart!,
                                      _selectedColor,
                                    );
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

  Future<void> _sendColorData(DrumModel drumPart, Color color) async {
    final bluetoothBloc = context.read<BluetoothBloc>();
    final DrumModel updatedDrumPart = DrumModel(
      led: drumPart.led,
      name: drumPart.name,
      rgb: [color.r.toInt(), color.g.toInt(), color.b.toInt()],
    );

    await StorageService.saveDrumPart(drumPart.led.toString(), updatedDrumPart);

    final Map<String, dynamic> batchMessage = {
      'notes': [drumPart.led],
      'rgb': [
        [color.r.toInt(), color.g.toInt(), color.b.toInt()],
      ],
    };

    final String jsonString = '${jsonEncode(batchMessage)}\n';
    final List<int> data = utf8.encode(jsonString);

    await SendData().sendLongData(bluetoothBloc, data);
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Countdown(),
    );

    // Turn off the light
    final Map<String, dynamic> offMessage = {
      'notes': [drumPart.led],
      'rgb': [
        [0, 0, 0],
      ],
    };

    final String offJsonString = '${jsonEncode(offMessage)}\n';
    final List<int> offData = utf8.encode(offJsonString);

    await SendData().sendLongData(bluetoothBloc, offData);
  }
}
