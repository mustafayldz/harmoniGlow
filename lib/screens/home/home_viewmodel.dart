import 'package:drumly/screens/home/components/card_data.dart';
import 'package:drumly/screens/my_drum/drum_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/adMob/ad_service.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/constants.dart';
import 'package:provider/provider.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required TickerProvider vsync}) {
    _initAnimations(vsync);
  }
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<CardData> _cards = [];

  // Getters
  AnimationController get animationController => _animationController;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<Offset> get slideAnimation => _slideAnimation;
  List<CardData> get cards => _cards;

  void _initAnimations(TickerProvider vsync) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: vsync,
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
  }

  void initialize(BuildContext context) {
    _checkLocalStorage();
    _initCards();
    _animationController.forward();

    // 🎯 Ana sayfa açıldıktan 30 saniye sonra reklam göster
    _scheduleInitialAd(context);
  }

  /// 📺 Ana sayfa için zamanlı reklam
  void _scheduleInitialAd(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Eğer bu session'da zaten gösterildiyse tekrar gösterme
    if (userProvider.hasShownInitialAdThisSession) {
      return;
    }

    await Future.delayed(const Duration(seconds: 30));

    // Flag'i işaretle ki bir daha gösterilmesin
    userProvider.markInitialAdAsShown();

    // Reklam göster
    AdService.instance.showInterstitialAd();
  }

  void _initCards() {
    _cards = [
      CardData(
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
      CardData(
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

      CardData(
        key: 'songsv2',
        title: 'Songs V2',
        subtitle: 'New song system from backend',
        color: const Color(0xFF8B5CF6),
        icon: Icons.library_music_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      CardData(
        key: 'settings',
        title: 'settings'.tr(),
        subtitle: 'Test new LED system',
        color: AppColors.settingsRed,
        icon: Icons.lightbulb_outline,
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];
    notifyListeners();
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
