// lib/firebase_options.dart
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  // ✅ WEB - Using your configuration from the screenshot
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAbozzCLi1_xF2rosQKupwUBqoGM3Z4Qu8',
    appId: '1:551573133643:web:b9b0e88c6c4df627bff0ce',
    messagingSenderId: '551573133643',
    projectId: 'mindheal-pro',
    authDomain: 'mindheal-pro.firebaseapp.com',
    storageBucket: 'mindheal-pro.firebasestorage.app',
    measurementId: '', // You can leave this empty if not using Analytics
  );

  // ✅ ANDROID - Using your configuration from the screenshot
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbozzCLi1_xF2rosQKupwUBqoGM3Z4Qu8', // Same API key works
    appId: '1:551573133643:android:fa49ace007454dc5bff0ce',
    messagingSenderId: '551573133643',
    projectId: 'mindheal-pro',
    storageBucket: 'mindheal-pro.firebasestorage.app',
  );

  // ✅ iOS - You'll need to add iOS app in Firebase console first
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbozzCLi1_xF2rosQKupwUBqoGM3Z4Qu8',
    appId: '1:551573133643:ios:YOUR_IOS_APP_ID', // You need to add iOS app
    messagingSenderId: '551573133643',
    projectId: 'mindheal-pro',
    storageBucket: 'mindheal-pro.firebasestorage.app',
    iosBundleId: 'com.mentalhealth.mentalWellnessApp', // From your screenshot
  );

  // ✅ macOS - Similar to iOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAbozzCLi1_xF2rosQKupwUBqoGM3Z4Qu8',
    appId: '1:551573133643:ios:YOUR_MACOS_APP_ID', // You need to add iOS app
    messagingSenderId: '551573133643',
    projectId: 'mindheal-pro',
    storageBucket: 'mindheal-pro.firebasestorage.app',
    iosBundleId: 'com.mentalhealth.mentalWellnessApp',
  );

  // ✅ Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAbozzCLi1_xF2rosQKupwUBqoGM3Z4Qu8',
    appId: '1:551573133643:web:b9b0e88c6c4df627bff0ce', // Web app ID works for Windows
    messagingSenderId: '551573133643',
    projectId: 'mindheal-pro',
    authDomain: 'mindheal-pro.firebaseapp.com',
    storageBucket: 'mindheal-pro.firebasestorage.app',
  );
}