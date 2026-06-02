import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class MafiaTextField extends StatelessWidget {
  const MafiaTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
    this.mutedText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextCapitalization textCapitalization;
  final bool mutedText;

  @override
  Widget build(BuildContext context) {
    final textColor = mutedText ? AppColors.mutedCream : AppColors.neonWhite;

    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: GoogleFonts.cinzel(
        color: textColor,
        fontSize: Responsive.isSmall(context) ? 16 : 18,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        hintText: hint,
        labelStyle: GoogleFonts.cinzel(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: [
            Shadow(
              color: AppColors.bloodGlow.withValues(alpha: 0.35),
              blurRadius: 5,
            ),
          ],
        ),
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.48)),
        filled: true,
        fillColor: AppColors.blackRed.withValues(alpha: 0.62),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.frame.withValues(alpha: 0.82),
            width: 1.4,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.frameBright, width: 2),
        ),
      ),
    );
  }
}
