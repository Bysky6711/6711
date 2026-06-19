import 'package:flutter/material.dart';

import 'animated_new_background.dart';

class MafiaBackground extends StatelessWidget {
  const MafiaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedNewBackground(child: child);
  }
}
