import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:drumly/env.dart';

/// SECURITY: This file now uses environment variables
/// Run with: flutter run --dart-define-from-file=.env
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get android => const FirebaseOptions(
        apiKey: Env.firebaseAndroidApiKey,
        appId: Env.firebaseAppIdAndroid,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        storageBucket: Env.firebaseStorageBucket,
      );

  static FirebaseOptions get ios => const FirebaseOptions(
        apiKey: Env.firebaseIosApiKey,
        appId: Env.firebaseAppIdIos,
        messagingSenderId: Env.firebaseMessagingSenderId,
        projectId: Env.firebaseProjectId,
        storageBucket: Env.firebaseStorageBucket,
        iosBundleId: 'com.drumly.mobile',
      );
}