import 'package:flutter/material.dart';

class StaffLines extends StatelessWidget {
  const StaffLines({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StaffPainter(),
      child: Container(),
    );
  }
}

class StaffPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600] ?? Colors.grey
      ..strokeWidth = 2.0;

    // Draw 5 horizontal lines for landscape mode (drum lanes)
    for (int i = 0; i < 5; i++) {
      final y = (size.height / 5) * (i + 0.5); // Center each lane
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw hit zone at the right side for landscape
    final hitZonePaint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 6.0;

    final hitX = size.width - 100; // 100px from right edge
    canvas.drawLine(
      Offset(hitX, 0),
      Offset(hitX, size.height),
      hitZonePaint,
    );

    // Draw note spawn line at left side
    final spawnPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = 3.0;

    canvas.drawLine(
      Offset(50, 0), // 50px from left edge
      Offset(50, size.height),
      spawnPaint,
    );

    // Draw lane separators
    final separatorPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.0;

    for (int i = 1; i < 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        separatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
