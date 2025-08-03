import 'package:flutter/material.dart';
import '../../data/models/drum_note.dart';
import '../../core/enums/drum_type.dart';

class FallingNote extends StatelessWidget {
  final DrumNote note;
  final double screenHeight;

  const FallingNote({
    Key? key,
    required this.note,
    required this.screenHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: note.yPosition, // In landscape, notes move horizontally
      top: _getLaneYPosition(note.lane),
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            _getDrumImagePath(note.drumType),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image fails to load
              return Container(
                decoration: BoxDecoration(
                  color: _getDrumColor(note.drumType),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Icon(
                    _getDrumIcon(note.drumType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _getLaneYPosition(int lane) {
    // Calculate Y position for landscape mode (5 horizontal lanes)
    return (screenHeight / 5) * (lane + 0.5) -
        20; // Center in lane, offset by half note height
  }

  String _getDrumImagePath(DrumType drumType) {
    switch (drumType) {
      case DrumType.kick:
        return 'assets/images/classicDrum/c_kick.png';
      case DrumType.snare:
        return 'assets/images/classicDrum/c_snare.png';
      case DrumType.hihat:
        return 'assets/images/classicDrum/c_hihat.png';
      case DrumType.tom1:
        return 'assets/images/classicDrum/c_tom1.png';
      case DrumType.tom2:
        return 'assets/images/classicDrum/c_tom2.png';
    }
  }

  Color _getDrumColor(DrumType drumType) {
    switch (drumType) {
      case DrumType.kick:
        return Colors.red;
      case DrumType.snare:
        return Colors.blue;
      case DrumType.hihat:
        return Colors.yellow;
      case DrumType.tom1:
        return Colors.green;
      case DrumType.tom2:
        return Colors.orange;
    }
  }

  IconData _getDrumIcon(DrumType drumType) {
    switch (drumType) {
      case DrumType.kick:
        return Icons.circle;
      case DrumType.snare:
        return Icons.radio_button_checked;
      case DrumType.hihat:
        return Icons.close;
      case DrumType.tom1:
        return Icons.circle_outlined;
      case DrumType.tom2:
        return Icons.circle_outlined;
    }
  }
}
