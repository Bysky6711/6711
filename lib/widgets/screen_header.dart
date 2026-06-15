import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import 'premium/premium_motion.dart';

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
    final iconSize = largeIcon ? 34.0 : 24.0;

    return Row(
      children: [
        PressableScale(
          onTap: onBack,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (showIcon) Icon(icon, color: AppColors.white, size: iconSize),
        if (showIcon && showTitle) const SizedBox(width: 10),
        if (showTitle)
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white,
                fontSize: Responsive.isSmall(context) ? 22 : 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                shadows: const [
                  Shadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          )
        else
          const Spacer(),
      ],
    );
  }
}
