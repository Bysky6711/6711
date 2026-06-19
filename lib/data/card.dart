import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with TickerProviderStateMixin {
  late final AnimationController burnController;
  late final AnimationController particleController;
  late final AnimationController floatController;

  bool burning = false;
  bool done = false;

  @override
  void initState() {
    super.initState();
    burnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..repeat();
    floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    burnController.dispose();
    particleController.dispose();
    floatController.dispose();
    super.dispose();
  }

  String get roleName => GameRoles.nameOf(widget.roleType);

  String get assetPath {
    if (widget.imagePath != null) return widget.imagePath!;
    switch (widget.roleType) {
      case MafiaRoleCardType.host:
      case MafiaRoleCardType.mafia:
        return MafiaAssets.mafiaClassCard;
      case MafiaRoleCardType.detective:
        return 'assets/images/card/card_class_detektyw.jpg';
      case MafiaRoleCardType.sheriff:
        return 'assets/images/card/card_class_szeryf.jpg';
      case MafiaRoleCardType.citizen:
        return 'assets/images/card/card_class_obywatel.jpg';
      case MafiaRoleCardType.doctor:
        return 'assets/images/card/2.jpg';
    }
  }

  Future<void> burnAndClose() async {
    if (burning || done) return;
    HapticFeedback.mediumImpact();
    setState(() => burning = true);
    await burnController.forward();
    if (!mounted) return;
    setState(() => done = true);
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return MafiaIOSScaffold(
      darkOverlay: .10,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              12,
              Responsive.horizontalPadding(context),
              24,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IOSBackButton(onTap: () => Navigator.pop(context, false)),
                ),
                const SizedBox(height: 8),
                LockClock(
                  subtitle: burning ? 'Karta spala się…' : 'Dotknij kartę, aby ją spalić',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: burnAndClose,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          burnController,
                          particleController,
                          floatController,
                        ]),
                        builder: (context, _) {
                          final burn = burnController.value;
                          final floatY = math.sin(floatController.value * math.pi * 2) * 8;
                          final shake = burn > .82 && burn < 1
                              ? math.sin(particleController.value * math.pi * 900) * 2.2
                              : 0.0;
                          final fade = done ? 0.0 : 1.0;

                          return SizedBox(
                            width: 600,
                            height: 700,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _BurnParticlePainter(
                                        progress: burn,
                                        time: particleController.value,
                                        active: burning || done,
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(shake, floatY - burn * 10),
                                  child: Transform.scale(
                                    scale: 1 - burn * .08,
                                    child: Opacity(
                                      opacity: fade,
                                      child: _BurningRoleCard(
                                        assetPath: assetPath,
                                        roleName: roleName,
                                        progress: burn,
                                      ),
                                    ),
                                  ),
                                ),
                                if (done) const _FlashMark(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: burning ? 0 : 1,
                  child: Text(
                    'Karta jest już odsłonięta — stuknij, aby spalić',
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: .48),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BurningRoleCard extends StatelessWidget {
  const _BurningRoleCard({
    required this.assetPath,
    required this.roleName,
    required this.progress,
  });

  final String assetPath;
  final String roleName;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    return SizedBox(
      width: 240,
      height: 330,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B1C18), Color(0xFF1C1310)],
                ),
              ),
            ),
          ),
          ClipPath(
            clipper: _JaggedBurnClipper(progress: progress),
            child: ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: .82),
                  const Color(0xFFFF7A3C).withValues(alpha: .20),
                  Colors.transparent,
                ],
                stops: [
                  (progress - .08).clamp(0.0, 1.0).toDouble(),
                  progress.clamp(0.0, 1.0).toDouble(),
                  (progress + .20).clamp(0.0, 1.0).toDouble(),
                ],
              ).createShader(rect),
              child: ClipRRect(
                borderRadius: radius,
                child: Image.asset(
                  assetPath,
                  width: 240,
                  height: 330,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF241010),
                    alignment: Alignment.center,
                    child: Text(
                      roleName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              size: const Size(240, 330),
              painter: _BurnEdgePainter(progress: progress),
            ),
          ),
        ],
      ),
    );
  }
}

