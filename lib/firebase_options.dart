// GENERATED FILE — PLACEHOLDER.
//
// ⚠️  Replace this file by running FlutterFire CLI in the project root:
//        dart pub global activate flutterfire_cli
//        flutterfire configure
//     That command creates a real firebase_options.dart tied to YOUR Firebase
//     project (it overwrites this file). See SETUP_ONLINE.md.
//
// The placeholder values below let the app COMPILE, but Firebase will fail to
// initialise at runtime until you run `flutterfire configure`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

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
        return ios;
      default:
        return web;
    }
  }

  // TODO(flutterfire): replace every 'REPLACE_ME' via `flutterfire configure`.

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB6XXCt27lzhuKiVvgZIPp9ZOqh-JI2VKo',
    appId: '1:868091531285:web:9d8a5e94f4d23619ef3e1c',
    messagingSenderId: '868091531285',
    projectId: 'mafia-6711',
    authDomain: 'mafia-6711.firebaseapp.com',
    databaseURL: 'https://mafia-6711-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'mafia-6711.firebasestorage.app',
    measurementId: 'G-CX70F3FW7H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDX8fy2xZcX0HhqIBCyMoku_Vzhn-9vNUg',
    appId: '1:868091531285:android:ae474224eb9aa1bdef3e1c',
    messagingSenderId: '868091531285',
    projectId: 'mafia-6711',
    databaseURL: 'https://mafia-6711-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'mafia-6711.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChRVdscMHWCvyGiZ4ZHU0Q0g4LEvXIPYQ',
    appId: '1:868091531285:ios:cdd89da552cc81fdef3e1c',
    messagingSenderId: '868091531285',
    projectId: 'mafia-6711',
    databaseURL: 'https://mafia-6711-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'mafia-6711.firebasestorage.app',
    iosBundleId: 'com.example.mafia',
  );
}
