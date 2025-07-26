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
import 'package:drumly/screens/requested_songs/requested_songs_page.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/provider/notification_provider.dart';
import 'package:drumly/shared/modern_components.dart';
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
        curve: Curves.easeOutBack,
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
        subtitle: 'improveYourSkills'.tr(),
        icon: Icons.school_outlined,
        gradient: ModernGradients.successCard,
        onTap: () => _navigateToPage(const TrainingView()),
      ),
      _CardData(
        key: 'songs',
        title: 'songs'.tr(),
        subtitle: 'playYourFavorites'.tr(),
        icon: Icons.music_note_outlined,
        gradient: ModernGradients.secondaryCard,
        onTap: () => _navigateToPage(const SongView()),
      ),
      _CardData(
        key: 'myBeats',
        title: 'myBeats'.tr(),
        subtitle: 'yourCreations'.tr(),
        icon: Icons.library_music_outlined,
        gradient: ModernGradients.accentCard,
        onTap: () => _navigateToPage(const MyBeatsView()),
      ),
      _CardData(
        key: 'myDrum',
        title: 'myDrum'.tr(),
        subtitle: 'customizeYourKit'.tr(),
        icon: Icons.music_video_outlined,
        gradient: ModernGradients.primaryCard,
        onTap: () => _navigateToPage(const DrumAdjustment()),
      ),
      _CardData(
        key: 'beatMaker',
        title: 'beatMaker'.tr(),
        subtitle: 'createNewBeats'.tr(),
        icon: Icons.create_outlined,
        gradient: ModernGradients.warningCard,
        onTap: () => _navigateToPage(const BeatMakerView()),
      ),
      _CardData(
        key: 'requestedSongs',
        title: 'requestedSongs'.tr(),
        subtitle: 'communityRequests'.tr(),
        icon: Icons.queue_music_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigateToPage(const RequestedSongsPage()),
      ),
      _CardData(
        key: 'settings',
        title: 'settings'.tr(),
        subtitle: 'preferences'.tr(),
        icon: Icons.settings_outlined,
        gradient: ModernGradients.errorCard,
        onTap: () => _navigateToPage(const SettingView()),
      ),
      _CardData(
        key: 'bluetooth',
        title: 'bluetooth'.tr(),
        subtitle: 'connectDevice'.tr(),
        icon: Icons.bluetooth_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        onTap: () => _navigateToPage(const FindDevicesView()),
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

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BluetoothBloc>().state;
    final isConnected = state.isConnected;
    final deviceName = state.connectedDevice?.advName ?? 'Unknown Device';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Rebuild localized cards when language changes
    _initCards();

    return ModernScreenLayout(
      title: 'Drumly',
      isDarkMode: isDarkMode,
      showBackButton: false,
      actions: [
        // Notification Icon
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            final hasUnread = notificationProvider.unreadCount > 0;
            return Stack(
              children: [
                ModernIconButton(
                  icon: Icons.notifications_outlined,
                  onPressed: () => _navigateToPage(const NotificationView()),
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                if (hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: ModernColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Connection Status Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildConnectionStatusCard(
                isConnected,
                deviceName,
                isDarkMode,
              ),
            ),
          ),

          // Feature Cards Grid
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final card = _cards[index];
                  return SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildModernFeatureCard(card, isDarkMode),
                    ),
                  );
                },
                childCount: _cards.length,
              ),
            ),
          ),

          // Ad Section (Placeholder)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ModernGlassCard(
                isDarkMode: isDarkMode,
                height: 80,
                child: const Center(
                  child: Text(
                    'Ad Space',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  /// 📡 Connection Status Card
  Widget _buildConnectionStatusCard(
    bool isConnected,
    String deviceName,
    bool isDarkMode,
  ) =>
      ModernGlassCard(
        isDarkMode: isDarkMode,
        margin: const EdgeInsets.only(bottom: 16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isConnected
                    ? ModernGradients.successCard
                    : ModernGradients.errorCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'connected'.tr() : 'disconnected'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  if (isConnected) ...[
                    const SizedBox(height: 4),
                    Text(
                      deviceName,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isConnected)
              ModernIconButton(
                icon: Icons.bluetooth_searching,
                onPressed: () => _navigateToPage(const FindDevicesView()),
                size: 20,
                padding: 8,
              ),
          ],
        ),
      );

  /// 🎨 Modern Feature Card
  Widget _buildModernFeatureCard(_CardData card, bool isDarkMode) =>
      ModernGradientCard(
        gradient: card.gradient,
        onTap: () {
          // Analytics
          FirebaseAnalytics.instance.logEvent(
            name: 'card_tapped',
            parameters: {'card_type': card.key},
          );
          card.onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                card.icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const Spacer(),

            // Title
            Text(
              card.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              card.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}

/// 📋 Card Data Model
class _CardData {
  _CardData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
}
