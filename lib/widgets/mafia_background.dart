import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class MafiaBackground extends StatelessWidget {
  const MafiaBackground({super.key, required this.child});

  final Widget child;

  static const String backgroundPath = 'assets/images/backgrounds/new_background.jpg';

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
                  Colors.black.withValues(alpha: 0.98),
                  AppColors.deepBlack.withValues(alpha: 0.94),
                  AppColors.deepRed.withValues(alpha: 0.82),
                  AppColors.bloodRedDark.withValues(alpha: 0.66),
                ],
                stops: const [0.00, 0.38, 0.74, 1.00],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.15,
                colors: [
                  AppColors.bloodRed.withValues(alpha: 0.20),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.42),
                ],
                stops: const [0.00, 0.48, 1.00],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
