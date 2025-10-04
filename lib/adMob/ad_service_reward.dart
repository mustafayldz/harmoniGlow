import 'dart:async';

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
