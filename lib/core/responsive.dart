import 'dart:math' as math;

import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isSmall(BuildContext context) => width(context) < 390;

  static double clamp(double value, double min, double max) =>
      value.clamp(min, max).toDouble();

  static double horizontalPadding(BuildContext context) {
    final w = width(context);

    if (w < 360) return 12;
    if (w < 600) return 18;
    return 24;
  }

  static double contentMaxWidth(BuildContext context) {
    final w = width(context);

    if (w >= 900) return 520;
    if (w >= 600) return 500;
    return double.infinity;
  }

  static double mainTitleSize(BuildContext context) {
    final w = width(context);
    return clamp(w * 0.23, 62, 112);
  }

  static double buttonWidth(BuildContext context) {
    final w = width(context);
    return math.min(w - (horizontalPadding(context) * 2), 380);
  }
}
