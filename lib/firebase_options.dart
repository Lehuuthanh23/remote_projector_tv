// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

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
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDm3vrWSzs2_EyCLFLNMz-udrw1DoC4CA',
    appId: '1:469868592109:android:de63ac62600292b5ddc5e4',
    messagingSenderId: '469868592109',
    projectId: 'remote-projector-27649',
    storageBucket: 'remote-projector-27649.appspot.com',
  );
}
