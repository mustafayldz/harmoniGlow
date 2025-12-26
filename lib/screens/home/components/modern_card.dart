import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/home/components/card_data.dart';
import 'package:drumly/screens/my_drum/drum_adjustment.dart';
import 'package:drumly/screens/settings/setting_view.dart';
import 'package:drumly/screens/songs/song_view.dart';
import 'package:drumly/screens/songs/songv2_view.dart';
import 'package:drumly/screens/training/traning_view.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ModernCard extends StatelessWidget {
  const ModernCard({required this.card, super.key});
  final CardData card;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final destination = _getDestination(card.key, isConnected);

    return GestureDetector(
      onTap: () =>
          _handleModernTap(context, card.key, isConnected, destination),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: card.gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: card.color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    card.icon,
                    size: constraints.maxWidth * 0.2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.08),
                Flexible(
                  child: Text(
                    card.title,
                    style: TextStyle(
                      fontSize: constraints.maxWidth * 0.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: constraints.maxHeight * 0.04),
                Flexible(
                  child: Text(
                    card.subtitle,
                    style: TextStyle(
                      fontSize: constraints.maxWidth * 0.08,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleModernTap(
    BuildContext context,
    String key,
    bool isConnected,
    Widget destination,
  ) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: key.replaceAll(' ', '_'));
      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } catch (e, st) {
      debugPrint('Navigation error: $e\n$st');
    }
  }

  Widget _getDestination(String key, bool isConnected) {
    switch (key) {
      case 'training':
        return const TrainingView();
      case 'songs':
        return const SongView();
      case 'songsv2':
        return const SongV2View();
      case 'mydrum':
        return const DrumAdjustment();
      case 'settings':
        return const SettingView();
      default:
        return const SizedBox.shrink();
    }
  }
}
