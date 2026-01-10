import 'package:drumly/game/drum_hero_game.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

/// DrumHeroGame'i Flutter içinde gösteren ekran
class DrumHeroScreen extends StatelessWidget {
  const DrumHeroScreen({
    super.key,
    this.debugMode = false,
  });
  
  /// Debug modu: drum bölgelerini ve tap edilen lane'i gösterir
  /// Kalibrasyon için bu değeri true yap
  final bool debugMode;

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
        child: GameWidget(
          game: DrumHeroGame(
            onExit: () => Navigator.of(context).pop(),
            debugMode: debugMode,
          ),
          backgroundBuilder: (context) => Container(
            color: const Color(0xFF0A0A15),
          ),
        ),
      ),
    );
}
