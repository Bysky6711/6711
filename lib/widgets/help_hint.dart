import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/responsive.dart';

class HelpHint extends StatelessWidget {
  const HelpHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.help_outline_rounded,
          color: Colors.white.withValues(alpha: 0.55),
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white60,
              fontSize: Responsive.isSmall(context) ? 17 : 19,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
