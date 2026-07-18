import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

enum MafiaPlayingCardColor { red, blue }

class MafiaPlayingCard extends StatelessWidget {
  const MafiaPlayingCard({
    super.key,
    this.width = 280,
    this.color = MafiaPlayingCardColor.red,
    this.compact = false,
    this.title = 'MAFIA',
  });

  final double width;
  final MafiaPlayingCardColor color;
  final bool compact;
  final String title;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.48;
    final isRed = color == MafiaPlayingCardColor.red;

    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isRed ? AppColors.cardRed : AppColors.cardBlue,
          borderRadius: BorderRadius.circular(compact ? 10 : 18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: compact ? 16 : 26,
              offset: Offset(0, compact ? 8 : 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 10 : 18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      isRed ? AppColors.cardRed : AppColors.cardBlue,
                      isRed ? AppColors.cardRedDeep : AppColors.cardBlueDeep,
                    ],
                  ),
                ),
              ),
              CustomPaint(painter: _MafiaCardPatternPainter(isRed: isRed)),
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.black.withValues(alpha: 0.88),
                    fontSize: compact ? width * 0.26 : width * 0.20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: compact ? -1.2 : 2,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.14),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MafiaCardPatternPainter extends CustomPainter {
  const _MafiaCardPatternPainter({required this.isRed});

  final bool isRed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double r = size.width * 0.18; r < size.width * 0.95; r += 18) {
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), r, paint);
    }

    final mPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.32,
        size.width * 0.50,
        size.height * 0.55,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.32,
        size.width * 0.72,
        size.height * 0.55,
      )
      ..lineTo(size.width * 0.72, size.height * 0.67)
      ..quadraticBezierTo(
        size.width * 0.60,
        size.height * 0.52,
        size.width * 0.50,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.52,
        size.width * 0.28,
        size.height * 0.67,
      )
      ..close();

    canvas.drawPath(path, mPaint);
  }

  @override
  bool shouldRepaint(covariant _MafiaCardPatternPainter oldDelegate) {
    return oldDelegate.isRed != isRed;
  }
}
