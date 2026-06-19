// W lib/ui_system/mafia_ios_system.dart:
// 1) dodaj import:
// import '../widgets/animated_new_background.dart';
// 2) usuń klasy: _NewMafiaRainOverlay, _NewMafiaRainOverlayState, _NewMafiaRainPainter
// 3) podmień klasę MafiaIOSBackground na tę poniżej:

class MafiaIOSBackground extends StatelessWidget {
  const MafiaIOSBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.04,
    this.rain = true,
    this.lightning = true,
  });

  final Widget child;
  final double darkOverlay;
  final bool rain;
  final bool lightning;

  @override
  Widget build(BuildContext context) {
    return AnimatedNewBackground(
      darkOverlay: darkOverlay,
      rain: rain,
      child: child,
    );
  }
}
