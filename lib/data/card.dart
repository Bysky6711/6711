import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../ui_system/mafia_ios_system.dart';
import 'roles.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({
    super.key,
    required this.roleType,
    this.imagePath,
    this.playerName,
    this.playerId,
    this.roomCode,
  });

  final MafiaRoleCardType roleType;
  final String? imagePath;
  final String? playerName;
  final String? playerId;
  final String? roomCode;

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with TickerProviderStateMixin {
  late final AnimationController intro;
  late final AnimationController reels;
  late final AnimationController print;
  late final AnimationController idle;

  bool printing = false;

  String get roleName => GameRoles.nameOf(widget.roleType);
  String get displayRole => widget.roleType == MafiaRoleCardType.host
      ? 'MAFIA'
      : roleName.toUpperCase();
  String get playerName => widget.playerName?.trim().isNotEmpty == true
      ? widget.playerName!.trim()
      : 'GOSPODARZ';
  String get roomCode => widget.roomCode?.trim().isNotEmpty == true
      ? widget.roomCode!.trim()
      : 'LOCAL';
  String get playerId => widget.playerId?.trim().isNotEmpty == true
      ? widget.playerId!.trim()
      : _fallbackId;

  String get _fallbackId {
    final source = '$playerName-$roomCode-$displayRole';
    var hash = 0;
    for (final code in source.codeUnits) {
      hash = (hash * 31 + code) & 0xFFFFFF;
    }
    return 'ID-${hash.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

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
    intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    reels = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2650),
    );
    print = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _runAnimation();
  }

  Future<void> _runAnimation() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await intro.forward();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    await reels.forward();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => printing = true);
    await print.forward();
  }

  @override
  void dispose() {
    intro.dispose();
    reels.dispose();
    print.dispose();
    idle.dispose();
    super.dispose();
  }

  void finish() {
    if (print.value < 1) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: _RevealBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                12,
                Responsive.horizontalPadding(context),
                18,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IOSBackButton(
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LockClock(
                    subtitle: print.value >= 1
                        ? 'Karta wydrukowana'
                        : printing
                            ? 'Drukowanie identyfikatora…'
                            : 'Losowanie roli…',
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([intro, reels, print, idle]),
                        builder: (context, _) {
                          return SizedBox(
                            width: 360,
                            height: 610,
                            child: Stack(
                              alignment: Alignment.topCenter,
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CasinoGlowPainter(
                                        time: idle.value,
                                        power: (intro.value + reels.value + print.value)
                                            .clamp(0.0, 1.0)
                                            .toDouble(),
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: Offset(
                                    0,
                                    (1 - Curves.easeOutBack.transform(intro.value)) * -26,
                                  ),
                                  child: Opacity(
                                    opacity: intro.value.clamp(0.0, 1.0).toDouble(),
                                    child: _SlotMachine(
                                      progress: reels.value,
                                      time: idle.value,
                                      targetIcon: _RoleIconSpec.forRole(widget.roleType),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 258,
                                  child: _PrintedMafiaId(
                                    progress: print.value,
                                    assetPath: assetPath,
                                    playerName: playerName,
                                    playerId: playerId,
                                    roomCode: roomCode,
                                    role: displayRole,
                                    onFinish: finish,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: print,
                    builder: (context, _) {
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: print.value >= 1 ? 1 : 0,
                        child: Text(
                          'Kliknij miniaturę karty, aby zobaczyć podgląd. Kliknij ✓, aby przejść dalej.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: .68),
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealBackground extends StatelessWidget {
  const _RevealBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/backgrounds/new_background.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.1,
                colors: [Color(0xFF4A1010), Color(0xFF160404), Colors.black],
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: .18),
                Colors.black.withValues(alpha: .34),
                Colors.black.withValues(alpha: .70),
              ],
            ),
          ),
        ),
        const IgnorePointer(child: _SoftRainOverlay()),
      ],
    );
  }
}

class _SoftRainOverlay extends StatefulWidget {
  const _SoftRainOverlay();

  @override
  State<_SoftRainOverlay> createState() => _SoftRainOverlayState();
}

class _SoftRainOverlayState extends State<_SoftRainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        painter: _RainPainter(progress: controller.value),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  const _RainPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1;
    for (var i = 0; i < 34; i++) {
      final x = (i * 47 + progress * 120) % size.width;
      final y = (i * 83 + progress * 260) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 8, y + 34), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _RoleIconSpec {
  const _RoleIconSpec(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;

  static _RoleIconSpec forRole(MafiaRoleCardType role) {
    switch (role) {
      case MafiaRoleCardType.mafia:
      case MafiaRoleCardType.host:
        return const _RoleIconSpec(
          Icons.local_fire_department_rounded,
          'MAFIA',
          Color(0xFFD62330),
        );
      case MafiaRoleCardType.detective:
        return const _RoleIconSpec(Icons.manage_search_rounded, 'DET', Color(0xFF60A5FA));
      case MafiaRoleCardType.sheriff:
        return const _RoleIconSpec(Icons.gpp_good_rounded, 'SZER', Color(0xFFF6C453));
      case MafiaRoleCardType.doctor:
        return const _RoleIconSpec(Icons.medical_services_rounded, 'LEK', Color(0xFF34D399));
      case MafiaRoleCardType.citizen:
        return const _RoleIconSpec(Icons.person_rounded, 'OBYW', Color(0xFFE7D8B7));
    }
  }
}

class _SlotMachine extends StatelessWidget {
  const _SlotMachine({
    required this.progress,
    required this.time,
    required this.targetIcon,
  });

  final double progress;
  final double time;
  final _RoleIconSpec targetIcon;

  @override
  Widget build(BuildContext context) {
    final pulse = math.sin(time * math.pi * 2) * .5 + .5;
    return SizedBox(
      width: 330,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 320,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2B0909), Color(0xFF090203), Color(0xFF3A1010)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .75),
                  blurRadius: 34,
                  offset: const Offset(0, 22),
                ),
                BoxShadow(
                  color: const Color(0xFFD62330).withValues(alpha: .22 + pulse * .14),
                  blurRadius: 42,
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: .35)),
              ),
              child: const Text(
                'MAFIA ROLE JACKPOT',
                style: TextStyle(
                  color: Color(0xFFFFD166),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            top: 70,
            child: Container(
              width: 284,
              height: 118,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF050101),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .82),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _Reel(index: index, progress: progress, target: targetIcon),
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            top: 199,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: progress > .96 ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: targetIcon.color.withValues(alpha: .20),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: targetIcon.color.withValues(alpha: .45)),
                ),
                child: Text(
                  'JACKPOT: ${targetIcon.label} ×3',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 7,
            child: Container(
              width: 96,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .74),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Reel extends StatelessWidget {
  const _Reel({required this.index, required this.progress, required this.target});

  final int index;
  final double progress;
  final _RoleIconSpec target;

  static const _items = [
    _RoleIconSpec(Icons.local_fire_department_rounded, 'MAFIA', Color(0xFFD62330)),
    _RoleIconSpec(Icons.manage_search_rounded, 'DET', Color(0xFF60A5FA)),
    _RoleIconSpec(Icons.gpp_good_rounded, 'SZER', Color(0xFFF6C453)),
    _RoleIconSpec(Icons.medical_services_rounded, 'LEK', Color(0xFF34D399)),
    _RoleIconSpec(Icons.person_rounded, 'OBYW', Color(0xFFE7D8B7)),
  ];

  @override
  Widget build(BuildContext context) {
    final stopAt = .68 + index * .10;
    final spinning = progress < stopAt;
    final phase = spinning ? (progress * (18 + index * 7)) : 0.0;
    final current = spinning ? _items[((phase.floor() + index) % _items.length)] : target;
    final offset = spinning ? ((phase % 1) - .5) * 38 : 0.0;
    final blurOpacity = spinning ? .34 : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF120505),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: current.color.withValues(alpha: spinning ? .18 : .58)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, offset),
              child: _ReelSymbol(spec: current, large: !spinning),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .62),
                        Colors.transparent,
                        Colors.black.withValues(alpha: .62),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: Container(color: Colors.white.withValues(alpha: blurOpacity))),
          ],
        ),
      ),
    );
  }
}

