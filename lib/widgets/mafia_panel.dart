import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class MafiaPanel extends StatelessWidget {
  const MafiaPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(small ? 13 : 18),
      decoration: BoxDecoration(
        color: AppColors.darkPanel.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.frame.withValues(alpha: 0.88),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.72),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: AppColors.bloodGlow.withValues(alpha: 0.13),
            blurRadius: 24,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CrimsonPanelPainter()),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CrimsonPanelPainter extends CustomPainter {
  const _CrimsonPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cornerPaint = Paint()
      ..color = AppColors.bloodGlow.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = AppColors.bloodGlow.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    void drawCorner({required bool right, required bool bottom}) {
      final x = right ? size.width - 18 : 18.0;
      final y = bottom ? size.height - 18 : 18.0;

      final sx = right ? -1.0 : 1.0;
      final sy = bottom ? -1.0 : 1.0;

      final path = Path()
        ..moveTo(x, y + sy * 18)
        ..quadraticBezierTo(x + sx * 2, y + sy * 4, x + sx * 18, y)
        ..moveTo(x + sx * 6, y + sy * 18)
        ..quadraticBezierTo(x + sx * 14, y + sy * 12, x + sx * 18, y + sy * 6);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, cornerPaint);
    }

    drawCorner(right: false, bottom: false);
    drawCorner(right: true, bottom: false);
    drawCorner(right: false, bottom: true);
    drawCorner(right: true, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _CrimsonPanelPainter oldDelegate) {
    return false;
  }
}
