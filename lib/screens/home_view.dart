import 'package:drumly/adMob/ad_view.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';
import 'package:drumly/constants.dart';
import 'package:drumly/screens/beat_maker/beat_maker_view.dart';
import 'package:drumly/screens/bluetooth/find_devices_view.dart';
import 'package:drumly/screens/my_beats/my_beats_view.dart';
import 'package:drumly/screens/my_drum/drum_adjustment.dart';
import 'package:drumly/screens/my_drum/drum_model.dart';
import 'package:drumly/screens/settings/setting_view.dart';
import 'package:drumly/screens/songs/song_view.dart';
import 'package:drumly/screens/training/traning_view.dart';
import 'package:drumly/screens/notifications/notification_view.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/provider/notification_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  List<_CardData> _cards = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkLocalStorage();
    _initCards();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initCards() {
    _cards = [
      _CardData(
        key: 'training',
        title: 'training'.tr(),
        subtitle: 'trainWithMusic'.tr(),
        color: AppColors.trainingGreen,
        icon: Icons.school_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        key: 'songs',
        title: 'songs'.tr(),
        subtitle: 'discoverSongs'.tr(),
        color: AppColors.songsPink,
        icon: Icons.music_note_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        key: 'beat maker',
        title: 'beatMaker'.tr(),
        subtitle: 'createBeats'.tr(),
        color: AppColors.makerOrange,
        icon: Icons.create_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        key: 'my beats',
        title: 'myBeats'.tr(),
        subtitle: 'listenToBeats'.tr(),
        color: AppColors.beatsPurple,
        icon: Icons.headphones_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        key: 'my drum',
        title: 'myDrum'.tr(),
        subtitle: 'adjustDrum'.tr(),
        color: AppColors.drumBlue,
        icon: Icons.tune_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _CardData(
        key: 'settings',
        title: 'settings'.tr(),
        subtitle: 'customizeApp'.tr(),
        color: AppColors.settingsRed,
        icon: Icons.settings_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];
  }

  Future<void> _checkLocalStorage() async {
    final savedData = await StorageService.getDrumPartsBulk();
    if (savedData == null) {
      await StorageService.saveDrumPartsBulk(
        DrumParts.drumParts.entries
            .map((e) => DrumModel.fromJson(e.value))
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;
    final deviceName = state.connectedDevice?.advName ?? 'Unknown Device';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Rebuild localized cards when language changes
    _initCards();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    const Color(0xFF0F172A), // Dark slate
                    const Color(0xFF1E293B), // Lighter slate
                    const Color(0xFF334155), // Even lighter
                  ]
                : [
                    const Color(0xFFF8FAFC), // Light gray
                    const Color(0xFFE2E8F0), // Slightly darker
                    const Color(0xFFCBD5E1), // Even darker
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
                  animation: _fadeAnimation,
                  builder: (context, child) => Opacity(
                    opacity: _fadeAnimation.value,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildModernAppBar(isDarkMode),
                    ),
                  ),
                ),
              ),

              // Bluetooth Status
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) => Opacity(
                    opacity: _fadeAnimation.value,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildModernBluetoothBanner(
                        isConnected,
                        deviceName,
                        isDarkMode,
                      ),
                    ),
                  ),
                ),
              ),

              // Cards Grid
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final card = _cards[index];
                      final destination =
                          _getDestination(card.key, isConnected);

                      return AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) => Opacity(
                          opacity: _fadeAnimation.value,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0, 0.3 + (index * 0.1)),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: Interval(
                                  index * 0.1,
                                  1.0,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                            ),
                            child: _buildModernCard(
                              card,
                              destination,
                              isConnected,
                              isDarkMode,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _cards.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(bool isDarkMode) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drumly',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF60A5FA), Color(0xFF34D399)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) =>
                        GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationView(),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            color: isDarkMode ? Colors.white : Colors.black,
                            size: 24,
                          ),
                          if (notificationProvider.hasUnreadNotifications)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC),
                                    width: 2,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  notificationProvider.unreadCount > 99
                                      ? '99+'
                                      : notificationProvider.unreadCount
                                          .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildModernBluetoothBanner(
    bool connected,
    String deviceName,
    bool isDarkMode,
  ) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: GestureDetector(
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FindDevicesView()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: connected
                    ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                    : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (connected ? Colors.green : Colors.red)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    connected
                        ? Icons.bluetooth_connected_rounded
                        : Icons.bluetooth_disabled_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connected
                            ? 'connectedToDevice'.tr()
                            : 'disconnected'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (connected) ...[
                        const SizedBox(height: 2),
                        Text(
                          deviceName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildModernCard(
    _CardData card,
    Widget destination,
    bool isConnected,
    bool isDarkMode,
  ) =>
      GestureDetector(
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

  Future<void> _handleModernTap(
    BuildContext context,
    String key,
    bool isConnected,
    Widget destination,
  ) async {
    try {
      await FirebaseAnalytics.instance.logEvent(name: key.replaceAll(' ', '_'));
      if (!context.mounted) return;

      if (!isConnected && key == 'songs') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdView(
              onAdFinished: () async {
                if (!context.mounted) return;
                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SongView()),
                );
              },
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      }
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
      case 'my drum':
        return isConnected ? const DrumAdjustment() : const FindDevicesView();
      case 'beat maker':
        return const BeatMakerView();
      case 'settings':
        return const SettingView();
      case 'my beats':
        return const MyBeatsView();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _CardData {
  _CardData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.gradient,
  });
  final String key;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final LinearGradient gradient;
}
