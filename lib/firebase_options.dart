// Placeholder Firebase options for the IIM Shillong POC.
// Replace this file by running: dart pub global activate flutterfire_cli && flutterfire configure
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'iim-shillong-community-poc',
    authDomain: 'iim-shillong-community-poc.firebaseapp.com',
    storageBucket: 'iim-shillong-community-poc.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_ANDROID_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'iim-shillong-community-poc',
    storageBucket: 'iim-shillong-community-poc.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'iim-shillong-community-poc',
    storageBucket: 'iim-shillong-community-poc.appspot.com',
    iosBundleId: 'in.ac.iimshillong.iimShillongCommunity',
  );
}
