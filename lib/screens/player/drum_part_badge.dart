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
      offset: Offset(-0.1, 0.0),
      sizeRatio: Size(0.5, 0.6),
    ),
    'Hi-Hat': _PartPosition(
      assetPath: 'assets/images/draw/hihat.png',
      offset: Offset(-0.05, 0.2),
      sizeRatio: Size(0.5, 0.4),
    ),
    'Tom 1': _PartPosition(
      assetPath: 'assets/images/draw/tom1.png',
      offset: Offset(0.3, 0.0),
      sizeRatio: Size(0.2, 0.4),
    ),
    'Tom 2': _PartPosition(
      assetPath: 'assets/images/draw/tom2.png',
      offset: Offset(0.56, 0.0),
      sizeRatio: Size(0.2, 0.4),
    ),
    'Ride Cymbal': _PartPosition(
      assetPath: 'assets/images/draw/ride.png',
      offset: Offset(0.63, 0.0),
      sizeRatio: Size(0.5, 0.6),
    ),
    'Kick Drum': _PartPosition(
      assetPath: 'assets/images/draw/kick.png',
      offset: Offset(0.33, 0.13),
      sizeRatio: Size(0.4, 0.5),
    ),
    'Tom Floor': _PartPosition(
      assetPath: 'assets/images/draw/tomFloor.png',
      offset: Offset(0.64, 0.3),
      sizeRatio: Size(0.2, 0.3),
    ),
    'Snare Drum': _PartPosition(
      assetPath: 'assets/images/draw/snare.png',
      offset: Offset(0.22, 0.3),
      sizeRatio: Size(0.2, 0.3),
    ),
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final minDimension = availableWidth < availableHeight 
            ? availableWidth 
            : availableHeight;
        
        // Responsive badge sizing
        final badgePadding = (minDimension * 0.02).clamp(4.0, 12.0);
        final badgeFontSize = (minDimension * 0.035).clamp(10.0, 16.0);
        final badgeBorderRadius = (minDimension * 0.03).clamp(8.0, 16.0);
        final badgeSpacing = (minDimension * 0.02).clamp(4.0, 12.0);
        
        // Calculate drum kit section height ratio
        final badgeSectionRatio = selectedParts.isNotEmpty ? 0.18 : 0.15;
        
        return Column(
          children: [
            // Badges section - responsive
            SizedBox(
              height: availableHeight * badgeSectionRatio,
              child: selectedParts.isNotEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: badgeSpacing),
                          child: Wrap(
                            spacing: badgeSpacing,
                            runSpacing: badgeSpacing * 0.5,
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            children: selectedParts
                                .map(
                                  (part) => Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: badgePadding,
                                      vertical: badgePadding * 0.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: highlightColor.withAlpha(51),
                                      border: Border.all(
                                        color: highlightColor,
                                        width: (minDimension * 0.005).clamp(1.0, 3.0),
                                      ),
                                      borderRadius: BorderRadius.circular(badgeBorderRadius),
                                    ),
                                    child: Text(
                                      part,
                                      style: TextStyle(
                                        color: highlightColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: badgeFontSize,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            
            // Drum kit visualization - responsive
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1024 / 559,
                  child: LayoutBuilder(
                    builder: (context, drumConstraints) {
                      final drumWidth = drumConstraints.maxWidth;
                      final drumHeight = drumConstraints.maxHeight;

                      return Stack(
                        children: _partData.entries.map((entry) {
                          final isSelected = selectedParts.contains(entry.key);
                          final data = entry.value;

                          final left = data.offset.dx * drumWidth;
                          final top = data.offset.dy * drumHeight;
                          final w = data.sizeRatio.width * drumWidth;
                          final h = data.sizeRatio.height * drumHeight;

                          return Positioned(
                            left: left,
                            top: top,
                            width: w,
                            height: h,
                            child: Image.asset(
                              data.assetPath,
                              fit: BoxFit.contain,
                              color: isSelected
                                  ? highlightColor.withAlpha(175)
                                  : null,
                              colorBlendMode:
                                  isSelected ? BlendMode.srcATop : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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
