class Env {
  // Firebase Configuration
  static const String firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );

  static const String firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );

  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  // AdMob Configuration
  static const String admobRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
  );

  static const String admobRewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
  );

  static const String admobInterstitialAndroid = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
  );

  static const String admobInterstitialIos = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
  );

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  // Validate environment variables
  static bool get isValid =>
      firebaseAndroidApiKey.isNotEmpty &&
      firebaseIosApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
