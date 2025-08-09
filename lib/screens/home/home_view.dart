import 'package:drumly/screens/home/components/home_cards_grid.dart';
import 'package:drumly/screens/home/components/modern_app_bar.dart';
import 'package:drumly/screens/home/components/promotion_card.dart';
import 'package:drumly/screens/home/home_viewmodel.dart';
import 'package:drumly/widgets/version_update_dialog.dart';
import 'package:drumly/provider/user_provider.dart';
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
    
    // initState'de context henüz ready olmayabilir, post frame callback kullan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize(context);
      _checkForUpdates();
    });
  }
  
  /// 🔄 Version kontrolü ve popup gösterimi
  void _checkForUpdates() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Eğer bu session'da zaten gösterildiyse tekrar gösterme
    if (userProvider.hasShownVersionCheckThisSession) {
      return;
    }
    
    // Uygulama tam yüklendikten sonra kontrol et
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      final wasDialogShown = await VersionChecker.checkAndShowUpdateDialog(context);
      
      // Sadece dialog gösterildiyse flag'i işaretle
      if (wasDialogShown) {
        userProvider.markVersionCheckAsShown();
      }
    }
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
                  bottom: false,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
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
                                  curve: const Interval(
                                    0.3,
                                    1.0,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              ),
                              child: const StaticPromotionCard(),
                            ),
                          ),
                        ),
                      ),

                      // Cards Grid
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
