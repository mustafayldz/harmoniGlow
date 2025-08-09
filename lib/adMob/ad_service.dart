import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drumly/adMob/ad_helper.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isLoading = false;
  InterstitialAd? interstitialAd;

  /// Reklam göster ve tamamlanmasını bekle
  Future<bool> showInterstitialAd() async {
    if (_isLoading) {
      debugPrint('Ad is already loading, skipping...');
      return true; // Zaten yükleniyor, navigasyona izin ver
    }

    _isLoading = true;
    final completer = Completer<bool>();

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

      // Timeout ekle (30 saniye sonra otomatik olarak izin ver)
      Timer(const Duration(seconds: 30), () {
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
  Future<bool> showInterstitialAdWithLoading(BuildContext context) async {
    bool? result;

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const PopScope(
        canPop: false, // Geri butonunu engelle
        child: AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  'Reklam yükleniyor...\nLütfen bekleyin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Reklam göster ve tamamlanmasını bekle
      result = await showInterstitialAd();
    } finally {
      // Loading dialog'u kapat (context hala geçerliyse)
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    return result;
  }

  /// Servisi temizle
  void dispose() {
    interstitialAd?.dispose();
    interstitialAd = null;
    _isLoading = false;
  }
}
