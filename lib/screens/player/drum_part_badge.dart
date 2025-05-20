import 'package:flutter/material.dart';

class DrumOverlayView extends StatelessWidget {
  const DrumOverlayView({
    required this.selectedParts,
    this.highlightColor = Colors.red,
    super.key,
  });

  final List<String> selectedParts;
  final Color highlightColor;

  // Orijinal görsel 400x350 → buraya göre % oranlar
  static const Map<String, Offset> relativePositions = {
    'Crash Cymbal': Offset(0.05, 0.04), // soldaki eğik zil
    'Hi-Hat': Offset(0.73, 0.42), // sağdaki üst üste duran ziller
    'Ride Cymbal': Offset(0.90, 0.05), // sağ üstteki büyük zil
    'Snare Drum': Offset(0.24, 0.58), // sol alttaki küçük trampet
    'Kick Drum': Offset(0.47, 0.62), // ortadaki büyük davul
    'Tom 1': Offset(0.40, 0.26), // sol üst tom
    'Tom 2': Offset(0.55, 0.26), // sağ üst tom
    'Tom Floor': Offset(0.71, 0.58), // sağ alttaki tom
  };

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Etiketler üstte
          if (selectedParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: selectedParts
                    .map(
                      (part) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: highlightColor.withOpacity(0.2),
                          border: Border.all(color: highlightColor, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          part,
                          style: TextStyle(
                            color: highlightColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Görsel ve Highlight
          // Görsel ve Highlight
          AspectRatio(
            aspectRatio: 400 / 350, // Orijinal görsel oranı
            child: LayoutBuilder(
              builder: (context, constraints) {
                final imageWidth = constraints.maxWidth;
                final imageHeight = constraints.maxHeight;

                return Stack(
                  children: [
                    Image.asset(
                      'assets/images/drum-set.png',
                      fit: BoxFit.contain,
                      width: imageWidth,
                      height: imageHeight,
                    ),
                    ...selectedParts.map((part) {
                      final relOffset = relativePositions[part];
                      if (relOffset == null) return const SizedBox.shrink();

                      final dx = relOffset.dx * imageWidth;
                      final dy = relOffset.dy * imageHeight;

                      return Positioned(
                        left: dx,
                        top: dy,
                        child: _HighlightBox(
                          color: highlightColor,
                          size:
                              imageWidth * 0.08, // Responsive highlight boyutu
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      );
}

class _HighlightBox extends StatelessWidget {
  const _HighlightBox({this.color = Colors.red, this.size = 40});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      );
}
