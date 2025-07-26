import 'package:drumly/screens/home/components/home_cards_grid.dart';
import 'package:drumly/screens/home/components/modern_app_bar.dart';
import 'package:drumly/screens/home/components/promotion_card.dart';
import 'package:drumly/screens/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(vsync: this);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<HomeViewModel>.value(
        value: _viewModel,
        child: Consumer<HomeViewModel>(
          builder: (context, viewModel, child) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return Scaffold(
              body: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            const Color(0xFF0F172A),
                            const Color(0xFF1E293B),
                            const Color(0xFF334155),
                          ]
                        : [
                            const Color(0xFFF8FAFC),
                            const Color(0xFFE2E8F0),
                            const Color(0xFFCBD5E1),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // App Bar
                      SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: viewModel.fadeAnimation,
                          builder: (context, child) => Opacity(
                            opacity: viewModel.fadeAnimation.value,
                            child: SlideTransition(
                              position: viewModel.slideAnimation,
                              child: const ModernAppBar(),
                            ),
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: viewModel.fadeAnimation,
                          builder: (context, child) => Opacity(
                            opacity: viewModel.fadeAnimation.value,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: viewModel.animationController,
                                  curve: const Interval(0.3, 1.0,
                                      curve: Curves.easeOutCubic),
                                ),
                              ),
                              child: const StaticPromotionCard(),
                            ),
                          ),
                        ),
                      ),

                      // Cards Grid
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: HomeCardsGrid(
                          fadeAnimation: viewModel.fadeAnimation,
                          animationController: viewModel.animationController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
}
