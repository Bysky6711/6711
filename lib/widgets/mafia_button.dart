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
      height: small ? 50 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.blackRed.withValues(alpha: 0.88),
              foregroundColor: AppColors.neonWhite,
              elevation: 0,
              shadowColor: Colors.transparent,
              side: BorderSide(
                color: AppColors.frameBright.withValues(alpha: 0.88),
                width: 1.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.bloodGlow.withValues(alpha: 0.18);
                }

                if (states.contains(WidgetState.hovered)) {
                  return AppColors.bloodGlow.withValues(alpha: 0.10);
                }

                return null;
              }),
            ),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.bloodGlow.withValues(alpha: 0.12),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AppColors.neonWhite,
                  size: small ? 19 : 21,
                  shadows: [
                    Shadow(
                      color: AppColors.bloodGlow.withValues(alpha: 0.80),
                      blurRadius: 8,
                    ),
                  ],
                ),
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
                      fontSize: small ? 17 : 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AppColors.neonWhite,
                      shadows: [
                        Shadow(
                          color: AppColors.bloodGlow.withValues(alpha: 0.75),
                          blurRadius: 7,
                        ),
                        const Shadow(
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
      ),
    );
  }
}
