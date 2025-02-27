import 'dart:async';

import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    required this.color,
    required this.label,
    required this.onPress,
    super.key,
  });
  final Color color;
  final String label;
  final VoidCallback onPress;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double gradientProgress = 0.0;
  Timer? _pressTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pressTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() {
      gradientProgress = 1.0;
    });

    // Start a timer to determine if the user holds down long enough
    _pressTimer = Timer(const Duration(seconds: 1), () {
      // User has pressed until the end (for 1 second)
      widget.onPress(); // Call the provided callback function
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() {
      gradientProgress = 0.0;
    });

    // Cancel the timer since the user released early
    _pressTimer?.cancel();
  }

  void _handleTapCancel() {
    _controller.reverse();
    setState(() {
      gradientProgress = 0.0;
    });

    // Cancel the timer since the user cancelled the press
    _pressTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Center(
            child: CustomPaint(
              painter: AnimatedBorderPainter(
                animation: _controller,
                color: widget.color,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: gradientProgress),
                duration: const Duration(seconds: 1),
                builder: (_, progress, child) => GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  child: ProgressButton(
                    size: const Size(250, 40),
                    progress: progress,
                    color: widget.color,
                    label: widget.label,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class AnimatedBorderPainter extends CustomPainter {
  AnimatedBorderPainter({required this.animation, required this.color})
      : super(repaint: animation);
  final Color color;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    final path = Path()..addRRect(rRect);

    final pathMetrics = path.computeMetrics();
    final totalLength =
        pathMetrics.fold(0.0, (sum, metric) => sum + metric.length);

    final halfLength = totalLength / 2;

    final currentLength = totalLength * animation.value;
    final firstHalfLength =
        (currentLength > halfLength) ? halfLength : currentLength;
    final secondHalfLength = (currentLength < halfLength)
        ? currentLength - halfLength
        : currentLength;

    final firstPath = extractPath(path, firstHalfLength);
    final secondPath = extractPath(path, secondHalfLength, offset: halfLength);

    canvas.drawPath(firstPath, paint);
    canvas.drawPath(secondPath, paint);
  }

  Path extractPath(Path originalPath, double length, {double offset = 0}) {
    final path = Path();
    double currentLength = 0.0;

    for (final metric in originalPath.computeMetrics()) {
      if (currentLength + metric.length > offset) {
        final start = offset > currentLength ? offset - currentLength : 0.0;
        final remainingLength = length - (currentLength - offset);
        final extractLength = remainingLength.clamp(0, metric.length - start);
        path.addPath(
          metric.extractPath(start, start + extractLength),
          Offset.zero,
        );
        break;
      }
      currentLength += metric.length;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProgressButton extends StatelessWidget {
  const ProgressButton({
    required this.size,
    required this.progress,
    required this.color,
    required this.label,
    super.key,
  });
  final Size size;
  final double progress;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: size.height,
        width: size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: (0.3)),
        ),
        child: Stack(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: color,
                width: size.width * progress,
              ),
            ),
            Center(
              child: Text(
                label,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
          ],
        ),
      );
}
