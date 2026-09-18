// File generated for E-Sport Sudan
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
    apiKey: 'AIzaSyCtAgYyfkBwPq080YjlSTdIuuoWvT_Y-G0',
    appId: '1:811746328042:web:fd361589a0eb3b00dcc693',
    messagingSenderId: '811746328042',
    projectId: 'e-sport-sudan',
    authDomain: 'e-sport-sudan.firebaseapp.com',
    storageBucket: 'e-sport-sudan.firebasestorage.app',
    databaseURL: 'https://e-sport-sudan-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtAgYyfkBwPq080YjlSTdIuuoWvT_Y-G0',
    appId: '1:811746328042:android:fd361589a0eb3b00dcc693',
    messagingSenderId: '811746328042',
    projectId: 'e-sport-sudan',
    storageBucket: 'e-sport-sudan.firebasestorage.app',
    databaseURL: 'https://e-sport-sudan-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtAgYyfkBwPq080YjlSTdIuuoWvT_Y-G0',
    appId: '1:811746328042:ios:fd361589a0eb3b00dcc693',
    messagingSenderId: '811746328042',
    projectId: 'e-sport-sudan',
    storageBucket: 'e-sport-sudan.firebasestorage.app',
    databaseURL: 'https://e-sport-sudan-default-rtdb.firebaseio.com',
  );
}
