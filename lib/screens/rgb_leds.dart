import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/constants.dart';
import 'package:harmoniglow/mock_service/local_service.dart';

class RgbLedsScreen extends StatefulWidget {
  const RgbLedsScreen({super.key});

  @override
  RgbLedsScreenState createState() => RgbLedsScreenState();
}

class RgbLedsScreenState extends State<RgbLedsScreen> {
  final prefs = StorageService();
  final drumPartKeys = DrumParts.drumParts.keys.toList();

  List<Map<String, dynamic>> loadedLedData = [];

  // RGB values for each LED
  List<int> redValues = List.filled(10, 0);
  List<int> greenValues = List.filled(10, 0);
  List<int> blueValues = List.filled(10, 0);

  // Method to get color for each LED
  Color getSelectedColor(int index) {
    return Color.fromARGB(
      255,
      redValues[index].toInt(),
      greenValues[index].toInt(),
      blueValues[index].toInt(),
    );
  }

  @override
  void initState() {
    checkSavedRgbValues();
    super.initState();
  }

  // Load saved RGB values
  checkSavedRgbValues() async {
    loadedLedData = await prefs.loadAllLedData();

    if (loadedLedData.isNotEmpty) {
      for (int i = 0; i < loadedLedData.length; i++) {
        redValues[i] = loadedLedData[i]["red"];
        greenValues[i] = loadedLedData[i]["green"];
        blueValues[i] = loadedLedData[i]["blue"];
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothBloc = context.read<BluetoothBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('RGB LED Drum Controller'),
      ),
      body: ListView.builder(
        itemCount: drumPartKeys.length,
        itemBuilder: (context, index) {
          String key = drumPartKeys[index];
          String drumName = DrumParts.drumParts[key]!["name"].toString();
          List<int> defaultRgb =
              (DrumParts.drumParts[key]!["rgb"] as List).cast<int>();

          // Set default RGB if no user input
          if (redValues[index] == 0 &&
              greenValues[index] == 0 &&
              blueValues[index] == 0) {
            redValues[index] = defaultRgb[0];
            greenValues[index] = defaultRgb[1];
            blueValues[index] = defaultRgb[2];
          }

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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('R'),
                            Slider(
                              value: redValues[index].toDouble(),
                              min: 0,
                              max: 255,
                              divisions: 255,
                              activeColor: Colors.red,
                              onChanged: (value) {
                                setState(() {
                                  redValues[index] = value.toInt();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('G'),
                            Slider(
                              value: greenValues[index].toDouble(),
                              min: 0,
                              max: 255,
                              divisions: 255,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                setState(() {
                                  greenValues[index] = value.toInt();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('B'),
                            Slider(
                              value: blueValues[index].toDouble(),
                              min: 0,
                              max: 255,
                              divisions: 255,
                              activeColor: Colors.blue,
                              onChanged: (value) {
                                setState(() {
                                  blueValues[index] = value.toInt();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: double.infinity,
                    color: getSelectedColor(index),
                    alignment: Alignment.center,
                    child: const Text(
                      'Selected Color',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          List<Map<String, dynamic>> ledData = [];

          for (int i = 0; i < drumPartKeys.length; i++) {
            String key = drumPartKeys[i];
            String ledName = DrumParts.drumParts[key]!["name"].toString();
            int red = redValues[i].toInt();
            int green = greenValues[i].toInt();
            int blue = blueValues[i].toInt();

            ledData.add({
              "name": ledName,
              "red": red,
              "green": green,
              "blue": blue,
            });
          }

          String jsonData = jsonEncode(ledData);
          List<int> bytes = utf8.encode('$jsonData\n');

          if (bluetoothBloc.state.characteristic != null) {
            try {
              await bluetoothBloc.state.characteristic!
                  .write(bytes, withoutResponse: true);
              debugPrint('Data sent: $jsonData');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data sent successfully!')),
              );
            } catch (e) {
              debugPrint('Failed to send data: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to send data!')),
              );
            }
          } else {
            debugPrint('Bluetooth characteristic is null.');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Bluetooth characteristic not available!')),
            );
          }

          await prefs.saveAllLedData(ledData);
        },
        child: const Icon(Icons.send),
      ),
    );
  }
}
