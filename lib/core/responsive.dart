import 'dart:math' as math;
import 'package:flutter/material.dart';

class Responsive {
  const Responsive._();

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isSmall(BuildContext context) => width(context) < 390;

  static bool isTiny(BuildContext context) => width(context) < 340;

  static double clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }

  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w < 340) return 14;
    if (w < 390) return 18;
    return 22;
  }

  static double contentMaxWidth(BuildContext context) {
    final w = width(context);
    if (w >= 900) return 520;
    if (w >= 600) return 500;
    return double.infinity;
  }

  static double clockSize(BuildContext context) {
    final w = width(context);
    return clamp(w * 0.235, 78, 100);
  }

  static double titleSize(BuildContext context) {
    final w = width(context);
    return clamp(w * 0.105, 34, 46);
  }

  static double buttonWidth(BuildContext context) {
    return math.min(width(context) - horizontalPadding(context) * 2, 390);
  }
}
