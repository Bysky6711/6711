import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class MafiaButton extends StatelessWidget {
  const MafiaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return SizedBox(
      width: math.min(
        Responsive.width(context) - (Responsive.horizontalPadding(context) * 2),
        380,
      ),
      height: small ? 52 : 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.58),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: const BorderSide(color: AppColors.frame, width: 1.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.neonWhite, size: small ? 20 : 22),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text.toUpperCase(),
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: small ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.white, blurRadius: 5),
                      Shadow(
                        color: Colors.black,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
