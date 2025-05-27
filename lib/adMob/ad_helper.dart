import 'dart:io';

class AdHelper {
  String get interstitialAdUnitId {
    final String id = Platform.isIOS
        // ? 'ca-app-pub-8628075241374370/2832782514' // iOS gerçek ID
        ? 'ca-app-pub-3940256099942544/1033173712' // iOS test ID
        // : 'ca-app-pub-8628075241374370/2951126614'; // Android gerçek ID
        : 'ca-app-pub-3940256099942544/1033173712'; // Android test ID
    return id;
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Android test ID
      // return 'ca-app-pub-8628075241374370/5569852413'; // Android gerçek ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS test ID
      // return 'ca-app-pub-8628075241374370/7819469591'; // iOS gerçek ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
