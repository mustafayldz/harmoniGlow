import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:drumly/game/core/constants/drumly_colors.dart';
import 'package:drumly/game/core/constants/drumly_text_styles.dart';
import 'package:drumly/game/presentation/components/neon_button.dart';

/// ============================================================================
/// PAUSE OVERLAY - Modern glassmorphism pause menu
/// ============================================================================
///
/// Features:
/// - Glassmorphism card with blur effect
/// - Neon style buttons
/// - Smooth animations
/// - Current game stats display
/// ============================================================================

class PauseOverlay extends StatefulWidget {

  const PauseOverlay({
    required this.currentScore, required this.currentCombo, required this.currentAccuracy, required this.onResume, required this.onRestart, required this.onHome, super.key,
  });
  /// Current score.
  final int currentScore;

  /// Current combo.
  final int currentCombo;

  /// Current accuracy.
  final double currentAccuracy;

  /// Callback for resume button.
  final VoidCallback onResume;

  /// Callback for restart button.
  final VoidCallback onRestart;

  /// Callback for home button.
  final VoidCallback onHome;

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
          opacity: _fadeAnimation.value,
          child: Scaffold(
            backgroundColor: DrumlyColors.darkBg.withValues(alpha: 0.9),
            body: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          ),
        ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildGlassCard(),
        ),
      ),
    );

  Widget _buildGlassCard() => Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: DrumlyColors.darkCard.withValues(alpha: DrumlyColors.glassOpacity),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DrumlyColors.neonCyan.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: DrumlyColors.neonCyan.withValues(alpha: 0.2),
            blurRadius: 30,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pause icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DrumlyColors.neonCyan.withValues(alpha: 0.2),
                    border: Border.all(
                      color: DrumlyColors.neonCyan,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DrumlyColors.neonCyan.withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pause,
                    size: 40,
                    color: DrumlyColors.neonCyan,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'PAUSED',
                  style: DrumlyTextStyles.displayMedium.copyWith(
                    fontSize: 36,
                  ),
                ),

                const SizedBox(height: 32),

                // Current stats
                _buildStatsSection(),

                const SizedBox(height: 32),

                // Divider
                Container(
                  height: 1,
                  color: DrumlyColors.divider,
                ),

                const SizedBox(height: 32),

                // Buttons
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );

  Widget _buildStatsSection() => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DrumlyColors.darkBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DrumlyColors.divider,
        ),
      ),
      child: Column(
        children: [
          Text(
            'CURRENT STATS',
            style: DrumlyTextStyles.caption.copyWith(
              letterSpacing: 2,
              color: DrumlyColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            label: 'Score',
            value: widget.currentScore.toString(),
            color: DrumlyColors.neonGold,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            label: 'Combo',
            value: widget.currentCombo.toString(),
            color: DrumlyColors.neonCyan,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            label: 'Accuracy',
            value: '${widget.currentAccuracy.toStringAsFixed(1)}%',
            color: DrumlyColors.successColor,
          ),
        ],
      ),
    );

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color color,
  }) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DrumlyTextStyles.body,
        ),
        Text(
          value,
          style: DrumlyTextStyles.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildButtons() => Column(
      children: [
        NeonButton.accent(
          label: 'RESUME',
          onPressed: widget.onResume,
          icon: Icons.play_arrow,
          fullWidth: true,
          size: NeonButtonSize.large,
        ),
        const SizedBox(height: 16),
        NeonButton.primary(
          label: 'RESTART',
          onPressed: widget.onRestart,
          icon: Icons.replay,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        NeonButton(
          label: 'HOME',
          onPressed: widget.onHome,
          icon: Icons.home,
          fullWidth: true,
          color: DrumlyColors.textSecondary,
        ),
      ],
    );
}
