import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Bu widget’ı, reklam göstermek istediğiniz her sayfanın en üstünde wrap edin.
/// initState’te reklamı yükler, gösterir. Reklam kapatılınca veya hata olursa
/// child’ı gösterir ve widget dispose’unda tüm kaynakları temizler.
class InterstitialAdWrapper extends StatefulWidget {
  const InterstitialAdWrapper({
    required this.adUnitId,
    required this.child,
    super.key,
    this.onAdComplete,
  });

  /// AdMob’dan aldığınız Interstitial Ad Unit ID
  final String adUnitId;

  /// Reklam gösterimi tamamlandığında veya hata durumunda asıl gösterilecek sayfa
  final Widget child;

  /// Reklam kapandığında ekstra bir şey yapmak isterseniz buraya callback ekleyebilirsiniz
  final VoidCallback? onAdComplete;

  @override
  InterstitialAdWrapperState createState() => InterstitialAdWrapperState();
}

class InterstitialAdWrapperState extends State<InterstitialAdWrapper> {
  InterstitialAd? _ad;
  bool _showChild = false;

  @override
  void initState() {
    super.initState();
    // Reklamı gerçekten "sayfa açıldıktan sonra" yükleyip göstermek için
    // bir frame sonrası tetikleyelim:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndShowAd();
    });
  }

  void _loadAndShowAd() {
    print("-> Interstitial yükleniyor");
    InterstitialAd.load(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print("-> Interstitial yüklendi, gösteriliyor");
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print("-> Interstitial kapatıldı");
              ad.dispose();
              _complete();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              print("-> Gösterim hatası: ${err.message}");
              ad.dispose();
              _complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (err) {
          print("-> Yükleme hatası: ${err.message}");
          _complete();
        },
      ),
    );
  }

  void _complete() {
    if (mounted) {
      setState(() => _showChild = true);
      widget.onAdComplete?.call();
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showChild) {
      // Reklam bitti ya da hata verince asıl içeriği göster
      return widget.child;
    }
    // Reklam yüklenirken ya da gösterilirken bekletme ekranı
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
