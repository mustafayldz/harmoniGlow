import 'package:flutter/material.dart';
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

    for (int i = 0; i < drumPartKeys.length; i++) {
      if (loadedLedData.isNotEmpty &&
          loadedLedData[i]["red"] != 0 &&
          loadedLedData[i]["green"] != 0 &&
          loadedLedData[i]["blue"] != 0) {
        redValues[i] = loadedLedData[i]["red"];
        greenValues[i] = loadedLedData[i]["green"];
        blueValues[i] = loadedLedData[i]["blue"];
      } else {
        // Set default values from DrumParts if no user input or RGB values are [0, 0, 0]
        List<int> defaultRgb =
            (DrumParts.drumParts[drumPartKeys[i]]!["rgb"] as List).cast<int>();
        redValues[i] = defaultRgb[0];
        greenValues[i] = defaultRgb[1];
        blueValues[i] = defaultRgb[2];
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RGB LED Drum Controller'),
      ),
      body: ListView.builder(
        itemCount: drumPartKeys.length,
        itemBuilder: (context, index) {
          String key = drumPartKeys[index];
          String drumName = DrumParts.drumParts[key]!['name'].toString();

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
            String ledName = DrumParts.drumParts[key]!['name'].toString();
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
          await prefs.saveAllLedData(ledData);
        },
        child: const Icon(Icons.send),
      ),
    );
  }
}
