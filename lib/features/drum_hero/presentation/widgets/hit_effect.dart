import 'package:flutter/material.dart';

class HitEffect extends StatefulWidget {
  final double x;
  final double y;
  final bool isPerfect;

  const HitEffect({
    Key? key,
    required this.x,
    required this.y,
    this.isPerfect = false,
  }) : super(key: key);

  @override
  State<HitEffect> createState() => _HitEffectState();
}

class _HitEffectState extends State<HitEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward().then((_) {
      if (mounted) {
        // Remove this widget after animation completes
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.x - 40,
      top: widget.y - 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isPerfect
                      ? Colors.amber.withValues(alpha: 0.7)
                      : Colors.cyan.withValues(alpha: 0.7),
                  border: Border.all(
                    color: widget.isPerfect ? Colors.yellow : Colors.white,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.isPerfect ? 'PERFECT!' : 'GOOD!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
