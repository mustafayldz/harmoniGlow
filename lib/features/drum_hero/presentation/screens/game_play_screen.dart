import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../bloc/game_bloc.dart';
import '../widgets/staff_lines.dart';
import '../widgets/falling_note.dart';
import '../../core/enums/game_state.dart';

class GamePlayScreen extends StatefulWidget {
  final int level;

  const GamePlayScreen({Key? key, required this.level}) : super(key: key);

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen>
    with TickerProviderStateMixin {
  late AnimationController _gameLoopController;

  @override
  void initState() {
    super.initState();

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _gameLoopController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addListener(_gameLoop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start game with screen dimensions after the widget is built
    final size = MediaQuery.of(context).size;
    context.read<GameBloc>().add(StartGame(
          level: widget.level,
          screenWidth: size.width,
          screenHeight: size.height,
        ));
    _gameLoopController.repeat();
  }

  void _gameLoop() {
    if (mounted) {
      final bloc = context.read<GameBloc>();
      // Only update if game is playing
      if (bloc.state.gameState == GameState.playing) {
        bloc.add(UpdateNotePositions(1 / 60)); // 60 FPS
      }
    }
  }

  @override
  void dispose() {
    // Stop all sounds before leaving
    final gameBloc = context.read<GameBloc>();
    gameBloc.add(ExitGame());

    // Reset orientation when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _gameLoopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<GameBloc, GameBlocState>(
        listener: (context, state) {
          // Handle level completion
          if (state.levelCompleted) {
            _showLevelCompleteDialog(context);
          }
          // Handle pause state
          if (state.gameState == GameState.paused) {
            _showPauseDialog(context);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple[900]!, Colors.black],
                  ),
                ),
              ),

              // Staff Lines (Horizontal in landscape)
              const StaffLines(),

              // Falling Notes
              ...state.activeNotes.map((note) => FallingNote(
                    note: note,
                    screenHeight: MediaQuery.of(context).size.height,
                  )),

              // Drum Hit Areas (5 lanes for landscape)
              _buildDrumAreas(),

              // UI Overlay (Score, Combo, Level info)
              _buildGameUI(state),

              // Pause/Resume Button
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (state.gameState == GameState.playing) {
                        context.read<GameBloc>().add(PauseGame());
                      } else if (state.gameState == GameState.paused) {
                        context.read<GameBloc>().add(ResumeGame());
                      }
                    },
                    icon: Icon(
                      state.gameState == GameState.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

              // Exit Button
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 30),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrumAreas() {
    return Column(
      children: List.generate(5, (index) {
        return Expanded(
          child: GestureDetector(
            onTapDown: (details) => _handleDrumHit(index),
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      _getDrumName(index),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGameUI(GameBlocState state) {
    return Positioned(
      top: 80,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level: ${state.currentLevel}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${state.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Combo: ${state.combo}x',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Accuracy: ${state.accuracy.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDrumHit(int lane) {
    context.read<GameBloc>().add(HitNote(lane));
  }

  String _getDrumName(int lane) {
    switch (lane) {
      case 0:
        return 'HiHat';
      case 1:
        return 'Tom1';
      case 2:
        return 'Snare';
      case 3:
        return 'Tom2';
      case 4:
        return 'Kick';
      default:
        return '';
    }
  }

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: const Text(
            'Game Paused',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          content: const Text(
            'Tap Resume to continue playing',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.read<GameBloc>().add(ResumeGame());
              },
              child: const Text(
                'Resume',
                style: TextStyle(color: Colors.green, fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to menu
              },
              child: const Text(
                'Exit',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLevelCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: const Text(
            'Level Complete!',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
          content: BlocBuilder<GameBloc, GameBlocState>(
            builder: (context, state) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Final Score: ${state.score}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accuracy: ${state.accuracy.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max Combo: ${state.combo}',
                    style: const TextStyle(color: Colors.yellow, fontSize: 16),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to menu
              },
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        );
      },
    );
  }
}
