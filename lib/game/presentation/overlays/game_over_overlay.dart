import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/game/core/constants/drumly_colors.dart';
import 'package:drumly/game/core/constants/drumly_text_styles.dart';
import 'package:drumly/game/presentation/components/neon_button.dart';

/// ============================================================================
/// GAME OVER OVERLAY - Modern glassmorphism game over screen
/// ============================================================================
///
/// Features:
/// - Glassmorphism card with blur effect
/// - Animated score count-up (0 to final)
/// - Displays: score, accuracy %, max combo
/// - Neon style buttons (Retry, Home)
/// ============================================================================

class GameOverOverlay extends StatefulWidget {

  const GameOverOverlay({
    required this.score, required this.accuracy, required this.maxCombo, required this.totalHits, required this.perfectHits, required this.goodHits, required this.missCount, required this.onRetry, required this.onHome, super.key,
  });
  /// Final score achieved.
  final int score;

  /// Accuracy percentage (0-100).
  final double accuracy;

  /// Maximum combo achieved.
  final int maxCombo;

  /// Total hits (for calculating hit count).
  final int totalHits;

  /// Perfect hits count.
  final int perfectHits;

  /// Good hits count.
  final int goodHits;

  /// Miss count.
  final int missCount;

  /// Callback for retry button.
  final VoidCallback onRetry;

  /// Callback for home button.
  final VoidCallback onHome;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Score count-up animation
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: widget.score.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Slide up animation
    _slideAnimation = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
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
  Widget build(BuildContext context) {
    final gameOverText = 'game.gameOver'.tr();
    final scoreLabel = 'game.score'.tr();
    final accuracyLabel = 'game.accuracy'.tr();
    final maxComboLabel = 'game.maxCombo'.tr();
    final perfectLabel = 'game.perfect'.tr();
    final goodLabel = 'game.good'.tr();
    final missLabel = 'game.miss'.tr();
    final retryLabel = 'game.playAgain'.tr();
    final homeLabel = 'game.mainMenu'.tr();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth * 0.9).clamp(280.0, 520.0);
            final cardHeight = constraints.maxHeight * 0.7;
            final scale =
              (cardHeight / 700).clamp(0.6, 1.0).toDouble();

