import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class NeonMafiaTitle extends StatelessWidget {
  const NeonMafiaTitle({super.key, this.fontSize = 92});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final width = Responsive.width(context);
    final letterSpacing = Responsive.clamp(width * 0.014, 3, 7);

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'MAFIA',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BernierShade',
            fontSize: fontSize,
            color: AppColors.neonWhite,
            letterSpacing: letterSpacing,
            shadows: const [
              Shadow(color: Colors.white, blurRadius: 3),
              Shadow(color: AppColors.neonWhite, blurRadius: 8),
              Shadow(color: Colors.black, blurRadius: 12, offset: Offset(4, 4)),
            ],
          ),
        ),
      ),
    );
  }
}
