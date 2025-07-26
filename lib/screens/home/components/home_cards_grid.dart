import 'package:drumly/screens/home/components/modern_card.dart';
import 'package:drumly/screens/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeCardsGrid extends StatelessWidget {
  const HomeCardsGrid({
    required this.fadeAnimation,
    required this.animationController,
    super.key,
  });
  final Animation<double> fadeAnimation;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) => Consumer<HomeViewModel>(
        builder: (context, viewModel, child) => SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final card = viewModel.cards[index];

              return AnimatedBuilder(
                animation: fadeAnimation,
                builder: (context, child) => Opacity(
                  opacity: fadeAnimation.value,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.3 + (index * 0.1)),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animationController,
                        curve: Interval(
                          index * 0.1,
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    ),
                    child: ModernCard(card: card),
                  ),
                ),
              );
            },
            childCount: viewModel.cards.length,
          ),
        ),
      );
}
