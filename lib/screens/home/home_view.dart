import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_state.dart';
import 'package:drumly/screens/home/components/home_cards_grid.dart';
import 'package:drumly/screens/home/components/modern_app_bar.dart';
import 'package:drumly/screens/home/components/promotion_card.dart';
import 'package:drumly/screens/home/home_viewmodel.dart';
import 'package:drumly/widgets/version_update_dialog.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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

    // Post frame callback ile initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel.initialize(context);
        _checkForUpdates();
      }
    });
  }

  /// 🔄 Version kontrolü - arka planda
  void _checkForUpdates() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.hasShownVersionCheckThisSession) return;

    // 1 saniye sonra kontrol et
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;
      
      final wasDialogShown = await VersionChecker.checkAndShowUpdateDialog(context);
      if (wasDialogShown) {
        userProvider.markVersionCheckAsShown();
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<BluetoothBloc, BluetoothStateC>(
      listener: (context, state) {
        // Bluetooth bağlantı durumu değiştiğinde kartları yeniden oluştur
        final isConnected = state.isConnected;
        _viewModel.updateCards(isConnected);
      },
      child: ChangeNotifierProvider<HomeViewModel>.value(
        value: _viewModel,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
              colors: isDarkMode
                  ? const [
                      Color(0xFF0F172A),
                      Color(0xFF1E293B),
                      Color(0xFF334155),
                    ]
                  : const [
                      Color(0xFFF8FAFC),
                      Color(0xFFE2E8F0),
                      Color(0xFFCBD5E1),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: _AnimatedAppBar(viewModel: _viewModel),
                ),
                // Promotion Card
                SliverToBoxAdapter(
                  child: _AnimatedPromotionCard(viewModel: _viewModel),
                ),
                // Cards Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: Selector<HomeViewModel, Animation<double>>(
                    selector: (_, vm) => vm.fadeAnimation,
                    builder: (context, fadeAnimation, _) => HomeCardsGrid(
                      fadeAnimation: fadeAnimation,
                      animationController: _viewModel.animationController,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Animated App Bar - ayrı widget
class _AnimatedAppBar extends StatelessWidget {
  const _AnimatedAppBar({required this.viewModel});
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: viewModel.fadeAnimation,
        builder: (context, child) => Opacity(
          opacity: viewModel.fadeAnimation.value,
          child: SlideTransition(
            position: viewModel.slideAnimation,
            child: const ModernAppBar(),
          ),
        ),
      );
}

/// Animated Promotion Card - ayrı widget
class _AnimatedPromotionCard extends StatelessWidget {
  const _AnimatedPromotionCard({required this.viewModel});
  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
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
                curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
              ),
            ),
            child: const StaticPromotionCard(),
          ),
        ),
      );
}
