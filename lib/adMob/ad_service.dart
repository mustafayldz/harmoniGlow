import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drumly/adMob/ad_helper.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isLoading = false;
  InterstitialAd? interstitialAd;

  /// Interstitial reklamı yükler, gösterir ve reklam kapatıldığında
  /// Future’ı tamamlar. Hata olursa yine tamamlar.
  Future<void> showInterstitialAd() async {
    if (_isLoading) {
      debugPrint('[AdService] showInterstitialAd: Zaten yükleniyor.');
      return;
    }

    _isLoading = true;
    final completer = Completer<void>();

    debugPrint('[AdService] Reklam yükleniyor...');

    await InterstitialAd.load(
      adUnitId: AdHelper().interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('[AdService] Reklam yüklendi.');
          interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdService] Reklam kapatıldı.');
              ad.dispose();
              _isLoading = false;
              completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                '[AdService] Reklam gösterilemedi: ${error.message}',
              );
              ad.dispose();
              _isLoading = false;
              completer.complete();
            },
          );

          debugPrint('[AdService] Reklam gösteriliyor...');
          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint(
            '[AdService] Reklam yüklenemedi: ${error.message}',
          );
          _isLoading = false;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }
}
