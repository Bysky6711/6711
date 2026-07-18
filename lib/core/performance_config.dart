import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PerformanceConfig {
  const PerformanceConfig._();

  static Future<void> apply() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Większy cache obrazów = mniej doczytywania assetów podczas animacji.
    PaintingBinding.instance.imageCache.maximumSize = 240;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 160 << 20;

    // Pełny ekran: ukrywa paski systemowe (mamy własny pasek statusu w UI).
    // Na iOS/Android chowa status/nav bar; na web to no-op (fullscreen w web
    // ustawiamy przez manifest display:fullscreen + żądanie przy 1. dotknięciu).
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}
