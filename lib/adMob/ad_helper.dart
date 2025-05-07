import 'dart:io';

class AdHelper {
  String get interstitialAdUnitId {
    final String id = Platform.isIOS
        ? 'ca-app-pub-8628075241374370/7011684769'
        : 'ca-app-pub-8628075241374370/7011684769';
    // Geliştirmede test ID’si; üretimde kendi AdMob’daki gerçek ID’nle değiştir
    return id;
  }
}
