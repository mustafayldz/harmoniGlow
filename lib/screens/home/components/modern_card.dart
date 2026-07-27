import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/screens/home/components/card_data.dart';
import 'package:drumly/screens/my_drum/drum_adjustment.dart';
import 'package:drumly/screens/settings/setting_view.dart';
import 'package:drumly/screens/songs/songv2_view.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drumly/game/drum_hero_screen.dart';

class ModernCard extends StatelessWidget {
  const ModernCard({required this.card, super.key});
  final CardData card;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final destination = _getDestination(card.key, isConnected);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () =>
            _handleModernTap(context, card.key, isConnected, destination),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDarkMode ? 0.14 : 0.045,
                ),
                blurRadius: 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: card.color.withValues(
                        alpha: isDarkMode ? 0.18 : 0.11,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      card.icon,
                      size: 21,
                      color: isDarkMode
                          ? Color.lerp(card.color, Colors.white, 0.18)
                          : card.color,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 17,
                    color: onSurface.withValues(alpha: 0.28),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                card.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: onSurface,
                  height: 1.05,
                  letterSpacing: -0.35,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Text(
                card.subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: 0.46),
                  height: 1.28,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
      case 'songs':
        return const SongV2View();
      case 'mydrum':
        return const DrumAdjustment();
      case 'settings':
        return const SettingView();
      case 'retim':
        return const DrumHeroScreen();
      default:
        return const SizedBox.shrink();
    }
  }
}
