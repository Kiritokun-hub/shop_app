// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0Axe0rSdTViiuVE3GHaCPqFLJn5Hrh-8',
    appId: '1:384795057808:web:660364dbf5ca62a9ca0215',
    messagingSenderId: '384795057808',
    projectId: 'vulcanizershop-dd4e9',
    authDomain: 'vulcanizershop-dd4e9.firebaseapp.com',
    storageBucket: 'vulcanizershop-dd4e9.appspot.com',
    measurementId: 'G-9LSHYE9S45',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7mkl-KzqtHQTcY096nzX6t2AGyzusSD4',
    appId: '1:384795057808:android:b818cebcf516a9c1ca0215',
    messagingSenderId: '384795057808',
    projectId: 'vulcanizershop-dd4e9',
    storageBucket: 'vulcanizershop-dd4e9.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDyYXLRLvihohB9AMypVlvzo9o60UDBpsA',
    appId: '1:384795057808:ios:e8408c8341c2a262ca0215',
    messagingSenderId: '384795057808',
    projectId: 'vulcanizershop-dd4e9',
    storageBucket: 'vulcanizershop-dd4e9.appspot.com',
    iosBundleId: 'com.example.shopApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDyYXLRLvihohB9AMypVlvzo9o60UDBpsA',
    appId: '1:384795057808:ios:8642aca468b0b4b7ca0215',
    messagingSenderId: '384795057808',
    projectId: 'vulcanizershop-dd4e9',
    storageBucket: 'vulcanizershop-dd4e9.appspot.com',
    iosBundleId: 'com.example.shopApp.RunnerTests',
  );
}
