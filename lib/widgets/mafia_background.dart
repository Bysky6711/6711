import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MafiaBackground extends StatelessWidget {
  const MafiaBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  static const String backgroundPath = 'assets/images/backgrounds/miasto.jpg';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundPath,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.96),
                  Colors.black.withValues(alpha: 0.78),
                  AppColors.deepRed.withValues(alpha: 0.78),
                  AppColors.deepRed.withValues(alpha: 0.92),
                ],
                stops: const [
                  0.00,
                  0.36,
                  0.72,
                  1.00,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}