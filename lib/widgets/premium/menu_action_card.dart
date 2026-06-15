import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import 'premium_motion.dart';

class MenuActionCard extends StatelessWidget {
  const MenuActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      child: Container(
        width: Responsive.buttonWidth(context),
        height: small ? 72 : 78,
        padding: EdgeInsets.symmetric(
          horizontal: small ? 14 : 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.glassWhite,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: small ? 42 : 48,
              height: small ? 42 : 48,
              decoration: BoxDecoration(
                color: AppColors.cardRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.white, size: small ? 23 : 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: small ? 16 : 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.black.withValues(alpha: 0.72),
                      fontSize: small ? 13 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
