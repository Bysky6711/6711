import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedNewBackground extends StatefulWidget {
  const AnimatedNewBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.08,
    this.rain = true,
    this.assetPath = 'assets/images/backgrounds/new_background.jpg',
    this.glowColors = const [Color(0xFF7A0E14), Color(0xFFD62330)],
  });

  final Widget child;
  final double darkOverlay;
  final bool rain;
  final String assetPath;

  /// Two colours driving the breathing radial glow (base = red; medieval =
  /// burgundy→gold).
  final List<Color> glowColors;

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
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _StaticMafiaBackground(assetPath: widget.assetPath),
          _StaticOverlay(darkOverlay: widget.darkOverlay),
          if (!reduceMotion)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final size = MediaQuery.sizeOf(context);
                final ratio = size.width / math.max(size.height, 1);
                final isWide = ratio > 1.16;
                final t = controller.value;
                final breath = .5 + .5 * math.sin(t * math.pi * 2);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            -math.sin(t * math.pi * 2) * .18,
                            .30 + math.cos(t * math.pi * 2) * .05,
                          ),
                          radius: isWide ? 1.0 : 1.25,
                          colors: [
                            widget.glowColors.first.withValues(alpha: .05 + breath * .03),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(
                            math.sin(t * math.pi * 2) * .12,
                            -.34 + math.cos(t * math.pi * 2) * .04,
                          ),
                          radius: isWide ? .72 : .92,
                          colors: [
                            widget.glowColors.last.withValues(alpha: .09 + breath * .05),
                            widget.glowColors.first.withValues(alpha: .06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    if (widget.rain)
                      IgnorePointer(
                        child: CustomPaint(
                          isComplex: false,
                          willChange: true,
                          painter: _AnimatedRainPainter(progress: t, wide: isWide),
                        ),
                      ),
                  ],
                );
              },
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _StaticMafiaBackground extends StatelessWidget {
  const _StaticMafiaBackground({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, _, _) => const _FallbackMafiaGradient(),
    );
  }
}

class _StaticOverlay extends StatelessWidget {
  const _StaticOverlay({required this.darkOverlay});

  final double darkOverlay;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: .18 + darkOverlay),
            Colors.black.withValues(alpha: .18 + darkOverlay),
            Colors.black.withValues(alpha: .56 + darkOverlay),
            Colors.black.withValues(alpha: .82 + darkOverlay),
          ],
          stops: const [0, .38, .78, 1],
        ),
      ),
    );
  }
}

class _AnimatedRainPainter extends CustomPainter {
  const _AnimatedRainPainter({required this.progress, required this.wide});

  final double progress;
  final bool wide;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    final count = wide ? 34 : 24;
    for (var i = 0; i < count; i++) {
      final x = (i * 53.0 + progress * 110.0) % size.width;
      final y = (i * 97.0 + progress * 300.0) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 7, y + 28), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedRainPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.wide != wide;
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
