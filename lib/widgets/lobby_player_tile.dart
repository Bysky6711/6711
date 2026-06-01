import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import 'mafia_hat_icon.dart';

class LobbyPlayerTile extends StatelessWidget {
  const LobbyPlayerTile({
    super.key,
    required this.name,
    required this.isHost,
  });

  final String name;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isSmall(context) ? 12 : 14,
        vertical: Responsive.isSmall(context) ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHost
              ? AppColors.neonWhite.withValues(alpha: 0.75)
              : AppColors.frame,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(
              child: isHost
                  ? const MafiaHatIcon(
                      size: 24,
                      color: AppColors.neonWhite,
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: AppColors.neonWhite,
                      size: 23,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: Responsive.isSmall(context) ? 15 : 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          if (isHost)
            Text(
              'HOST',
              style: GoogleFonts.cinzel(
                color: Colors.greenAccent,
                fontSize: Responsive.isSmall(context) ? 13 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}