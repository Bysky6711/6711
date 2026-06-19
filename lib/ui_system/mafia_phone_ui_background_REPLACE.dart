// W lib/ui_system/mafia_phone_ui.dart:
// 1) dodaj import:
// import '../widgets/animated_new_background.dart';
// 2) podmień klasę MafiaPhoneBackground na tę poniżej:

class MafiaPhoneBackground extends StatelessWidget {
  const MafiaPhoneBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.08,
  });

  final Widget child;
  final double darkOverlay;

  @override
  Widget build(BuildContext context) {
    return AnimatedNewBackground(
      darkOverlay: darkOverlay,
      child: child,
    );
  }
}
