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
  static const String admobBannerAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // Test ID
  );

  static const String admobBannerIos = String.fromEnvironment(
    'ADMOB_BANNER_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716', // Test ID
  );

  static const String admobRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917', // Test ID
  );

  static const String admobRewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313', // Test ID
  );

  // Validate environment variables
  static bool get isValid =>
      firebaseAndroidApiKey.isNotEmpty &&
      firebaseIosApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
