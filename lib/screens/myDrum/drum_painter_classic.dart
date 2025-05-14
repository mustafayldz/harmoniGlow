import 'package:flutter/material.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/myDrum/drum_model.dart';

class DrumPainterClassic extends CustomPainter {
  DrumPainterClassic({
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
        'center': Offset(84 * scaleX, 410 * scaleY),
        'radius': 44.0 * scaleX,
      },
      {
        'name': 'Crash Cymbal',
        'center': Offset(147 * scaleX, 200 * scaleY),
        'radius': 56.0 * scaleX,
      },
      {
        'name': 'Ride Cymbal',
        'center': Offset(388 * scaleX, 246 * scaleY),
        'radius': 52.0 * scaleX,
      },
      {
        'name': 'Snare Drum',
        'center': Offset(160 * scaleX, 510 * scaleY),
        'radius': 37.0 * scaleX,
      },
      {
        'name': 'Tom 1',
        'center': Offset(185 * scaleX, 350 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Tom 2',
        'center': Offset(285 * scaleX, 330 * scaleY),
        'radius': 40.0 * scaleX,
      },
      {
        'name': 'Tom Floor',
        'center': Offset(353 * scaleX, 490 * scaleY),
        'radius': 45.0 * scaleX,
      },
      {
        'name': 'Kick Drum',
        'center': Offset(245 * scaleX, 480 * scaleY),
        'radius': 50.0 * scaleX,
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
        'center': Offset(84 * scaleX, 410 * scaleY),
        'radius': 44.0 * scaleX,
      },
      {
        'name': 'Crash Cymbal',
        'center': Offset(147 * scaleX, 200 * scaleY),
        'radius': 56.0 * scaleX,
      },
      {
        'name': 'Ride Cymbal',
        'center': Offset(388 * scaleX, 246 * scaleY),
        'radius': 52.0 * scaleX,
      },
      {
        'name': 'Snare Drum',
        'center': Offset(160 * scaleX, 510 * scaleY),
        'radius': 37.0 * scaleX,
      },
      {
        'name': 'Tom 1',
        'center': Offset(185 * scaleX, 350 * scaleY),
        'radius': 36.0 * scaleX,
      },
      {
        'name': 'Tom 2',
        'center': Offset(285 * scaleX, 330 * scaleY),
        'radius': 40.0 * scaleX,
      },
      {
        'name': 'Tom Floor',
        'center': Offset(353 * scaleX, 490 * scaleY),
        'radius': 45.0 * scaleX,
      },
      {
        'name': 'Kick Drum',
        'center': Offset(245 * scaleX, 480 * scaleY),
        'radius': 50.0 * scaleX,
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
