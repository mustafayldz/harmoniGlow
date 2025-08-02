import 'package:drumly/adMob/ad_service.dart';
import 'package:flutter/material.dart';

class AdView extends StatefulWidget {
  const AdView({required this.onAdFinished, super.key});
  final VoidCallback onAdFinished;

  @override
  State<AdView> createState() => _AdViewState();
}

class _AdViewState extends State<AdView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
    _showAd();
  }

  Future<void> _showAd() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Kısa loading
    if (mounted) {
      setState(() => _adLoaded = true);

      AdService.instance.showInterstitialAd().whenComplete(() {
        if (mounted) {
          widget.onAdFinished();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo veya ikon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.play_circle_outline,
                size: 50,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 24),

            // Animasyonlu loading indicator
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) => Opacity(
                opacity: _animation.value,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Loading text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _adLoaded ? 'Preparing...' : 'Loading...',
                key: ValueKey(_adLoaded),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
