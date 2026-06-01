import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class CounterSetting extends StatelessWidget {
  const CounterSetting({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);
    final safeValue = value.clamp(min, max);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: small ? 48 : 54,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                fontSize: small ? 15 : 18,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CounterIconButton(
            icon: Icons.remove_circle_outline,
            enabled: safeValue > min,
            onPressed: () => onChanged(safeValue - 1),
          ),
          SizedBox(
            width: 34,
            child: Text(
              safeValue.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: small ? 20 : 24,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 4,
                  ),
                  Shadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          _CounterIconButton(
            icon: Icons.add_circle_outline,
            enabled: safeValue < max,
            onPressed: () => onChanged(safeValue + 1),
          ),
        ],
      ),
    );
  }
}

class _CounterIconButton extends StatelessWidget {
  const _CounterIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return SizedBox(
      width: small ? 38 : 42,
      height: small ? 38 : 42,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        iconSize: small ? 30 : 34,
        color: AppColors.neonWhite,
        disabledColor: AppColors.neonWhite.withValues(alpha: 0.28),
      ),
    );
  }
}