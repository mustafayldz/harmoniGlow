import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drumly/adMob/ad_helper.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isLoading = false;
  InterstitialAd? interstitialAd;

  Future<void> showInterstitialAd() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    final completer = Completer<void>();

    await InterstitialAd.load(
      adUnitId: AdHelper().interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          interstitialAd = ad;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isLoading = false;
              completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isLoading = false;
              completer.complete();
            },
          );

          ad.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          completer.complete();
        },
      ),
    );

    return completer.future;
  }
}
