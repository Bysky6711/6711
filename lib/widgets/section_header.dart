import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.showIcon = false,
  });

  final String title;
  final IconData icon;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showIcon) ...[
          Icon(icon, color: AppColors.neonWhite, size: 22),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              color: AppColors.neonWhite,
              fontSize: Responsive.isSmall(context) ? 18 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
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
      ],
    );
  }
}
