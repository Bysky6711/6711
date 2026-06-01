import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MafiaHatIcon extends StatelessWidget {
  const MafiaHatIcon({
    super.key,
    this.size = 24,
    this.color = AppColors.neonWhite,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0.5, 0),
      child: CustomPaint(
        size: Size(size, size),
        painter: MafiaHatPainter(color: color),
      ),
    );
  }
}

class MafiaHatPainter extends CustomPainter {
  const MafiaHatPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final brim = Path()
      ..moveTo(w * 0.16, h * 0.64)
      ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.84, h * 0.64);

    canvas.drawPath(brim, strokePaint);

    final crown = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        w * 0.30,
        h * 0.28,
        w * 0.40,
        h * 0.34,
      ),
      Radius.circular(w * 0.08),
    );

    canvas.drawRRect(crown, strokePaint);

    final topLine = Path()
      ..moveTo(w * 0.34, h * 0.28)
      ..quadraticBezierTo(w * 0.50, h * 0.18, w * 0.66, h * 0.28);

    canvas.drawPath(topLine, strokePaint);

    final band = Path()
      ..moveTo(w * 0.32, h * 0.49)
      ..lineTo(w * 0.68, h * 0.49);

    canvas.drawPath(band, strokePaint);
  }

  @override
  bool shouldRepaint(covariant MafiaHatPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}