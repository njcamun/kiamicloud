// Ficheiro placeholder — substitua com: flutterfire configure
// Ver docs/FIREBASE_SETUP.md
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
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'Plataforma nao suportada: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBnUpHj0_MXmD_AR_qFMMLLMBLe4O0b2wI',
    appId: '1:372525178999:web:c1c7d6bc79dfc845d16672',
    messagingSenderId: '372525178999',
    projectId: 'kiamicloud',
    authDomain: 'kiamicloud.firebaseapp.com',
    storageBucket: 'kiamicloud.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGs16fPxkQJ64XnpSrMvPsUNXC0SK33ZU',
    appId: '1:372525178999:android:a8ecf7d1abb009e4d16672',
    messagingSenderId: '372525178999',
    projectId: 'kiamicloud',
    storageBucket: 'kiamicloud.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBnUpHj0_MXmD_AR_qFMMLLMBLe4O0b2wI',
    appId: '1:372525178999:web:642b9a16e65c7271d16672',
    messagingSenderId: '372525178999',
    projectId: 'kiamicloud',
    authDomain: 'kiamicloud.firebaseapp.com',
    storageBucket: 'kiamicloud.firebasestorage.app',
  );

}