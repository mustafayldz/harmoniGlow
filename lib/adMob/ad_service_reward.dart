import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:drumly/adMob/ad_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdServiceReward {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  Completer<void>? _loadCompleter;

  /// Rewarded ad yükleme fonksiyonu, load tamamlandığında _loadCompleter tamamlanır
  void loadRewardedAd() {
    debugPrint('AdServiceReward: Loading rewarded ad...');
    _loadCompleter = Completer<void>();
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdServiceReward: Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _loadCompleter?.complete();
        },
        onAdFailedToLoad: (err) {
          debugPrint(
            'AdServiceReward: Rewarded ad failed to load: ${err.message}',
          );
          _isRewardedAdReady = false;
          _loadCompleter?.complete();
        },
      ),
    );
  }

  /// Konfeti animasyonu ile rewarded ad gösterme
  Future<bool> showRewardedAdWithConfetti(BuildContext context) async {
    debugPrint(
      'AdServiceReward: Attempting to show rewarded ad with confetti...',
    );

    final confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Eğer reklam hazır değilse, yüklemeyi başlat ve bitmesini bekle
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('AdServiceReward: Ad not ready, loading now and awaiting...');
      loadRewardedAd();
      await _loadCompleter?.future;

      // Tekrar kontrol et
      if (!_isRewardedAdReady || _rewardedAd == null) {
        debugPrint('AdServiceReward: Ad failed to load or still not ready.');
        return false;
      }
    }

    final rewardCompleter = Completer<bool>();
    debugPrint('AdServiceReward: Rewarded ad is ready, showing now.');

    // Reklamın tam ekran içerik callback'leri
    _rewardedAd!
      ..fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('AdServiceReward: Ad dismissed before earning reward.');
          ad.dispose();
          rewardCompleter.complete(false);
          debugPrint('AdServiceReward: Reloading rewarded ad after dismissal.');
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('AdServiceReward: Failed to show ad: ${err.message}');
          ad.dispose();
          rewardCompleter.complete(false);
          debugPrint(
            'AdServiceReward: Reloading rewarded ad after show failure.',
          );
          loadRewardedAd();
        },
      )
      ..setImmersiveMode(true);

    debugPrint('AdServiceReward: Calling show() on rewarded ad.');

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint(
          'AdServiceReward: User earned reward! Amount: ${reward.amount}, Type: ${reward.type}',
        );

        // Konfeti animasyonu başlat
        _showConfettiAnimation(context, confettiController);

        rewardCompleter.complete(true);
      },
    );

    // Durumu sıfırla ve bir sonraki yükleme başlat
    _rewardedAd = null;
    _isRewardedAdReady = false;
    debugPrint('AdServiceReward: Loading next rewarded ad after show.');
    loadRewardedAd();

    return rewardCompleter.future;
  }

  /// Konfeti animasyonu gösterme fonksiyonu
  void _showConfettiAnimation(
    BuildContext context,
    ConfettiController confettiController,
  ) {
    final overlay = Overlay.of(context);

    late OverlayEntry confettiEntry;

    confettiEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              // Sol üstten konfeti
              Positioned(
                top: 0,
                left: 0,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: 1.5708, // Aşağı doğru (π/2 radyan)
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                  colors: const [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.pink,
                    Colors.purple,
                    Colors.orange,
                  ],
                ),
              ),
              // Sağ üstten konfeti
              Positioned(
                top: 0,
                right: 0,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirection: 1.5708, // Aşağı doğru
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.1,
                  colors: const [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.pink,
                    Colors.purple,
                    Colors.orange,
                  ],
                ),
              ),
              // Ortadan konfeti
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: MediaQuery.of(context).size.width * 0.5,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  colors: const [
                    Colors.red,
                    Colors.blue,
                    Colors.green,
                    Colors.yellow,
                    Colors.pink,
                    Colors.purple,
                    Colors.orange,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(confettiEntry);
    confettiController.play();

    // 3 saniye sonra konfeti animasyonunu kaldır
    Future.delayed(const Duration(seconds: 3), () {
      confettiController.stop();
      confettiEntry.remove();
    });
  }

  /// Sadece showRewardedAd çağırılarak reklamı yükleyip göstermeye çalışır
  Future<bool> showRewardedAd() async {
    debugPrint('AdServiceReward: Attempting to show rewarded ad...');

    // Eğer reklam hazır değilse, yüklemeyi başlat ve bitmesini bekle
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('AdServiceReward: Ad not ready, loading now and awaiting...');
      loadRewardedAd();
      await _loadCompleter?.future;

      // Tekrar kontrol et
      if (!_isRewardedAdReady || _rewardedAd == null) {
        debugPrint('AdServiceReward: Ad failed to load or still not ready.');
        return false;
      }
    }

    final rewardCompleter = Completer<bool>();
    debugPrint('AdServiceReward: Rewarded ad is ready, showing now.');

    // Reklamın tam ekran içerik callback'leri
    _rewardedAd!
      ..fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('AdServiceReward: Ad dismissed before earning reward.');
          ad.dispose();
          rewardCompleter.complete(false);
          debugPrint('AdServiceReward: Reloading rewarded ad after dismissal.');
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('AdServiceReward: Failed to show ad: ${err.message}');
          ad.dispose();
          rewardCompleter.complete(false);
          debugPrint(
            'AdServiceReward: Reloading rewarded ad after show failure.',
          );
          loadRewardedAd();
        },
      )
      ..setImmersiveMode(true);

    debugPrint('AdServiceReward: Calling show() on rewarded ad.');

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint(
          'AdServiceReward: User earned reward! Amount: ${reward.amount}, Type: ${reward.type}',
        );
        rewardCompleter.complete(true);
      },
    );

    // Durumu sıfırla ve bir sonraki yükleme başlat
    _rewardedAd = null;
    _isRewardedAdReady = false;
    debugPrint('AdServiceReward: Loading next rewarded ad after show.');
    loadRewardedAd();

    return rewardCompleter.future;
  }
}
