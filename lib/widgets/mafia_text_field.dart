import 'package:flutter/material.dart';
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
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: AppColors.white,
        fontSize: Responsive.isSmall(context) ? 16 : 18,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        hintText: hint,
        labelStyle: TextStyle(
          color: AppColors.white.withValues(alpha: 0.78),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
        hintStyle: TextStyle(
          color: AppColors.white.withValues(alpha: 0.42),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: AppColors.glassDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.white, width: 1.4),
        ),
      ),
    );
  }
}
