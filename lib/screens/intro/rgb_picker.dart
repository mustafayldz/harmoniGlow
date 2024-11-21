import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/mock_service/local_service.dart';
import 'package:harmoniglow/models/drum_model.dart';
import 'package:harmoniglow/shared/countdown.dart';

class RGBPicker extends StatefulWidget {
  final int partNumber;
  const RGBPicker({super.key, required this.partNumber});

  @override
  RGBPickerState createState() => RGBPickerState();
}

class RGBPickerState extends State<RGBPicker> {
  Color _currentColor = Colors.green;
  DrumModel? rgbValues;

  @override
  void initState() {
    super.initState();

    setDefaultColor();
  }

  Future<void> setDefaultColor() async {
    rgbValues = await StorageService.getDrumPart(widget.partNumber.toString());
    if (rgbValues != null && rgbValues!.rgb != null) {
      setState(() {
        _currentColor = Color.fromRGBO(
          rgbValues!.rgb![0],
          rgbValues!.rgb![1],
          rgbValues!.rgb![2],
          1.0,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();

    if (rgbValues == null) {
      // Show a loading indicator until the RGB values are fetched
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          rgbValues!.name ?? 'Unknown',
        ),
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

        // test light button
        ElevatedButton(
          onPressed: () async {
            // Prepare the drum part model and save it
            DrumModel drumPart = DrumModel(
              led: widget.partNumber,
              name: rgbValues?.name,
              rgb: [
                _currentColor.red,
                _currentColor.green,
                _currentColor.blue,
              ],
            );

            StorageService.saveDrumPart(widget.partNumber.toString(), drumPart);

            // Prepare the batch message to send
            Map<String, dynamic> batchMessage = {
              'notes': [widget.partNumber],
              'rgb': [
                [_currentColor.red, _currentColor.green, _currentColor.blue]
              ],
            };

            final String jsonString = '${jsonEncode(batchMessage)}\n';
            final List<int> data = utf8.encode(jsonString);

            // Send the data
            await _sendLongData(bluetoothBloc, data);

            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Countdown();
              },
            );

            // Prepare the message to turn off the light
            Map<String, dynamic> offMessage = {
              'notes': [widget.partNumber],
              'rgb': [
                [0, 0, 0]
              ],
            };

            final String offJsonString = '${jsonEncode(offMessage)}\n';
            final List<int> offData = utf8.encode(offJsonString);

            // Send the data to turn off the light
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
