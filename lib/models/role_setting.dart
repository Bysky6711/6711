import 'package:flutter/material.dart';

class RoleSetting {
  const RoleSetting({
    required this.name,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String name;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
}
