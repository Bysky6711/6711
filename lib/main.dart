import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/app_scroll_behavior.dart';
import 'core/performance_config.dart';
import 'firebase_options.dart';
import 'screens/main_menu_screen.dart';
import 'services/online_room_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PerformanceConfig.apply();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Sign in anonymously so the (hardened) Firestore rules can require an
  // authenticated user. Non-fatal if it fails — but the tightened rules then
  // reject writes, so make sure "Anonymous" sign-in is enabled in the Firebase
  // console (Authentication → Sign-in method).
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Anonimowe logowanie nie powiodło się: $e');
  }
  // Auto-detect long-polling: fast streaming transport on normal networks,
  // automatic fallback to long-polling behind proxies/firewalls that break it.
  // Must be set before any Firestore use.
  if (kIsWeb) {
    // Configure the SAME named "default" database instance the app uses.
    mafiaFirestore().settings = const Settings(
      webExperimentalAutoDetectLongPolling: true,
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mafia',
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5404F),
          brightness: Brightness.dark,
        ).copyWith(surface: const Color(0xFF241619)),
        splashColor: const Color(0x33E5404F),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF33221F),
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
