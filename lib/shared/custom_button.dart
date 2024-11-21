import 'package:flutter/material.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({super.key});

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double gradientProgress = 0.0;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: CustomPaint(
              painter: AnimatedBorderPainter(animation: _controller),
              child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: gradientProgress),
                  duration: const Duration(seconds: 1),
                  builder: (_, progress, child) {
                    return GestureDetector(
                      onTapDown: (_) {
                        _controller.forward();

                        setState(() {
                          gradientProgress = 1.0;
                        });
                      },
                      onTapUp: (_) {
                        _controller.reverse();

                        setState(() {
                          gradientProgress = 0.0;
                        });
                      },
                      onTapCancel: () {
                        _controller.reverse();

                        setState(() {
                          gradientProgress = 0.0;
                        });
                      },
                      child: ProgressButton(
                        size: const Size(250, kButtonHeight),
                        progress: progress,
                      ),
                    );
                  })),
        ),
      ],
    );
  }
}

class AnimatedBorderPainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedBorderPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPrimaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect =
        RRect.fromRectAndRadius(rect, const Radius.circular(kBorderRadius));

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
            metric.extractPath(start, start + extractLength), Offset.zero);
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
  final Size size;
  final double progress;
  const ProgressButton({super.key, required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.height,
      width: size.width,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: kPrimaryColor.withOpacity(0.3)),
      child: Stack(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: kPrimaryColor,
              width: size.width * progress,
            ),
          ),
          const Center(
              child: Text(
            "PRESS AND HOLD TO SAVE",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ))
        ],
      ),
    );
  }
}

const kBorderRadius = 10.0;
const kButtonHeight = 40.0;
final kPrimaryColor = Colors.red[800]!;
