import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/responsive.dart';

class MafiaClockText extends StatelessWidget {
  const MafiaClockText({
    super.key,
    this.time,
    this.fontSize,
    this.align = TextAlign.center,
  });

  final String? time;
  final double? fontSize;
  final TextAlign align;

  String _formattedNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      time ?? _formattedNow(),
      textAlign: align,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontFamily: 'BernierShade',
        fontSize: fontSize ?? Responsive.clockSize(context),
        height: 0.92,
        color: AppColors.white,
        letterSpacing: 2,
        shadows: const [
          Shadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(4, 5)),
        ],
      ),
    );
  }
}
