import 'package:drumly/game/drum_hero_game.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
/// DrumHeroGame'i Flutter içinde gösteren ekran
class DrumHeroScreen extends StatelessWidget {
  const DrumHeroScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
        child: GameWidget(
          game: DrumHeroGame(
            onExit: () => Navigator.of(context).pop(),
          ),
          backgroundBuilder: (context) => Container(
            color: const Color(0xFF0A0A15),
          ),
        ),
      ),
    );
}
