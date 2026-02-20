import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart" show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC9gIIGbHYB1hvGlV_2hKXlX09lbp6mCe8",
    appId: "1:154116765305:web:e7090d24aab2d590af06a8",
    messagingSenderId: "154116765305",
    projectId: "ogrenci-davranis-takibi",
    authDomain: "ogrenci-davranis-takibi.firebaseapp.com",
    storageBucket: "ogrenci-davranis-takibi.firebasestorage.app",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyC9gIIGbHYB1hvGlV_2hKXlX09lbp6mCe8",
    appId: "1:154116765305:web:e7090d24aab2d590af06a8",
    messagingSenderId: "154116765305",
    projectId: "ogrenci-davranis-takibi",
    storageBucket: "ogrenci-davranis-takibi.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyC9gIIGbHYB1hvGlV_2hKXlX09lbp6mCe8",
    appId: "1:154116765305:web:e7090d24aab2d590af06a8",
    messagingSenderId: "154116765305",
    projectId: "ogrenci-davranis-takibi",
    storageBucket: "ogrenci-davranis-takibi.firebasestorage.app",
    iosBundleId: "com.example.schooltrackFlutter",
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyC9gIIGbHYB1hvGlV_2hKXlX09lbp6mCe8",
    appId: "1:154116765305:web:e7090d24aab2d590af06a8",
    messagingSenderId: "154116765305",
    projectId: "ogrenci-davranis-takibi",
    storageBucket: "ogrenci-davranis-takibi.firebasestorage.app",
    iosBundleId: "com.example.schooltrackFlutter",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyC9gIIGbHYB1hvGlV_2hKXlX09lbp6mCe8",
    appId: "1:154116765305:web:e7090d24aab2d590af06a8",
    messagingSenderId: "154116765305",
    projectId: "ogrenci-davranis-takibi",
    authDomain: "ogrenci-davranis-takibi.firebaseapp.com",
    storageBucket: "ogrenci-davranis-takibi.firebasestorage.app",
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: "AIzaSyC9gIIGbHYB1hvGlV_2hKXlX09lbp6mCe8",
    appId: "1:154116765305:web:e7090d24aab2d590af06a8",
    messagingSenderId: "154116765305",
    projectId: "ogrenci-davranis-takibi",
    authDomain: "ogrenci-davranis-takibi.firebaseapp.com",
    storageBucket: "ogrenci-davranis-takibi.firebasestorage.app",
  );
}
