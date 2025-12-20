import 'dart:io';
import 'package:drumly/env.dart';

/// SECURITY: AdMob IDs now loaded from environment variables
/// Run with: flutter run --dart-define-from-file=.env
class AdHelper {
  String get interstitialAdUnitId {
    final String id = Platform.isIOS 
        ? Env.admobInterstitialIos 
        : Env.admobInterstitialAndroid;
    return id;
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return Env.admobRewardedAndroid;
    } else if (Platform.isIOS) {
      return Env.admobRewardedIos;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
