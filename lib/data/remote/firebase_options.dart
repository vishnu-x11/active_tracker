
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCZnmL2Z4NlDpNFkAceW994yZjj6EwYmjc',
    appId: '1:773988908810:web:d60d65399697a3241f44f3',
    messagingSenderId: '773988908810',
    projectId: 'active-health-f8654',
    authDomain: 'active-health-f8654.firebaseapp.com',
    storageBucket: 'active-health-f8654.firebasestorage.app',
    measurementId: 'G-5PBLKFFGWG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBuHTXOKlbdvx0EMQBxk7zS0LnNCUbsn5w',
    appId: '1:773988908810:android:0d6045b3ff04ac621f44f3',
    messagingSenderId: '773988908810',
    projectId: 'active-health-f8654',
    storageBucket: 'active-health-f8654.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBH4xcGFdoTrwHg8ey0Pp8wKWhOtWjrLYo',
    appId: '1:773988908810:ios:6af944968bc370711f44f3',
    messagingSenderId: '773988908810',
    projectId: 'active-health-f8654',
    storageBucket: 'active-health-f8654.firebasestorage.app',
    iosBundleId: 'com.example.activeTracker',
  );
}
