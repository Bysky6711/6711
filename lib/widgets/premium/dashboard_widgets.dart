import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import 'mafia_clock_text.dart';
import 'mafia_playing_card.dart';
import 'premium_motion.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, this.subtitle, this.showMoon = true});

  final String? subtitle;
  final bool showMoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
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
          const Expanded(child: MafiaClockText()),
          if (showMoon) ...[
            const SizedBox(width: 16),
            Icon(
              Icons.nightlight_outlined,
              color: AppColors.white,
              size: Responsive.isSmall(context) ? 54 : 64,
            ),
          ],
        ],
      ),
    );
  }
}

class DashboardTile extends StatelessWidget {
  const DashboardTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);
    final tileSize = small ? 64.0 : 72.0;

    return PressableScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: AppColors.white,
                  size: small ? 35 : 40,
                ),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: const BoxDecoration(
                      color: AppColors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge! > 9 ? '9+' : badge.toString(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: tileSize + 18,
            child: Text(
              label.toLowerCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                shadows: [
                  Shadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Responsive.isSmall(context) ? 16 : 18,
      runSpacing: Responsive.isSmall(context) ? 18 : 20,
      alignment: WrapAlignment.center,
      children: List.generate(children.length, (index) {
        return PremiumFadeSlide(
          delay: Duration(milliseconds: 40 * index),
          duration: const Duration(milliseconds: 260),
          offset: const Offset(0, 14),
          child: children[index],
        );
      }),
    );
  }
}

class DashboardPlayingCardTile extends StatelessWidget {
  const DashboardPlayingCardTile({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final MafiaPlayingCardColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = Responsive.isSmall(context) ? 148.0 : 164.0;

    return PressableScale(
      onTap: onTap,
      child: Column(
        children: [
          MafiaPlayingCard(width: width, color: color, compact: true),
          const SizedBox(height: 8),
          Text(
            label.toLowerCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
