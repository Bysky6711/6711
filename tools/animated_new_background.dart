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
      duration: const Duration(seconds: 36),
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
        final t = controller.value;
        final size = MediaQuery.sizeOf(context);
        final isWide = size.width / math.max(size.height, 1) > 1.15;
        final foregroundFit = isWide ? BoxFit.contain : BoxFit.cover;
        final foregroundWidth = isWide ? size.width * 0.82 : size.width * 1.06;
        final dx = math.sin(t * math.pi * 2) * (isWide ? 18.0 : 10.0);
        final dy = math.cos(t * math.pi * 2) * (isWide ? 8.0 : 6.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.10,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Image.asset(
                  AnimatedNewBackground.assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, _, _) => const _FallbackMafiaGradient(),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.15,
                    colors: [
                      Colors.black.withValues(alpha: .05),
                      Colors.black.withValues(alpha: .36 + widget.darkOverlay),
                      Colors.black.withValues(alpha: .72 + widget.darkOverlay),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: SizedBox(
                  width: foregroundWidth,
                  height: size.height * (isWide ? .96 : 1.06),
                  child: Image.asset(
                    AnimatedNewBackground.assetPath,
                    fit: foregroundFit,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: .12 + widget.darkOverlay),
                    Colors.black.withValues(alpha: .20 + widget.darkOverlay),
                    Colors.black.withValues(alpha: .68 + widget.darkOverlay),
                  ],
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

    for (var i = 0; i < 54; i++) {
      final x = (i * 43.0 + progress * 180.0) % size.width;
      final y = (i * 89.0 + progress * 460.0) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 10, y + 42), paint);
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
