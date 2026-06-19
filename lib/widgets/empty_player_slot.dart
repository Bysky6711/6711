import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class EmptyPlayerSlot extends StatelessWidget {
  const EmptyPlayerSlot({super.key, required this.slotNumber});

  final int slotNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isSmall(context) ? 12 : 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(
              child: Icon(
                Icons.person_add_alt_outlined,
                color: Colors.white.withValues(alpha: 0.45),
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Wolne miejsce $slotNumber',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white54,
              fontSize: Responsive.isSmall(context) ? 16 : 18,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
