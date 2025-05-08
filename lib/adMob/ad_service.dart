import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drumly/adMob/ad_helper.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isLoading = false;

  /// Interstitial reklamı yükler, gösterir ve reklam kapatıldığında
  /// Future’ı tamamlar. Hata olursa yine tamamlar.
  Future<void> showInterstitialAd() {
    if (_isLoading) {
      debugPrint(
          '[AdService] showInterstitialAd: Zaten yükleniyor, hemen tamamlanıyor.');
      return Future.value();
    }
    _isLoading = true;
    final completer = Completer<void>();

    debugPrint(
        '[AdService] Interstitial load başlıyor. UnitID=${AdHelper().interstitialAdUnitId}');
    InterstitialAd.load(
      adUnitId: AdHelper().interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('[AdService] onAdLoaded: Reklam yüklendi.');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint(
                  '[AdService] onAdDismissedFullScreenContent: Reklam kapatıldı.');
              ad.dispose();
              _isLoading = false;
              completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                  '[AdService] onAdFailedToShowFullScreenContent: Hata gösterme sırasında: ${error.message}');
              ad.dispose();
              _isLoading = false;
              completer.complete();
            },
          );
          debugPrint('[AdService] ad.show() çağrılıyor.');
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint(
              '[AdService] onAdFailedToLoad: Yükleme hatası: ${error.message}');
          _isLoading = false;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }
}