class _ReelSymbol extends StatelessWidget {
  const _ReelSymbol({required this.spec, required this.large});

  final _RoleIconSpec spec;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(spec.icon, color: spec.color, size: large ? 38 : 32),
        const SizedBox(height: 5),
        Text(
          spec.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .88),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
      ],
    );
  }
}

class _PrintedMafiaId extends StatelessWidget {
  const _PrintedMafiaId({
    required this.progress,
    required this.assetPath,
    required this.playerName,
    required this.playerId,
    required this.roomCode,
    required this.role,
    required this.onFinish,
  });

  final double progress;
  final String assetPath;
  final String playerName;
  final String playerId;
  final String roomCode;
  final String role;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final curved = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0).toDouble());
    return Transform.translate(
      offset: Offset(0, -88 + curved * 128),
      child: Opacity(
        opacity: progress.clamp(0.0, 1.0).toDouble(),
        child: Container(
          width: 286,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4E8D2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF3B241B).withValues(alpha: .28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .55),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
              BoxShadow(color: const Color(0xFFFFD166).withValues(alpha: .18), blurRadius: 26),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _PreviewableCardThumb(assetPath: assetPath, role: role),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TAJNY IDENTYFIKATOR',
                          style: TextStyle(
                            color: Color(0xFF6F1D1B),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          playerName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF20120E),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ROLA: $role',
                          style: const TextStyle(
                            color: Color(0xFF6F1D1B),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _TicketLine(label: 'POKÓJ', value: roomCode),
                        _TicketLine(label: 'ID', value: playerId),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFF3B241B).withValues(alpha: .22)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _Barcode(seed: '$playerName-$playerId-$roomCode')),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onFinish,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6F1D1B).withValues(alpha: .10),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF6F1D1B), size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewableCardThumb extends StatelessWidget {
  const _PreviewableCardThumb({required this.assetPath, required this.role});

  final String assetPath;
  final String role;

  void _openPreview(BuildContext context) {
    HapticFeedback.selectionClick();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Podgląd karty',
      barrierColor: Colors.black.withValues(alpha: .72),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 290,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF120505),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: .14)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: .70), blurRadius: 36),
                    BoxShadow(color: const Color(0xFFD62330).withValues(alpha: .28), blurRadius: 46),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        assetPath,
                        width: 250,
                        height: 345,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stuknij, aby zamknąć podgląd',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .56),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: Tween<double>(begin: .82, end: 1).animate(curved), child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPreview(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 74,
            height: 102,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .28),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(assetPath, fit: BoxFit.cover),
          ),
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF6F1D1B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF4E8D2), width: 2),
              ),
              child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketLine extends StatelessWidget {
  const _TicketLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF3B241B),
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class _Barcode extends StatelessWidget {
  const _Barcode({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    var h = 11;
    for (final c in seed.codeUnits) {
      h = (h * 33 + c) & 0xFFFF;
    }
    return SizedBox(
      height: 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(34, (i) {
          final w = 1.0 + ((h >> (i % 12)) & 3).toDouble();
          return Padding(
            padding: const EdgeInsets.only(right: 1),
            child: Container(
              width: w,
              color: const Color(0xFF20120E).withValues(alpha: i.isEven ? .88 : .52),
            ),
          );
        }),
      ),
    );
  }
}

class _CasinoGlowPainter extends CustomPainter {
  const _CasinoGlowPainter({required this.time, required this.power});
  final double time;
  final double power;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .24);
    final rnd = math.Random(911);
    final bg = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFD62330).withValues(alpha: .20 * power),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 260));
    canvas.drawCircle(center, 260, bg);

    for (var i = 0; i < 70; i++) {
      final seed = rnd.nextDouble();
      final t = (time + seed) % 1;
      final angle = seed * math.pi * 2;
      final r = 70 + seed * 230;
      final pos = center +
          Offset(
            math.cos(angle + time * 1.8) * r,
            math.sin(angle + time * 1.8) * r * .65 + t * 40,
          );
      final paint = Paint()
        ..color = (i.isEven ? const Color(0xFFFFD166) : const Color(0xFFFF7A3C))
            .withValues(alpha: (1 - t) * .38 * power)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(pos, 1.2 + seed * 2.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CasinoGlowPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.power != power;
  }
}
