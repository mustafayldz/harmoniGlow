import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:drumly/adMob/ad_helper.dart';

/// Sayfa açıldığında interstitial reklamı yükleyip gösterir,
/// reklama tıklayıp kapatınca child'ı ekrana getirir.
class InterstitialAdWrapper extends StatefulWidget {
  const InterstitialAdWrapper({
    super.key,
  });

  @override
  InterstitialAdWrapperState createState() => InterstitialAdWrapperState();
}

class InterstitialAdWrapperState extends State<InterstitialAdWrapper> {
  InterstitialAd? _ad;
  bool _adDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadAndShowAd();
  }

  void _loadAndShowAd() {
    InterstitialAd.load(
      adUnitId: AdHelper().interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              setState(() {
                _adDismissed = true;
              });
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              setState(() {
                _adDismissed = true;
              });
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial load failed: ${err.message}');
          // Yükleme başarısızsa child’ı hemen göster
          setState(() {
            _adDismissed = true;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reklam kapatıldıysa veya yükleme başarısızsa child'ı göster
    if (_adDismissed) {
      return const Center(
        child: Text('Reklam kapatıldı veya yükleme başarısız oldu'),
      );
    }

    // Aksi halde yüklenme/sunulma sırasında bir bekleme gösterebilirsin
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