class _JaggedBurnClipper extends CustomClipper<Path> {
  const _JaggedBurnClipper({required this.progress});

  final double progress;

  double _ease(double t) {
    if (t < .15) return (t / .15) * .10;
    return (.10 + math.pow((t - .15) / .85, 1.8) * .90).toDouble();
  }

  @override
  Path getClip(Size size) {
    final eased = _ease(progress.clamp(0.0, 1.0).toDouble());
    final baseY = size.height * (1 - eased * 1.25);
    final amp = 12 + progress * 18;
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseY);

    const points = 20;
    for (var i = 0; i <= points; i++) {
      final x = size.width * i / points;
      final wave = math.sin(i * 1.5 + progress * 20) * amp +
          math.sin(i * 3.5 - progress * 12) * amp * .45 +
          math.sin(i * 8.2 + progress * 24) * amp * .22;
      path.lineTo(x, baseY + wave);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _JaggedBurnClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

class _BurnEdgePainter extends CustomPainter {
  const _BurnEdgePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final eased = Curves.easeInCubic.transform(progress.clamp(0.0, 1.0).toDouble());
    final y = size.height * (1 - eased * 1.14);
    final rect = Rect.fromLTWH(-34, y - 34, size.width + 68, 82);
    final glow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color(0xFFFFD166),
          Color(0xFFFF7A3C),
          Color(0xFFD62330),
          Colors.transparent,
        ],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..blendMode = BlendMode.screen;
    canvas.drawRect(
      rect,
      glow..color = glow.color.withValues(alpha: (progress * 3).clamp(0.0, 1.0).toDouble()),
    );
  }

  @override
  bool shouldRepaint(covariant _BurnEdgePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BurnParticlePainter extends CustomPainter {
  const _BurnParticlePainter({
    required this.progress,
    required this.time,
    required this.active,
  });

  final double progress;
  final double time;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active || progress <= 0) return;
    final rnd = math.Random(12);
    final centerX = size.width / 2;
    final cardTop = (size.height - 330) / 2;
    final cardW = 240.0;
    final cardH = 330.0;
    final burnY = cardTop + cardH *
        (1 - Curves.easeInCubic.transform(progress).clamp(0.0, 1.15).toDouble());

    for (var i = 0; i < 95; i++) {
      final seed = rnd.nextDouble();
      final localT = (time * (1.2 + seed) + seed) % 1.0;
      final x = centerX - cardW / 2 + rnd.nextDouble() * cardW +
          math.sin(localT * 8 + i) * 26;
      final y = burnY - localT * (100 + rnd.nextDouble() * 220) + rnd.nextDouble() * 22;
      final alpha = (1 - localT) * progress.clamp(0.0, 1.0).toDouble();
      final ember = Paint()
        ..color = (i.isEven ? const Color(0xFFFFD166) : const Color(0xFFFF6E37))
            .withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(x, y), 1.5 + rnd.nextDouble() * 3.4, ember);
    }

    for (var i = 0; i < 34; i++) {
      final seed = rnd.nextDouble();
      final localT = (time * .42 + seed) % 1.0;
      final x = centerX - cardW / 2 + rnd.nextDouble() * cardW +
          math.sin(localT * 5 + i) * 34;
      final y = burnY - 22 - localT * 160;
      final smoke = Paint()
        ..color = const Color(0xFF2B201E).withValues(alpha: (1 - localT) * .20 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(x, y), 9 + localT * 24, smoke);
    }
  }

  @override
  bool shouldRepaint(covariant _BurnParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.time != time ||
        oldDelegate.active != active;
  }
}

class _FlashMark extends StatelessWidget {
  const _FlashMark();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.local_fire_department_rounded,
      color: Colors.orange.shade200.withValues(alpha: .95),
      size: 54,
    );
  }
}
