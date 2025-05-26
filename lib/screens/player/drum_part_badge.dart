import 'package:flutter/material.dart';

class DrumOverlayView extends StatelessWidget {
  const DrumOverlayView({
    required this.selectedParts,
    this.highlightColor = Colors.red,
    super.key,
  });

  final List<String> selectedParts;
  final Color highlightColor;

  static const Map<String, _PartPosition> _partData = {
    'Crash Cymbal': _PartPosition(
      assetPath: 'assets/images/draw/crash.png',
      offset: Offset(-0.1, 0.4),
      sizeRatio: Size(0.5, 0.5),
    ),
    'Hi-Hat': _PartPosition(
      assetPath: 'assets/images/draw/hihat.png',
      offset: Offset(-0.05, 0.55),
      sizeRatio: Size(0.5, 0.35),
    ),
    'Snare Drum': _PartPosition(
      assetPath: 'assets/images/draw/snare.png',
      offset: Offset(0.22, 0.7),
      sizeRatio: Size(0.2, 0.2),
    ),
    'Tom 1': _PartPosition(
      assetPath: 'assets/images/draw/tom1.png',
      offset: Offset(0.3, 0.38),
      sizeRatio: Size(0.2, 0.4),
    ),
    'Tom 2': _PartPosition(
      assetPath: 'assets/images/draw/tom2.png',
      offset: Offset(0.56, 0.38),
      sizeRatio: Size(0.2, 0.4),
    ),
    'Tom Floor': _PartPosition(
      assetPath: 'assets/images/draw/tomFloor.png',
      offset: Offset(0.64, 0.7),
      sizeRatio: Size(0.2, 0.2),
    ),
    'Ride Cymbal': _PartPosition(
      assetPath: 'assets/images/draw/ride.png',
      offset: Offset(0.63, 0.4),
      sizeRatio: Size(0.5, 0.5),
    ),
    'Kick Drum': _PartPosition(
      assetPath: 'assets/images/draw/kick.png',
      offset: Offset(0.33, 0.48),
      sizeRatio: Size(0.4, 0.5),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        children: [
          if (selectedParts.isNotEmpty)
            Wrap(
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
                        color: highlightColor.withAlpha(51),
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
          SizedBox(
            height: screenHeight *
                0.5, // iPhone 13 Pro için yaklaşık 1519px × 830px
            child: AspectRatio(
              aspectRatio: 1024 / 559,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return Stack(
                    children: _partData.entries.map((entry) {
                      final isSelected = selectedParts.contains(entry.key);
                      final data = entry.value;

                      final left = data.offset.dx * width;
                      final top = data.offset.dy * height;
                      final w = data.sizeRatio.width * width;
                      final h = data.sizeRatio.height * height;

                      return Positioned(
                        left: left,
                        top: top,
                        width: w,
                        height: h,
                        child: Image.asset(
                          data.assetPath,
                          fit: BoxFit.contain,
                          color:
                              isSelected ? highlightColor.withAlpha(140) : null,
                          colorBlendMode: isSelected ? BlendMode.srcATop : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartPosition {
  const _PartPosition({
    required this.assetPath,
    required this.offset,
    required this.sizeRatio,
  });
  final String assetPath;
  final Offset offset;
  final Size sizeRatio;
}
