import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import 'premium_motion.dart';

class CodeDotsIndicator extends StatelessWidget {
  const CodeDotsIndicator({
    super.key,
    required this.length,
    required this.filled,
  });

  final int length;
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filled;

        return AnimatedScale(
          scale: isFilled ? 1.18 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isFilled ? AppColors.white : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 1.4),
            ),
          ),
        );
      }),
    );
  }
}

class CodeDigitButton extends StatelessWidget {
  const CodeDigitButton({super.key, required this.value, required this.onTap});

  final String value;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final size = Responsive.isSmall(context) ? 70.0 : 78.0;

    return PressableScale(
      onTap: () => onTap(value),
      haptic: HapticFeedbackType.selection,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          value,
          style: TextStyle(
            color: AppColors.white,
            fontSize: Responsive.isSmall(context) ? 34 : 38,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
