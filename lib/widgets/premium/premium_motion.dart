import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumFadeSlide extends StatefulWidget {
  const PremiumFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.offset = const Offset(0, 16),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<PremiumFadeSlide> createState() => _PremiumFadeSlideState();
}

class _PremiumFadeSlideState extends State<PremiumFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> opacity;
  late final Animation<Offset> slide;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: widget.duration);

    opacity = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    slide = Tween<Offset>(
      begin: Offset(widget.offset.dx / 100, widget.offset.dy / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));

    Future<void>.delayed(widget.delay, () {
      if (mounted) controller.forward();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.haptic = HapticFeedbackType.light,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback onTap;
  final HapticFeedbackType haptic;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool pressed = false;

  Future<void> triggerHaptic() async {
    switch (widget.haptic) {
      case HapticFeedbackType.light:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.selection:
        await HapticFeedback.selectionClick();
        break;
    }
  }

  void setPressed(bool value) {
    if (pressed == value) return;
    setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setPressed(true),
      onTapCancel: () => setPressed(false),
      onTapUp: (_) {
        setPressed(false);
        triggerHaptic();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: pressed ? 0.88 : 1,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

enum HapticFeedbackType { light, medium, selection }
