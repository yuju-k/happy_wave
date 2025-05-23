// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXTgehtB-r81FikpDPZQxy5beVC28V1fc',
    appId: '1:694452238656:web:e3663f1058a1d62d1e22a5',
    messagingSenderId: '694452238656',
    projectId: 'happywave-4e66e',
    authDomain: 'happywave-4e66e.firebaseapp.com',
    storageBucket: 'happywave-4e66e.firebasestorage.app',
    measurementId: 'G-WGPP6MV8W9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgP89ZFauCod5L5PgzKi6ga8NEdz0HwJ4',
    appId: '1:694452238656:android:a5aa07a7a8b2727e1e22a5',
    messagingSenderId: '694452238656',
    projectId: 'happywave-4e66e',
    storageBucket: 'happywave-4e66e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtyF7DL19rcc7CcidpPvtiEDurOZs_4e0',
    appId: '1:694452238656:ios:df05f7153064a3961e22a5',
    messagingSenderId: '694452238656',
    projectId: 'happywave-4e66e',
    storageBucket: 'happywave-4e66e.firebasestorage.app',
    iosBundleId: 'com.example.happyWave',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCtyF7DL19rcc7CcidpPvtiEDurOZs_4e0',
    appId: '1:694452238656:ios:df05f7153064a3961e22a5',
    messagingSenderId: '694452238656',
    projectId: 'happywave-4e66e',
    storageBucket: 'happywave-4e66e.firebasestorage.app',
    iosBundleId: 'com.example.happyWave',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBXTgehtB-r81FikpDPZQxy5beVC28V1fc',
    appId: '1:694452238656:web:3b9a6e9074dedfd41e22a5',
    messagingSenderId: '694452238656',
    projectId: 'happywave-4e66e',
    authDomain: 'happywave-4e66e.firebaseapp.com',
    storageBucket: 'happywave-4e66e.firebasestorage.app',
    measurementId: 'G-10J8H0PHTM',
  );
}
