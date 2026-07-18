import 'package:flutter/material.dart';

class RoleSummary {
  const RoleSummary({required this.name, required this.value, this.valueColor});

  final String name;
  final String value;
  final Color? valueColor;
}
