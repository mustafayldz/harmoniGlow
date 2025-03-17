import 'package:flutter/material.dart';

class DrumPainter extends CustomPainter {
  DrumPainter({
    required this.onTapPart,
    required this.imageSize,
    this.tapPosition,
  });

  final Offset? tapPosition;
  final Function(String) onTapPart;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.transparent;

    // Define base positions relative to a reference image size
    const Size referenceSize = Size(400, 400); // Reference image size
    final double scaleX = imageSize.width / referenceSize.width;
    final double scaleY = imageSize.height / referenceSize.height;

    // Dynamic drum part positions with colors
    final List<Map<String, dynamic>> drumParts = [
      {
        'name': 'Hi-Hat',
        'center': Offset(68 * scaleX, 300 * scaleY),
        'radius': 43.0 * scaleX,
        'color': Colors.blue.withValues(alpha: 0.3),
      },
      {
        'name': 'Crash Cymbal',
        'center': Offset(156 * scaleX, 128 * scaleY),
        'radius': 50.0 * scaleX,
        'color': Colors.amber.withValues(alpha: 0.3),
      },
      {
        'name': 'Ride Cymbal',
        'center': Offset(365 * scaleX, 155 * scaleY),
        'radius': 48.0 * scaleX,
        'color': Colors.orange.withValues(alpha: 0.3),
      },
      {
        'name': 'Snare Drum',
        'center': Offset(174 * scaleX, 345 * scaleY),
        'radius': 35.0 * scaleX,
        'color': Colors.teal.withValues(alpha: 0.3),
      },
      {
        'name': 'Tom 1',
        'center': Offset(206 * scaleX, 221 * scaleY),
        'radius': 33.0 * scaleX,
        'color': Colors.red.withValues(alpha: 0.3),
      },
      {
        'name': 'Tom 2',
        'center': Offset(279 * scaleX, 221 * scaleY),
        'radius': 33.0 * scaleX,
        'color': Colors.green.withValues(alpha: 0.3),
      },
      {
        'name': 'Tom 3',
        'center': Offset(348 * scaleX, 333 * scaleY),
        'radius': 32.0 * scaleX,
        'color': Colors.purple.withValues(alpha: 0.3),
      },
      {
        'name': 'Kick Drum',
        'center': Offset(240 * scaleX, 295 * scaleY),
        'radius': 25.0 * scaleX,
        'color': Colors.yellow.withValues(alpha: 0.3),
      },
    ];

    // Draw each drum part with its specific color
    for (var part in drumParts) {
      paint.color = part['color'];
      canvas.drawCircle(part['center'], part['radius'], paint);
    }
  }

  bool detectTap(Offset position) {
    final double scaleX = imageSize.width / 350;
    final double scaleY = imageSize.height / 250;

    final List<Map<String, dynamic>> drumParts = [
      {
        'name': 'Hi-Hat',
        'center': Offset(68 * scaleX, 300 * scaleY),
        'radius': 43.0 * scaleX,
      },
      {
        'name': 'Crash Cymbal',
        'center': Offset(156 * scaleX, 128 * scaleY),
        'radius': 50.0 * scaleX,
      },
      {
        'name': 'Ride Cymbal',
        'center': Offset(365 * scaleX, 155 * scaleY),
        'radius': 48.0 * scaleX,
      },
      {
        'name': 'Snare Drum',
        'center': Offset(174 * scaleX, 345 * scaleY),
        'radius': 35.0 * scaleX,
      },
      {
        'name': 'Tom 1',
        'center': Offset(206 * scaleX, 221 * scaleY),
        'radius': 33.0 * scaleX,
      },
      {
        'name': 'Tom 2',
        'center': Offset(279 * scaleX, 221 * scaleY),
        'radius': 33.0 * scaleX,
      },
      {
        'name': 'Tom 3',
        'center': Offset(348 * scaleX, 333 * scaleY),
        'radius': 32.0 * scaleX,
      },
      {
        'name': 'Kick Drum',
        'center': Offset(240 * scaleX, 295 * scaleY),
        'radius': 25.0 * scaleX,
      },
    ];

    for (var part in drumParts) {
      final Offset center = part['center'];
      final double radius = part['radius'];

      final double distance = (position - center).distance;
      if (distance <= radius) {
        onTapPart(part['name']);
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
