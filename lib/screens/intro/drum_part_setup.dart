import 'package:flutter/material.dart';
import 'package:harmoniglow/screens/intro/rgb_picker.dart';

class DrumPartSetupPage extends StatelessWidget {
  final int partNumber;
  const DrumPartSetupPage({super.key, required this.partNumber});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Hi-Hat Open',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          RGBPicker(partNumber: partNumber),
        ],
      ),
    );
  }
}
