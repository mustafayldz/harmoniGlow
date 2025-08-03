import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../bloc/game_bloc.dart';
import 'game_play_screen.dart';
import '../../core/constants/game_constants.dart';

class DrumHeroMainScreen extends StatefulWidget {
  const DrumHeroMainScreen({Key? key}) : super(key: key);

  @override
  State<DrumHeroMainScreen> createState() => _DrumHeroMainScreenState();
}

class _DrumHeroMainScreenState extends State<DrumHeroMainScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Force landscape orientation from the start
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Colors.purple[800]!.withOpacity(0.6),
              Colors.blue[900]!.withOpacity(0.4),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Modern Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.purple[300]!,
                              Colors.blue[300]!,
                              Colors.cyan[300]!,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'DRUM HERO',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose Your Challenge',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Modern Level Grid
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: GameConstants.levels.length,
                      itemBuilder: (context, index) {
                        final level = index;
                        final config = GameConstants.levels[level];
                        if (config == null) return const SizedBox.shrink();
                        return _buildModernLevelCard(context, level, config);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernLevelCard(
      BuildContext context, int level, LevelConfig config) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (level * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getLevelColor(level),
                  _getLevelColor(level).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getLevelColor(level).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _startGame(context, level),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${level + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getDifficultyText(level),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${config.bpm} BPM',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${config.noteCount} Notes',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.green[600]!;
      case 1:
        return Colors.blue[600]!;
      case 2:
        return Colors.orange[600]!;
      case 3:
        return Colors.red[600]!;
      case 4:
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getDifficultyText(int level) {
    switch (level) {
      case 0:
        return 'Beginner';
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  void _startGame(BuildContext context, int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => GameBloc(),
          child: GamePlayScreen(level: level),
        ),
      ),
    );
  }
}
