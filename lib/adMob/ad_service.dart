import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drumly/adMob/ad_helper.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isLoading = false;
  InterstitialAd? interstitialAd;

  /// Reklam göstermeden önce immersive mode'u kapat (X butonu görünsün)
  Future<void> _disableImmersiveForAd() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Kısa bir bekleme - UI değişikliğinin uygulanması için
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Reklam göster ve tamamlanmasını bekle
  Future<bool> showInterstitialAd() async {
    if (_isLoading) {
      debugPrint('Ad is already loading, skipping...');
      return true; // Zaten yükleniyor, navigasyona izin ver
    }

    _isLoading = true;
    final completer = Completer<bool>();

    // 🔑 Reklam göstermeden önce immersive mode'u kapat
    // Bu sayede reklamın X (kapat) butonu görünür ve tıklanabilir olur
    await _disableImmersiveForAd();

    try {
      await InterstitialAd.load(
        adUnitId: AdHelper().interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('Interstitial ad loaded successfully');
            interstitialAd = ad;

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('Interstitial ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed - allowing navigation');
                ad.dispose();
                interstitialAd = null;
                _isLoading = false;
                if (!completer.isCompleted) {
                  completer
                      .complete(true); // Reklam kapatıldı, navigasyona izin ver
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: $error');
                ad.dispose();
                interstitialAd = null;
                _isLoading = false;
                if (!completer.isCompleted) {
                  completer
                      .complete(true); // Hata olsa bile navigasyona izin ver
                }
              },
              onAdClicked: (ad) {
                debugPrint('Interstitial ad clicked');
              },
            );

            // Reklamı göster
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('Interstitial ad failed to load: $error');
            _isLoading = false;
            if (!completer.isCompleted) {
              completer.complete(true); // Yüklenemezse navigasyona izin ver
            }
          },
        ),
      );

      // Timeout ekle (10 saniye sonra otomatik olarak izin ver)
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          debugPrint('Ad timeout - allowing navigation');
          _isLoading = false;
          completer.complete(true);
        }
      });
    } catch (e) {
      debugPrint('Error in showInterstitialAd: $e');
      _isLoading = false;
      if (!completer.isCompleted) {
        completer.complete(true); // Hata durumunda navigasyona izin ver
      }
    }

    return completer.future;
  }

  /// Loading indicator ile reklam göster
  /// ⚠️ DİKKAT: Bu fonksiyon artık loading dialog GÖSTERMIYOR
  /// Loading dialog reklamın X butonunu engelleyebilir (Families Policy ihlali)
  Future<bool> showInterstitialAdWithLoading(BuildContext context) async => showInterstitialAd();

  /// Servisi temizle
  void dispose() {
    interstitialAd?.dispose();
    interstitialAd = null;
    _isLoading = false;
  }
}
