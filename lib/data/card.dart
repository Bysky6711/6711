import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../ui_system/mafia_ios_system.dart';
import '../widgets/shared_widgets.dart';
import 'roles.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key, required this.roleType, this.imagePath});
  final MafiaRoleCardType roleType;
  final String? imagePath;
  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> with TickerProviderStateMixin {
  late final AnimationController flipController;
  late final AnimationController burnController;
  late final Animation<double> burnSweep;
  bool revealed = false;
  bool burning = false;

  @override
  void initState() {
    super.initState();
    flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    burnController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    burnSweep = Tween<double>(begin: -0.35, end: 1.35).animate(CurvedAnimation(parent: burnController, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    flipController.dispose();
    burnController.dispose();
    super.dispose();
  }

  String get roleName => GameRoles.nameOf(widget.roleType);
  MafiaPlayingCardColor get cardColor => widget.roleType == MafiaRoleCardType.mafia ? MafiaPlayingCardColor.red : MafiaPlayingCardColor.blue;
  String get assetPath => widget.imagePath ?? (cardColor == MafiaPlayingCardColor.red ? MafiaAssets.redCard : MafiaAssets.blueCard);

  Future<void> revealAndBurn() async {
    if (revealed) return;
    setState(() => revealed = true);
    await flipController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => burning = true);
    await burnController.forward();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MafiaIOSScaffold(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 14, Responsive.horizontalPadding(context), 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Align(alignment: Alignment.centerLeft, child: IOSBackButton(onTap: () => Navigator.pop(context))),
                LockClock(subtitle: burning ? 'Karta spala się...' : revealed ? roleName : 'Dotknij kartę'),
                const SizedBox(height: 34),
                PressableScale(
                  onTap: revealAndBurn,
                  haptic: HapticFeedbackType.medium,
                  pressedScale: .98,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([flipController, burnController]),
                    builder: (context, _) {
                      final flip = Curves.easeOutCubic.transform(flipController.value);
                      final angle = flip * math.pi;
                      final front = angle > math.pi / 2;
                      final burn = Curves.easeInOutCubic.transform(burnController.value);
                      return Opacity(
                        opacity: (1 - burn * .92).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, -burn * 38),
                          child: Transform.scale(
                            scale: 1 - burn * .08,
                            child: Stack(alignment: Alignment.center, children: [
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..setEntry(3, 2, .0014)..rotateY(angle),
                                child: front
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()..rotateY(math.pi),
                                        child: _BurningCardFace(assetPath: assetPath, color: cardColor, roleName: roleName, burn: burn, sweep: burnSweep.value),
                                      )
                                    : _CardBack(assetPath: MafiaAssets.redCard, burn: burn, sweep: burnSweep.value),
                              ),
                              if (burning) ...List.generate(42, (i) => _FireParticle(progress: burn, index: i)),
                              if (burning) CustomPaint(size: const Size(330, 470), painter: _EmberPainter(progress: burn)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(revealed ? '' : 'Karta pokaże się tylko raz', style: TextStyle(color: AppColors.white.withValues(alpha: .62), fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.assetPath, required this.burn, required this.sweep});
  final String assetPath;
  final double burn;
  final double sweep;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BurnClipper(progress: burn),
      child: ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => _burnShader(bounds, sweep),
        child: ClipRRect(borderRadius: BorderRadius.circular(22), child: SizedBox(width: 280, height: 414, child: CardAsset(assetPath: assetPath, fallbackColor: MafiaPlayingCardColor.red))),
      ),
    );
  }
}

class _BurningCardFace extends StatelessWidget {
  const _BurningCardFace({required this.assetPath, required this.color, required this.roleName, required this.burn, required this.sweep});
  final String assetPath;
  final MafiaPlayingCardColor color;
  final String roleName;
  final double burn;
  final double sweep;
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BurnClipper(progress: burn),
      child: Stack(alignment: Alignment.center, children: [
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => _burnShader(bounds, sweep),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 280,
              height: 414,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: burn * .48), BlendMode.darken),
                child: CardAsset(assetPath: assetPath, fallbackColor: color),
              ),
            ),
          ),
        ),
        Positioned(bottom: 34, child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: AppColors.glassDark, borderRadius: BorderRadius.circular(14)), child: Text(roleName.toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)))),
        if (burn > 0) Positioned.fill(child: CustomPaint(painter: _BurnEdgePainter(progress: burn))),
      ]),
    );
  }
}

Shader _burnShader(Rect bounds, double value) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [
      (value - .24).clamp(0.0, 1.0),
      (value - .10).clamp(0.0, 1.0),
      value.clamp(0.0, 1.0),
      (value + .07).clamp(0.0, 1.0),
    ],
    colors: [
      Colors.black.withValues(alpha: .88),
      Colors.red.withValues(alpha: .85),
      Colors.orangeAccent,
      Colors.white,
    ],
  ).createShader(bounds);
}

class _BurnClipper extends CustomClipper<Path> {
  _BurnClipper({required this.progress});
  final double progress;
  @override
  Path getClip(Size size) {
    final p = progress.clamp(0.0, 1.0);
    final burnY = size.height * (1 - p * .96);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, burnY);
    for (var i = 0; i <= 22; i++) {
      final x = size.width - (i / 22) * size.width;
      final wave = math.sin(i * 1.6 + p * 12) * 12 + math.sin(i * .77) * 6;
      path.lineTo(x, burnY + wave);
    }
    path
      ..lineTo(0, 0)
      ..close();
    return path;
  }
  @override
  bool shouldReclip(covariant _BurnClipper oldClipper) => oldClipper.progress != progress;
}

class _BurnEdgePainter extends CustomPainter {
  _BurnEdgePainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final burnY = size.height * (1 - progress * .96);
    final path = Path()..moveTo(0, burnY);
    for (var i = 0; i <= 28; i++) {
      final x = i / 28 * size.width;
      final y = burnY + math.sin(i * 1.4 + progress * 12) * 11;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.deepOrange.withValues(alpha: .1), Colors.deepOrange.withValues(alpha: .95), Colors.yellowAccent.withValues(alpha: .70)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, burnY - 30, size.width, 60))
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(covariant _BurnEdgePainter oldDelegate) => oldDelegate.progress != progress;
}

class _FireParticle extends StatelessWidget {
  const _FireParticle({required this.progress, required this.index});
  final double progress;
  final int index;
  @override
  Widget build(BuildContext context) {
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final dx = math.sin(index * 7.1) * 118 * progress;
    final dy = -progress * (90 + (index % 7) * 28);
    final size = 3.0 + (index % 6) * 2;
    return Transform.translate(
      offset: Offset(dx, dy + 120 * (1 - progress)),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index.isEven ? Colors.deepOrangeAccent : Colors.amberAccent,
            boxShadow: [BoxShadow(color: Colors.deepOrange.withValues(alpha: .8), blurRadius: 14)],
          ),
        ),
      ),
    );
  }
}

class _EmberPainter extends CustomPainter {
  _EmberPainter({required this.progress});
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orangeAccent.withValues(alpha: (1 - progress) * .55);
    for (var i = 0; i < 34; i++) {
      final x = size.width / 2 + math.sin(i * 2.3) * 150 * progress;
      final y = size.height * .65 - progress * (65 + i * 7);
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 4), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) => oldDelegate.progress != progress;
}
