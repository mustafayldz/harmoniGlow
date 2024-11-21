import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/constants.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/shared/countdown.dart';

class RGBPicker extends StatefulWidget {
  final int partNumber;
  const RGBPicker({super.key, required this.partNumber});

  @override
  RGBPickerState createState() => RGBPickerState();
}

class RGBPickerState extends State<RGBPicker> {
  Color _currentColor = Colors.white;
  final prefs = StorageService();
  final drumPartKeys = DrumParts.drumParts.keys.toList();

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    return Column(
      children: [
        Text('Select RGB values for part ${widget.partNumber}:'),
        const SizedBox(height: 10),
        ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: (Color color) {
            setState(() {
              _currentColor = color;
            });
          },
          pickerAreaHeightPercent: 0.8,
          pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10.0)),
          displayThumbColor: true,
          labelTypes: const [],
          enableAlpha: false,
        ),

        // test button
        ElevatedButton(
          onPressed: () async {
            int red = _currentColor.red;
            int green = _currentColor.green;
            int blue = _currentColor.blue;

            List<int> rgb = [red, green, blue];
            String key = drumPartKeys[widget.partNumber];
            String drumName = DrumParts.drumParts[key]!['name'].toString();

            prefs.saveRgbForDrumPart(drumName, rgb);

            Map<String, dynamic> batchMessage = {
              'notes': [widget.partNumber],
              'rgb': [
                rgb,
              ],
            };

            final String jsonString = '${jsonEncode(batchMessage)}\n';
            final List<int> data = utf8.encode(jsonString);

            _sendLongData(bluetoothBloc, data);

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Countdown();
              },
            );

            // Turn off the light
            Map<String, dynamic> offMessage = {
              'notes': [widget.partNumber],
              'rgb': [
                [0, 0, 0]
              ],
            };

            final String offJsonString = '${jsonEncode(offMessage)}\n';
            final List<int> offData = utf8.encode(offJsonString);

            await _sendLongData(bluetoothBloc, offData);
          },
          child: Text('Shine ${widget.partNumber}. light'),
        ),
      ],
    );
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
