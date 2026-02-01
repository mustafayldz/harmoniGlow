import 'dart:ui';
import 'package:flutter/material.dart';

class SongIntroOverlay extends StatefulWidget {

  const SongIntroOverlay({
    required this.title, required this.artist, required this.bpm, required this.timeSignature, required this.visible, super.key,
    this.onHide,
  });
  final String title;
  final String artist;
  final int bpm;
  final String timeSignature;
  final bool visible;
  final VoidCallback? onHide;

  @override
  State<SongIntroOverlay> createState() => _SongIntroOverlayState();
}

class _SongIntroOverlayState extends State<SongIntroOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  bool _hasShown = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      reverseDuration: const Duration(milliseconds: 700),
    );

    _slide = Tween<Offset>(
      begin: const Offset(-1.1, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        widget.onHide?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SongIntroOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible && !_hasShown) {
      _hasShown = true;
      _controller.forward();
      // Kart play tuşuna basılana kadar ekranda kalacak - otomatik kaybolma yok
    } else if (!widget.visible && (_controller.isAnimating || _controller.isCompleted)) {
      // Play tuşuna basıldığında 2 saniye sonra sola kayarak çık
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _controller.reverse();
        }
      });
    }
  }

  void hide() {
    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: _IntroCard(
            title: widget.title,
            artist: widget.artist,
            bpm: widget.bpm,
            timeSignature: widget.timeSignature,
          ),
        ),
      ),
    );
}

class _IntroCard extends StatelessWidget {

  const _IntroCard({
    required this.title,
    required this.artist,
    required this.bpm,
    required this.timeSignature,
  });
  final String title;
  final String artist;
  final int bpm;
  final String timeSignature;

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.65),
                Colors.black.withValues(alpha: 0.35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                artist,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$bpm BPM',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeSignature,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
}
