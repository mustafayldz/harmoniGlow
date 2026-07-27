import 'package:drumly/screens/home/components/card_data.dart';
import 'package:drumly/screens/my_drum/drum_model.dart';
import 'package:drumly/services/local_service.dart';
import 'package:drumly/constants.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
  }

  void _initCards(bool isBluetoothConnected) {
    _cards = [
      CardData(
        key: 'songs',
        title: 'songs'.tr(),
        subtitle: 'discoverSongs'.tr(),
        color: const Color(0xFFE4578E),
        icon: Icons.music_note_outlined,
      ),

      // Ritmi Takip Et Oyunu Card
      CardData(
        key: 'retim',
        title: 'rhythmGameTitle'.tr(),
        subtitle: 'rhythmGameSubtitle'.tr(),
        color: const Color(0xFF8075E5),
        icon: Icons.timeline_outlined,
      ),

      if (isBluetoothConnected)
        CardData(
          key: 'mydrum',
          title: 'myDrumTitle'.tr(),
          subtitle: 'myDrumSubtitle'.tr(),
          color: const Color(0xFF4B87E8),
          icon: Icons.settings_input_component_outlined,
        ),

      CardData(
        key: 'settings',
        title: 'settings'.tr(),
        subtitle: 'settingsLedSubtitle'.tr(),
        color: const Color(0xFFE29B42),
        icon: Icons.lightbulb_outline,
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
