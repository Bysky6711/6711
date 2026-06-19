import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedNewBackground extends StatefulWidget {
  const AnimatedNewBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.08,
    this.rain = true,
  });

  static const String assetPath = 'assets/images/backgrounds/new_background.jpg';

  final Widget child;
  final double darkOverlay;
  final bool rain;

  @override
  State<AnimatedNewBackground> createState() => _AnimatedNewBackgroundState();
}

class _AnimatedNewBackgroundState extends State<AnimatedNewBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);
        final t = controller.value;
        final ratio = size.width / math.max(size.height, 1);
        final isWide = ratio > 1.15;

        // Główna poprawka: obraz NIE jest już rozciągany na cały ekran.
        // Dajemy rozmyte wypełnienie jako tło, a właściwy obraz jako mniejszą,
        // dolną warstwę sceny — dzięki temu księżyc/miasto nie są gigantyczne.
        final sceneWidth = isWide ? size.width * 0.58 : size.width * 1.04;
        final sceneHeight = isWide ? size.height * 0.82 : size.height * 1.02;
        final sceneDx = math.sin(t * math.pi * 2) * (isWide ? 18.0 : 8.0);
        final sceneDy = math.cos(t * math.pi * 2) * (isWide ? 7.0 : 5.0);
        final blurDx = math.sin(t * math.pi * 2 + .8) * 12.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Miękka, przyciemniona warstwa wypełniająca ekran.
            Transform.translate(
              offset: Offset(blurDx, 0),
              child: Transform.scale(
                scale: 1.18,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Image.asset(
                    AnimatedNewBackground.assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const _FallbackMafiaGradient(),
                  ),
                ),
              ),
            ),

            // Ciemna mgła, żeby rozmyte tło nie dominowało UI.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.05,
                  colors: [
                    Colors.black.withValues(alpha: .18 + widget.darkOverlay),
                    Colors.black.withValues(alpha: .44 + widget.darkOverlay),
                    Colors.black.withValues(alpha: .76 + widget.darkOverlay),
                  ],
                ),
              ),
            ),

            // Właściwa scena — mniejsza, dolna, jak tapeta telefonu.
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(sceneDx, sceneDy),
                child: SizedBox(
                  width: sceneWidth,
                  height: sceneHeight,
                  child: Image.asset(
                    AnimatedNewBackground.assetPath,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Delikatne czerwone światło jak w poprzednim klimacie.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.28),
                  radius: isWide ? .68 : .85,
                  colors: [
                    const Color(0xFFD62330).withValues(alpha: .10),
                    const Color(0xFF3A0505).withValues(alpha: .08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Vignette + dół mocniej wygaszony, żeby przyciski i ikonki były czytelne.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .10 + widget.darkOverlay),
                    Colors.black.withValues(alpha: .18 + widget.darkOverlay),
                    Colors.black.withValues(alpha: .58 + widget.darkOverlay),
                    Colors.black.withValues(alpha: .84 + widget.darkOverlay),
                  ],
                  stops: const [0, .38, .76, 1],
                ),
              ),
            ),

            if (widget.rain)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _AnimatedRainPainter(progress: t)),
                ),
              ),

            widget.child,
          ],
        );
      },
    );
  }
}

class _AnimatedRainPainter extends CustomPainter {
  const _AnimatedRainPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .07)
      ..strokeWidth = 1;

    for (var i = 0; i < 58; i++) {
      final x = (i * 41.0 + progress * 165.0) % size.width;
      final y = (i * 87.0 + progress * 430.0) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 9, y + 38), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedRainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FallbackMafiaGradient extends StatelessWidget {
  const _FallbackMafiaGradient();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.15,
          colors: [Color(0xFF4A1010), Color(0xFF160404), Colors.black],
        ),
      ),
    );
  }
}
