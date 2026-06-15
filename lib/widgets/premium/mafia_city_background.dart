import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class MafiaCityBackground extends StatelessWidget {
  const MafiaCityBackground({
    super.key,
    required this.child,
    this.blur = 0,
    this.darkOverlay = 0.18,
    this.parallaxOffset = Offset.zero,
  });

  final Widget child;
  final double blur;
  final double darkOverlay;
  final Offset parallaxOffset;

  @override
  Widget build(BuildContext context) {
    final background = RepaintBoundary(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.cityTopRed,
                    AppColors.cityMidRed,
                    AppColors.darkRed,
                    AppColors.cityBottomBlack,
                    AppColors.black,
                  ],
                  stops: [0.0, 0.28, 0.54, 0.78, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.12),
                  radius: 0.72,
                  colors: [
                    AppColors.cityGlowRed.withValues(alpha: 0.62),
                    AppColors.cityGlowRed.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(
                parallaxOffset.dx * 0.45,
                parallaxOffset.dy * 0.25,
              ),
              child: CustomPaint(painter: _CityPainter(layer: 0)),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(
                parallaxOffset.dx * 0.75,
                parallaxOffset.dy * 0.45,
              ),
              child: CustomPaint(painter: _CityPainter(layer: 1)),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: parallaxOffset,
              child: CustomPaint(painter: _CityPainter(layer: 2)),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: darkOverlay),
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: blur > 0
              ? ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: background,
                )
              : background,
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _CityPainter extends CustomPainter {
  const _CityPainter({required this.layer});

  final int layer;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = switch (layer) {
        0 => Colors.black.withValues(alpha: 0.22),
        1 => Colors.black.withValues(alpha: 0.42),
        _ => Colors.black.withValues(alpha: 0.88),
      }
      ..style = PaintingStyle.fill;

    final baseY = switch (layer) {
      0 => size.height * 0.70,
      1 => size.height * 0.75,
      _ => size.height * 0.80,
    };

    final random = math.Random(100 + layer);
    double x = -24;

    while (x < size.width + 40) {
      final w = 18 + random.nextDouble() * 42;
      final h = size.height * (0.12 + random.nextDouble() * 0.28);
      final rect = Rect.fromLTWH(x, baseY - h, w, h);
      canvas.drawRect(rect, paint);

      if (random.nextBool()) {
        final spirePaint = Paint()
          ..color = paint.color
          ..strokeWidth = 2 + layer.toDouble()
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(x + w * 0.68, baseY - h),
          Offset(x + w * 0.68, baseY - h - 28 - random.nextDouble() * 45),
          spirePaint,
        );
      }

      x += w + 4 + random.nextDouble() * 10;
    }

    final bottomPaint = Paint()
      ..color = layer == 2
          ? AppColors.black
          : Colors.black.withValues(alpha: 0.18 + layer * 0.18);
    canvas.drawRect(
      Rect.fromLTWH(0, baseY, size.width, size.height - baseY),
      bottomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CityPainter oldDelegate) {
    return oldDelegate.layer != layer;
  }
}