          return Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: child,
                  ),
                ),
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildGlassCard(
                    gameOverText: gameOverText,
                    scoreLabel: scoreLabel,
                    accuracyLabel: accuracyLabel,
                    maxComboLabel: maxComboLabel,
                    perfectLabel: perfectLabel,
                    goodLabel: goodLabel,
                    missLabel: missLabel,
                    retryLabel: retryLabel,
                    homeLabel: homeLabel,
                    scale: scale,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({
    required String gameOverText,
    required String scoreLabel,
    required String accuracyLabel,
    required String maxComboLabel,
    required String perfectLabel,
    required String goodLabel,
    required String missLabel,
    required String retryLabel,
    required String homeLabel,
    required double scale,
  }) => DecoratedBox(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final spacing = (constraints.maxHeight * 0.03).clamp(8.0, 18.0);
              final headerGap = (constraints.maxHeight * 0.015).clamp(6.0, 12.0);
              final padding = (20.0 * scale).clamp(12.0, 20.0);

              final titleStyle = DrumlyTextStyles.displayMedium
                  .copyWith(fontSize: DrumlyTextStyles.displayMedium.fontSize! * scale);
              final scoreStyle = DrumlyTextStyles.scoreDisplay
                  .copyWith(fontSize: DrumlyTextStyles.scoreDisplay.fontSize! * scale);
              final captionStyle = DrumlyTextStyles.caption
                  .copyWith(fontSize: DrumlyTextStyles.caption.fontSize! * scale);

              return Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    // Title
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        gameOverText,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: titleStyle,
                      ),
                    ),
                    SizedBox(height: headerGap),

                    // Animated score
                    AnimatedBuilder(
                      animation: _scoreAnimation,
                      builder: (context, child) => Text(
                          _scoreAnimation.value.toInt().toString(),
                          style: scoreStyle,
                        ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scoreLabel,
                      style: captionStyle.copyWith(
                        color: DrumlyColors.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),

                    SizedBox(height: spacing),

                    _buildStatsGrid(
                      accuracyLabel: accuracyLabel,
                      maxComboLabel: maxComboLabel,
                      scale: scale,
                    ),
                    SizedBox(height: spacing),
                    _buildHitBreakdown(
                      perfectLabel: perfectLabel,
                      goodLabel: goodLabel,
                      missLabel: missLabel,
                      scale: scale,
                    ),

                    SizedBox(height: spacing),

                    _buildButtons(
                      retryLabel: retryLabel,
                      homeLabel: homeLabel,
                      scale: scale,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

  Widget _buildStatsGrid({
    required String accuracyLabel,
    required String maxComboLabel,
    required double scale,
  }) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          label: accuracyLabel,
          value: '${widget.accuracy.toStringAsFixed(1)}%',
          color: DrumlyColors.neonCyan,
          scale: scale,
        ),
        Container(
          width: 1,
          height: 50 * scale,
          color: DrumlyColors.divider,
        ),
        _buildStatItem(
          label: maxComboLabel,
          value: widget.maxCombo.toString(),
          color: DrumlyColors.neonGold,
          scale: scale,
        ),
      ],
    );

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required double scale,
  }) {
    final valueStyle = DrumlyTextStyles.headlineMedium.copyWith(
      color: color,
      fontSize: DrumlyTextStyles.headlineMedium.fontSize! * scale,
      shadows: [
        Shadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 16,
        ),
      ],
    );
    final labelStyle = DrumlyTextStyles.caption.copyWith(
      fontSize: DrumlyTextStyles.caption.fontSize! * scale,
      letterSpacing: 1.5,
    );

    return Column(
      children: [
        Text(
          value,
          style: valueStyle,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: labelStyle,
        ),
      ],
    );
  }

  Widget _buildHitBreakdown({
    required String perfectLabel,
    required String goodLabel,
    required String missLabel,
    required double scale,
  }) => Container(
      padding: EdgeInsets.all((18.0 * scale).clamp(12.0, 18.0)),
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
            'game.hitBreakdown'.tr(),
            style: DrumlyTextStyles.caption.copyWith(
              letterSpacing: 2,
              color: DrumlyColors.textSecondary,
              fontSize: DrumlyTextStyles.caption.fontSize! * scale,
            ),
          ),
          SizedBox(height: (12.0 * scale).clamp(8.0, 12.0)),
          _buildHitRow(
            label: perfectLabel,
            count: widget.perfectHits,
            color: DrumlyColors.perfectColor,
            scale: scale,
          ),
          SizedBox(height: (8.0 * scale).clamp(6.0, 8.0)),
          _buildHitRow(
            label: goodLabel,
            count: widget.goodHits,
            color: DrumlyColors.goodColor,
            scale: scale,
          ),
          SizedBox(height: (8.0 * scale).clamp(6.0, 8.0)),
          _buildHitRow(
            label: missLabel,
            count: widget.missCount,
            color: DrumlyColors.missColor,
            scale: scale,
          ),
        ],
      ),
    );

  Widget _buildHitRow({
    required String label,
    required int count,
    required Color color,
    required double scale,
  }) {
    final percentage = widget.totalHits > 0
        ? (count / widget.totalHits * 100).toStringAsFixed(1)
        : '0.0';
    final bodyStyle = DrumlyTextStyles.body.copyWith(
      fontSize: DrumlyTextStyles.body.fontSize! * scale,
    );
    final countStyle = DrumlyTextStyles.body.copyWith(
      fontSize: DrumlyTextStyles.body.fontSize! * scale,
      color: color,
      fontWeight: FontWeight.bold,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Text(
          '$count ($percentage%)',
          style: countStyle,
        ),
      ],
    );
  }

  Widget _buildButtons({
    required String retryLabel,
    required String homeLabel,
    required double scale,
  }) {
    final retrySize = scale < 0.82
        ? NeonButtonSize.medium
        : NeonButtonSize.large;
    final homeSize = scale < 0.82
        ? NeonButtonSize.small
        : NeonButtonSize.medium;

    return Column(
      children: [
        NeonButton.accent(
          label: retryLabel,
          onPressed: widget.onRetry,
          icon: Icons.replay,
          fullWidth: true,
          size: retrySize,
        ),
        SizedBox(height: (14.0 * scale).clamp(8.0, 14.0)),
        NeonButton.primary(
          label: homeLabel,
          onPressed: widget.onHome,
          icon: Icons.home,
          fullWidth: true,
          size: homeSize,
        ),
      ],
    );
  }
}
