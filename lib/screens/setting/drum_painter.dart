import 'package:flutter/material.dart';
import 'package:harmoniglow/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:harmoniglow/screens/setting/drum_model.dart';

class DrumPainter extends CustomPainter {
  DrumPainter({
    required this.bluetoothBloc,
    required this.onTapPart,
    required this.imageSize,
    required this.partColors,
    this.tapPosition,
  });

  final BluetoothBloc bluetoothBloc;
  final Offset? tapPosition;
  final void Function(BluetoothBloc, String) onTapPart;
  final Size imageSize;
  final List<DrumModel>? partColors;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();

    const Size referenceSize = Size(400, 400);
    final double scaleX = imageSize.width / referenceSize.width;
    final double scaleY = imageSize.height / referenceSize.height;

    final List<Map<String, dynamic>> drumParts = [
      {
        'name': 'Hi-Hat',
        'center': Offset(78 * scaleX, 480 * scaleY),
        'radius': 50.0 * scaleX,
      },
      {
        'name': 'Crash Cymbal',
        'center': Offset(175 * scaleX, 207 * scaleY),
        'radius': 55.0 * scaleX,
      },
      {
        'name': 'Ride Cymbal',
        'center': Offset(416 * scaleX, 250 * scaleY),
        'radius': 55.0 * scaleX,
      },
      {
        'name': 'Snare Drum',
        'center': Offset(197 * scaleX, 550 * scaleY),
        'radius': 37.0 * scaleX,
      },
      {
        'name': 'Tom 1',
        'center': Offset(235 * scaleX, 355 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Tom 2',
        'center': Offset(318 * scaleX, 355 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Tom 3',
        'center': Offset(396 * scaleX, 535 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Kick Drum',
        'center': Offset(270 * scaleX, 480 * scaleY),
        'radius': 30.0 * scaleX,
      },
    ];

    for (var part in drumParts) {
      final DrumModel drumModel = (partColors ?? []).firstWhere(
        (element) => element.name == part['name'],
        orElse: () => DrumModel(rgb: [255, 255, 255]),
      );

      final Color partColor = Color.fromARGB(
        150,
        drumModel.rgb?[0] ?? 255,
        drumModel.rgb?[1] ?? 255,
        drumModel.rgb?[2] ?? 255,
      );

      paint.color = partColor;
      canvas.drawCircle(part['center'], part['radius'], paint);
    }
  }

  bool detectTap(Offset position) {
    final double scaleX = imageSize.width / 400;
    final double scaleY = imageSize.height / 400;

    final List<Map<String, dynamic>> drumParts = [
      {
        'name': 'Hi-Hat',
        'center': Offset(78 * scaleX, 480 * scaleY),
        'radius': 50.0 * scaleX,
      },
      {
        'name': 'Crash Cymbal',
        'center': Offset(175 * scaleX, 207 * scaleY),
        'radius': 55.0 * scaleX,
      },
      {
        'name': 'Ride Cymbal',
        'center': Offset(416 * scaleX, 250 * scaleY),
        'radius': 55.0 * scaleX,
      },
      {
        'name': 'Snare Drum',
        'center': Offset(197 * scaleX, 550 * scaleY),
        'radius': 37.0 * scaleX,
      },
      {
        'name': 'Tom 1',
        'center': Offset(235 * scaleX, 355 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Tom 2',
        'center': Offset(318 * scaleX, 355 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Tom 3',
        'center': Offset(396 * scaleX, 535 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Kick Drum',
        'center': Offset(270 * scaleX, 480 * scaleY),
        'radius': 30.0 * scaleX,
      },
    ];

    for (var part in drumParts) {
      final Offset center = part['center'];
      final double radius = part['radius'];

      final double distance = (position - center).distance;
      if (distance <= radius) {
        onTapPart(bluetoothBloc, part['name']);
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
