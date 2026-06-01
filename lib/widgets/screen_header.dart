import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.onBack,
    this.showTitle = true,
    this.showIcon = true,
    this.largeIcon = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onBack;
  final bool showTitle;
  final bool showIcon;
  final bool largeIcon;

  @override
  Widget build(BuildContext context) {
    final iconSize = largeIcon ? 34.0 : 23.0;

    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonWhite,
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (showIcon) Icon(icon, color: AppColors.neonWhite, size: iconSize),
        if (showIcon && showTitle) const SizedBox(width: 10),
        if (showTitle)
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                color: AppColors.neonWhite,
                fontSize: Responsive.isSmall(context) ? 24 : 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: const [
                  Shadow(color: Colors.white, blurRadius: 6),
                  Shadow(
                    color: Colors.black,
                    blurRadius: 12,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
