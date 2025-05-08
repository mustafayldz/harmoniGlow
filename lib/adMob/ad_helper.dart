import 'dart:io';

class AdHelper {
  String get interstitialAdUnitId {
    final String id = Platform.isIOS
        // ? 'ca-app-pub-8628075241374370/2832782514'
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-8628075241374370/2951126614';
    // Geliştirmede test ID’si; üretimde kendi AdMob’daki gerçek ID’nle değiştir
    return id;
  }
}
