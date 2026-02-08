// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // WEB CONFIG
      return const FirebaseOptions(
        apiKey: "AIzaSyDwX0l7HeoLSZG_-llnOIeMH6Wry5eFBPs",
        authDomain: "parking-login-46846.firebaseapp.com",
        projectId: "parking-login-46846",
        storageBucket: "parking-login-46846.firebasestorage.app",
        messagingSenderId: "909497564479",
        appId: "1:909497564479:web:db469dcfe5fbab9f85a78a",
        measurementId: "G-7Q6DJ0NM78",
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      // ANDROID CONFIG
      return const FirebaseOptions(
        apiKey: "AIzaSyDYFulI2UnyIkO-84cVcLzyXmHjlp0ZNU8",
        appId: "1:909497564479:android:25d27e01a9bf489485a78a",
        messagingSenderId: "909497564479",
        projectId: "parking-login-46846",
        storageBucket: "parking-login-46846.firebasestorage.app",
      );
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }
}
