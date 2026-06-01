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
    final textColor = mutedText ? AppColors.fieldGrey : Colors.white;

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
          shadows: mutedText
              ? null
              : const [Shadow(color: Colors.white, blurRadius: 4)],
        ),
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.55)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.35),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.frame, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.neonWhite, width: 2),
        ),
      ),
    );
  }
}
