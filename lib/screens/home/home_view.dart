import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_state.dart';
import 'package:drumly/screens/home/components/home_cards_grid.dart';
import 'package:drumly/screens/home/components/announcement_carousel.dart';
import 'package:drumly/screens/home/components/modern_app_bar.dart';
import 'package:drumly/screens/home/components/request_song_card.dart';
import 'package:drumly/screens/home/home_viewmodel.dart';
import 'package:drumly/widgets/version_update_dialog.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:drumly/provider/notification_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = HomeViewModel(vsync: this);

    // Post frame callback ile initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel.initialize(context);
        _checkForUpdates();
        unawaited(_refreshNotifications());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshNotifications());
    }
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    final provider = context.read<NotificationProvider>();

    // Background isolate tarafından kaydedilen push'ı badge'e hemen taşı.
    await provider.loadNotifications();
    if (!mounted) return;

    // Sunucudaki unread_count ile local durumu kesinleştir.
    await provider.syncNotifications(context);
  }

  /// 🔄 Version kontrolü - arka planda
  void _checkForUpdates() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.hasShownVersionCheckThisSession) return;

    // 1 saniye sonra kontrol et
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;

      final wasDialogShown =
          await VersionChecker.checkAndShowUpdateDialog(context);
      if (wasDialogShown) {
        userProvider.markVersionCheckAsShown();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
          backgroundColor:
              isDarkMode ? const Color(0xFF070A10) : const Color(0xFFF5F6F8),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _AnimatedAppBar(viewModel: _viewModel),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'home_featured'.tr(),
                    trailing: 'announcement'.tr(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: AnnouncementCarousel(),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'home_quick_action'.tr(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: RequestSongCard(),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'home_explore'.tr(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.45,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.15,
              ),
            ),
        ],
      ),
    );
  }
}
