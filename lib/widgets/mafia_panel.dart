import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';

class MafiaPanel extends StatelessWidget {
  const MafiaPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(small ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.frame, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.07),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }
}
