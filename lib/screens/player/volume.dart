import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class ModernVolumeButtons extends StatefulWidget {
  const ModernVolumeButtons({
    required this.player,
    super.key,
    this.step = 0.1,
  });
  final AudioPlayer player;
  final double step;

  @override
  ModernVolumeButtonsState createState() => ModernVolumeButtonsState();
}

class ModernVolumeButtonsState extends State<ModernVolumeButtons> {
  double _volume = 0.2;

  @override
  void initState() {
    super.initState();
    widget.player.setVolume(_volume);
  }

  Future<void> _changeVolume(double delta) async {
    setState(() {
      _volume = (_volume + delta).clamp(0.0, 1.0);
    });
    await widget.player.setVolume(_volume);
  }

  Widget _buildButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 32, color: Colors.black),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton(Icons.volume_down, () => _changeVolume(-widget.step)),
          Text(
            '${(_volume * 100).round()}%',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          _buildButton(Icons.volume_up, () => _changeVolume(widget.step)),
        ],
      );
}
