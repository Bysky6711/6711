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
  late final AnimationController loopController;

  bool burning = false;

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

  @override
  void initState() {
    super.initState();
    burnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 80),
    )..repeat();
  }

  @override
  void dispose() {
    burnController.dispose();
    loopController.dispose();
    super.dispose();
  }

  Future<void> burnAndClose() async {
    if (burning) return;
    HapticFeedback.mediumImpact();
    setState(() => burning = true);
    await burnController.forward();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return MafiaIOSScaffold(
      darkOverlay: .12,
      child: Padding(
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
            LockClock(subtitle: burning ? 'Karta rozpada się w żar…' : 'Dotknij kartę'),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: burnAndClose,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([burnController, loopController]),
                    builder: (context, _) {
                      final burn = burnController.value;
                      final idleFloat = math.sin(loopController.value * math.pi * 2) * 7;
                      final shake = burn > .08 && burn < .65
                          ? math.sin(loopController.value * math.pi * 1100) * (1 + burn * 5)
                          : 0.0;
                      final scale = 1 + math.sin(loopController.value * math.pi * 2) * .012 - burn * .10;
                      final opacity = (1 - Curves.easeInQuart.transform(burn).clamp(0.0, 1.0)).toDouble();

                      return SizedBox(
                        width: 620,
                        height: 720,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _CardAshVortexPainter(
                                    progress: burn,
                                    time: loopController.value,
                                  ),
                                ),
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(shake, idleFloat - burn * 22),
                              child: Transform.scale(
                                scale: scale,
                                child: Opacity(
                                  opacity: opacity,
                                  child: _VisibleRoleCard(
                                    assetPath: assetPath,
                                    roleName: roleName,
                                    burn: burn,
                                  ),
                                ),
                              ),
                            ),
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
                'Karta jest odsłonięta. Stuknij, aby ją spalić.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .50),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibleRoleCard extends StatelessWidget {
  const _VisibleRoleCard({
    required this.assetPath,
    required this.roleName,
    required this.burn,
  });

  final String assetPath;
  final String roleName;
  final double burn;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    final crack = Curves.easeOutCubic.transform((burn * 1.55).clamp(0.0, 1.0).toDouble());
    return SizedBox(
      width: 246,
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .78),
                    blurRadius: 42,
                    offset: const Offset(0, 24),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFF7A3C).withValues(alpha: burn * .50),
                    blurRadius: 48,
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: radius,
            child: Image.asset(
              assetPath,
              width: 246,
              height: 340,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF220707),
                alignment: Alignment.center,
                child: Text(
                  roleName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: CustomPaint(painter: _CrackPainter(progress: crack)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: burn * .50),
                    const Color(0xFFFF7A3C).withValues(alpha: burn * .16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrackPainter extends CustomPainter {
  const _CrackPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final main = Paint()
      ..color = Colors.black.withValues(alpha: .52 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 + progress * 2.4;
    final glow = Paint()
      ..color = const Color(0xFFFFD166).withValues(alpha: .42 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final paths = <Path>[
      Path()
        ..moveTo(size.width * .50, size.height * .02)
        ..lineTo(size.width * .46, size.height * .22)
        ..lineTo(size.width * .54, size.height * .40)
        ..lineTo(size.width * .47, size.height * .62)
        ..lineTo(size.width * .53, size.height * .98),
      Path()
        ..moveTo(size.width * .47, size.height * .34)
        ..lineTo(size.width * .25, size.height * .43)
        ..lineTo(size.width * .12, size.height * .60),
      Path()
        ..moveTo(size.width * .54, size.height * .43)
        ..lineTo(size.width * .78, size.height * .50)
        ..lineTo(size.width * .91, size.height * .68),
      Path()
        ..moveTo(size.width * .48, size.height * .64)
        ..lineTo(size.width * .28, size.height * .76)
        ..lineTo(size.width * .18, size.height * .90),
    ];

    for (final path in paths) {
      final metric = path.computeMetrics().first;
      final partial = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(partial, glow);
      canvas.drawPath(partial, main);
    }
  }

  @override
  bool shouldRepaint(covariant _CrackPainter oldDelegate) => oldDelegate.progress != progress;
}

class _CardAshVortexPainter extends CustomPainter {
  const _CardAshVortexPainter({required this.progress, required this.time});

  final double progress;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final rnd = math.Random(77);
    final ignition = Curves.easeOutCubic.transform((progress * 1.2).clamp(0.0, 1.0).toDouble());

    final flash = Paint()
      ..color = const Color(0xFFFFA34A).withValues(alpha: .22 * (1 - progress).clamp(0.0, 1.0).toDouble())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34);
    canvas.drawCircle(center, 120 + progress * 90, flash);

    for (var i = 0; i < 160; i++) {
      final seed = rnd.nextDouble();
      final angle = seed * math.pi * 2 + progress * (2.8 + seed * 4.0);
      final startX = center.dx - 123 + rnd.nextDouble() * 246;
      final startY = center.dy - 170 + rnd.nextDouble() * 340;
      final radius = ignition * (80 + rnd.nextDouble() * 260);
      final swirl = Offset(math.cos(angle) * radius, math.sin(angle) * radius * .72);
      final lift = Offset(0, -progress * (40 + rnd.nextDouble() * 190));
      final pos = Offset(startX, startY) + swirl + lift;
      final life = (1 - progress * .72).clamp(0.0, 1.0).toDouble();
      final isEmber = i % 3 != 0;
      final color = isEmber
          ? (i.isEven ? const Color(0xFFFFD166) : const Color(0xFFFF6E37))
          : const Color(0xFF161210);
      final paint = Paint()
        ..color = color.withValues(alpha: life * (.35 + rnd.nextDouble() * .55))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isEmber ? 4.0 : 1.0);
      final s = isEmber ? 1.1 + rnd.nextDouble() * 3.4 : 2.0 + rnd.nextDouble() * 4.5;
      canvas.drawCircle(pos, s, paint);
    }

    for (var i = 0; i < 32; i++) {
      final seed = rnd.nextDouble();
      final t = (time * .5 + seed + progress * .4) % 1;
      final x = center.dx - 130 + rnd.nextDouble() * 260 + math.sin(t * 6 + i) * 35;
      final y = center.dy - 90 - t * 220 - progress * 80;
      final paint = Paint()
        ..color = const Color(0xFF2B201E).withValues(alpha: (1 - t) * progress * .18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawCircle(Offset(x, y), 10 + t * 24, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CardAshVortexPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.time != time;
  }
}
