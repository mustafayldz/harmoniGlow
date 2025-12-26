import 'package:drumly/screens/home/components/card_data.dart';
import 'package:drumly/screens/my_drum/drum_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/adMob/ad_service.dart';
import 'package:drumly/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:drumly/constants.dart';
import 'package:provider/provider.dart';
import 'package:drumly/blocs/bluetooth/bluetooth_bloc.dart';

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
    final bluetoothBloc = Provider.of<BluetoothBloc>(context, listen: false);
    final isConnected = bluetoothBloc.state.isConnected;
    _initCards(isConnected);
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

    await Future.delayed(const Duration(seconds: 10));

    // Flag'i işaretle ki bir daha gösterilmesin
    userProvider.markInitialAdAsShown();

    // Reklam göster
    AdService.instance.showInterstitialAd();
  }

  void _initCards(bool isBluetoothConnected) {
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

      if (isBluetoothConnected)
        CardData(
          key: 'mydrum',
          title: 'My Drum',
          subtitle: 'Customize your drum kit',
          color: AppColors.drumBlue,
          icon: Icons.settings_input_component_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
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

  /// Update cards when Bluetooth connection state changes
  void updateCards(bool isBluetoothConnected) {
    _initCards(isBluetoothConnected);
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
