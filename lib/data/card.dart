import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../models/game_edition.dart';
import '../ui_system/mafia_ios_system.dart';
import 'medieval_classes.dart';
import 'roles.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({
    super.key,
    required this.roleType,
    this.imagePath,
    this.playerName,
    this.playerId,
    this.roomCode,
    this.instantIdOnly = false,
    this.edition = GameEdition.standard,
    this.medievalClass,
  });

  final MafiaRoleCardType roleType;
  final String? imagePath;
  final String? playerName;
  final String? playerId;
  final String? roomCode;
  final bool instantIdOnly;

  /// Which edition's reveal to render (base slot-machine vs medieval parchment).
  final GameEdition edition;
  final MedievalClassType? medievalClass;

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
      ? 'GOSPODARZ'
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

  /// Pretty stable ID hashed from the raw player id — matches the in-game "ID" app.
  String get _displayId {
    var hash = 0;
    for (final code in playerId.codeUnits) {
      hash = (hash * 31 + code) & 0xFFFFFF;
    }
    return 'ID-${hash.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String get assetPath {
    if (widget.imagePath != null) return widget.imagePath!;
    switch (widget.roleType) {
      case MafiaRoleCardType.host:
        return 'assets/images/card/card_back_blue.jpg';
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
      duration: const Duration(milliseconds: 3200),
    );
    print = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    final hostMedieval = widget.edition.isMedieval && widget.medievalClass == null && widget.roleType == MafiaRoleCardType.host;
    if (widget.instantIdOnly || hostMedieval) {
      intro.value = 1;
      reels.value = 1;
      print.value = 1;
      printing = true;
    } else if (widget.edition.isMedieval && widget.medievalClass != null) {
      idle.repeat();
      _runMedievalCeremony();
    } else {
      idle.repeat();
      _runAnimation();
    }
  }

  /// Medieval knighting ceremony: the king raises, the sword touches the right
  /// then the left shoulder (a spark at each), then the parchment is sealed.
  Future<void> _runMedievalCeremony() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    await intro.forward(); // king rises
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    final ms = reels.duration!.inMilliseconds;
    Future<void>.delayed(Duration(milliseconds: (ms * 0.5).round()), () {
      if (mounted) HapticFeedback.lightImpact(); // right shoulder
    });
    Future<void>.delayed(Duration(milliseconds: (ms * 0.98).round()), () {
      if (mounted) HapticFeedback.lightImpact(); // left shoulder
    });
    await reels.forward(); // sword sweeps both shoulders
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => printing = true);
    await print.forward(); // parchment seals
    if (!mounted) return;
    idle.stop();
  }

  Future<void> _runAnimation() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    await intro.forward();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    // A short "clunk" as each reel snaps into place, left-to-right.
    final spinMs = reels.duration!.inMilliseconds;
    for (final stop in _Reel.stops) {
      Future<void>.delayed(Duration(milliseconds: (spinMs * stop).round()), () {
        if (mounted) HapticFeedback.selectionClick();
      });
    }
    await reels.forward();
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() => printing = true);
    await print.forward();
    if (!mounted) return;
    idle.stop();
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

  Widget _buildMedievalReveal(BuildContext context) {
    final def = MedievalClasses.definitionOf(widget.medievalClass!);
    return MafiaIOSScaffold(
      darkOverlay: .12,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 12, Responsive.horizontalPadding(context), 16),
          child: AnimatedBuilder(
            animation: Listenable.merge([intro, reels, print, idle]),
            builder: (context, _) {
              final printed = print.value >= 1;
              return Column(
                children: [
                  Align(alignment: Alignment.centerLeft, child: IOSBackButton(onTap: () => Navigator.pop(context, false))),
                  const SizedBox(height: 8),
                  LockClock(
                    subtitle: printed
                        ? 'Pasowanie zakończone'
                        : printing
                            ? 'Pieczętowanie identyfikatora…'
                            : 'Ceremonia pasowania…',
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 340,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (print.value < 1)
                          Opacity(
                            opacity: (1 - print.value).clamp(0.0, 1.0).toDouble(),
                            child: _KnightingCeremony(sweep: reels.value, rise: intro.value, color: def.color),
                          ),
                        if (print.value > 0)
                          Opacity(
                            opacity: print.value.clamp(0.0, 1.0).toDouble(),
                            child: _MedievalParchment(def: def, playerName: playerName, playerId: _displayId, roomCode: roomCode),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: printed ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !printed,
                      child: LockButton(text: 'Dalej', icon: Icons.check_rounded, light: true, onTap: () => Navigator.of(context).pop(true)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildKingReveal(BuildContext context) {
    return MafiaIOSScaffold(
      darkOverlay: .12,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 12, Responsive.horizontalPadding(context), 16),
          child: Column(children: [
            Align(alignment: Alignment.centerLeft, child: IOSBackButton(onTap: () => Navigator.pop(context, false))),
            const SizedBox(height: 8),
            const LockClock(subtitle: 'Tron'),
            const Spacer(),
            Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE0C8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7A1F2B), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 28, offset: const Offset(0, 16))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.workspace_premium_rounded, color: Color(0xFFC9A227), size: 64),
                SizedBox(height: 12),
                Text('KRÓL', style: TextStyle(color: Color(0xFF20120E), fontSize: 30, fontWeight: FontWeight.w900, fontFamily: 'BernierDistressed')),
                SizedBox(height: 8),
                Text('Prowadzisz dwór — zmieniasz fazy, rozdajesz karty i czuwasz nad ceremoniałem. Nie należysz do żadnej frakcji.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF3B2A1E), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
              ]),
            ),
            const Spacer(),
            LockButton(text: 'Dalej', icon: Icons.check_rounded, light: true, onTap: () => Navigator.of(context).pop(true)),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Widget _buildInstantIdView(BuildContext context) {
    return MafiaIOSScaffold(
      darkOverlay: .10,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
          Responsive.horizontalPadding(context),
          12,
          Responsive.horizontalPadding(context),
          28 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).top -
                MediaQuery.paddingOf(context).bottom -
                34,
          ),
          child: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IOSBackButton(onTap: () => Navigator.pop(context, false)),
                  ),
                  const SizedBox(height: 10),
                  const LockClock(),
                  const SizedBox(height: 28),
                  RepaintBoundary(
                    child: PrintedMafiaId(
                      progress: 1,
                      assetPath: assetPath,
                      playerName: playerName,
                      playerId: _displayId,
                      roomCode: roomCode,
                      role: displayRole,
                      onFinish: () => Navigator.of(context).pop(false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.edition.isMedieval && widget.medievalClass != null) {
      return _buildMedievalReveal(context);
    }
    if (widget.edition.isMedieval && widget.roleType == MafiaRoleCardType.host) {
      return _buildKingReveal(context);
    }
    if (widget.instantIdOnly) {
      return _buildInstantIdView(context);
    }

    return MafiaIOSScaffold(
      darkOverlay: .12,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context),
            12,
            Responsive.horizontalPadding(context),
            16,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IOSBackButton(onTap: () => Navigator.pop(context, false)),
              ),
              const SizedBox(height: 8),
              LockClock(
                subtitle: print.value >= 1
                    ? 'Karta wydrukowana'
                    : printing
                        ? 'Drukowanie identyfikatora…'
                        : 'Losowanie roli…',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([intro, reels, print, idle]),
                        builder: (context, _) {
                          final printed = print.value >= 1;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Fixed-height stage so the machine and the printed ID
                              // cross-fade IN PLACE (no layout jump when reels vanish).
                              SizedBox(
                                height: 340,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: RepaintBoundary(
                                          child: CustomPaint(
                                            painter: _CasinoGlowPainter(
                                              time: idle.value,
                                              power: (intro.value + reels.value).clamp(0.0, 1.0).toDouble(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (print.value < 1)
                                      Opacity(
                                        opacity: (1 - print.value).clamp(0.0, 1.0).toDouble(),
                                        child: Transform.translate(
                                          offset: Offset(0, (1 - Curves.easeOutBack.transform(intro.value)) * -20),
                                          child: Opacity(
                                            opacity: intro.value.clamp(0.0, 1.0).toDouble(),
                                            child: _SlotMachine(
                                              progress: reels.value,
                                              time: idle.value,
                                              targetIcon: _RoleIconSpec.forRole(widget.roleType),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (print.value > 0)
                                      Opacity(
                                        opacity: print.value.clamp(0.0, 1.0).toDouble(),
                                        child: PrintedMafiaId(
                                          progress: print.value,
                                          assetPath: assetPath,
                                          playerName: playerName,
                                          playerId: _displayId,
                                          roomCode: roomCode,
                                          role: displayRole,
                                          onFinish: finish,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: printed ? 1 : 0,
                                child: IgnorePointer(
                                  ignoring: !printed,
                                  child: LockButton(
                                    text: 'Dalej',
                                    icon: Icons.check_rounded,
                                    light: true,
                                    onTap: finish,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: printed ? 1 : 0,
                                child: Text(
                                  'Stuknij miniaturę karty, aby powiększyć podgląd.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.white.withValues(alpha: .66),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleIconSpec {
  const _RoleIconSpec(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;

  static _RoleIconSpec forRole(MafiaRoleCardType role) {
    switch (role) {
      case MafiaRoleCardType.host:
        return const _RoleIconSpec(
          Icons.shield_moon_rounded,
          'HOST',
          Color(0xFFF6C453),
        );
      case MafiaRoleCardType.mafia:
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
    final landed = progress > .96;
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // ---- Cabinet body (gold-framed casino chassis) ----
          Positioned(
            top: 30,
            left: 8,
            right: 8,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF7C1519), Color(0xFF43090C), Color(0xFF17080A)],
                ),
                border: Border.all(color: const Color(0xFFE7B24C), width: 2.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .7), blurRadius: 28, offset: const Offset(0, 20)),
                  BoxShadow(color: const Color(0xFFD62330).withValues(alpha: .22 + pulse * .16), blurRadius: 32),
                ],
              ),
            ),
          ),
          // ---- Top marquee sign with chase bulbs ----
          Positioned(top: 0, child: _Marquee(pulse: pulse)),
          // ---- Reel window + center payline ----
          Positioned(
            top: 86,
            child: Container(
              width: 244,
              height: 120,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFF040101),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7B24C).withValues(alpha: .85), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .9), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Stack(
                children: [
                  Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _Reel(index: index, progress: progress, target: targetIcon),
                        ),
                      );
                    }),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5404F).withValues(alpha: landed ? 0 : .5),
                            boxShadow: landed ? null : [BoxShadow(color: const Color(0xFFE5404F).withValues(alpha: .6), blurRadius: 5)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ---- Result badge under the reels ----
          Positioned(
            top: 218,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: landed ? 1 : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: targetIcon.color.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: targetIcon.color.withValues(alpha: .6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(targetIcon.icon, color: targetIcon.color, size: 15),
                    const SizedBox(width: 7),
                    Text('WYLOSOWANO: ${targetIcon.label}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
          // ---- Payout tray at the base ----
          Positioned(
            bottom: 12,
            child: Container(
              width: 150,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0405),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE7B24C).withValues(alpha: .5)),
              ),
              child: Text(
                landed ? '★ WYPŁATA ★' : 'INSERT COIN',
                style: TextStyle(color: const Color(0xFFE7B24C).withValues(alpha: .85), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
          ),
          // ---- Side lever ----
          Positioned(right: -12, top: 96, child: _SlotLever(progress: progress)),
        ],
      ),
    );
  }
}

/// The lit sign on top of the cabinet, with a row of chasing bulbs each side.
class _Marquee extends StatelessWidget {
  const _Marquee({required this.pulse});
  final double pulse;

  Widget _bulb(int i) {
    final on = ((pulse * 6 + i) % 3) < 1.5;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? const Color(0xFFFFE9A8) : const Color(0xFF6E5522),
          boxShadow: on ? [BoxShadow(color: const Color(0xFFFFD166).withValues(alpha: .9), blurRadius: 6)] : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [Color(0xFF2A0709), Color(0xFF520E12)]),
        border: Border.all(color: const Color(0xFFE7B24C), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD166).withValues(alpha: .22 + pulse * .22), blurRadius: 18)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _bulb(0),
          _bulb(1),
          _bulb(2),
          const SizedBox(width: 8),
          const Text('M A F I A', style: TextStyle(color: Color(0xFFFFE39B), fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(width: 8),
          _bulb(3),
          _bulb(4),
          _bulb(5),
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

  /// Fraction of the spin at which each reel comes to rest (left-to-right).
  static const stops = [0.54, 0.73, 0.92];

  /// A long vertical strip of random symbols that always ends on the drawn
  /// [target]. A longer strip means a faster, more motion-blurred spin.
  List<_RoleIconSpec> _strip() {
    final rnd = math.Random(index * 97 + 13);
    final loops = 20 + index * 6;
    return [
      for (var i = 0; i < loops; i++) _items[rnd.nextInt(_items.length)],
      target,
    ];
  }

  /// Strong deceleration plus a small damped overshoot-and-settle wobble that
  /// lands exactly on the target at t == 1 — like a real mechanical reel
  /// snapping into its detent.
  double _settleCurve(double t) {
    final decel = 1 - math.pow(1 - t, 3.4).toDouble();
    final wobble = math.sin(t * math.pi * 3.0) * (1 - t) * (1 - t) * 0.05;
    return decel + wobble;
  }

  @override
  Widget build(BuildContext context) {
    final stopAt = stops[index];
    final local = (progress / stopAt).clamp(0.0, 1.0).toDouble();
    final eased = _settleCurve(local);
    final spinning = local < 1;
    // Approx. instantaneous speed drives the vertical motion blur.
    final speed = spinning ? (1 - local) : 0.0;
    final strip = _strip();
    final borderColor =
        spinning ? Colors.white.withValues(alpha: .16) : target.color.withValues(alpha: .7);

    return LayoutBuilder(
      builder: (context, c) {
        final cell = c.maxHeight;
        final maxShift = (strip.length - 1) * cell;
        final shift = eased * maxShift;
        final blur = (speed * 9).clamp(0.0, 9.0).toDouble();
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF120505),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor, width: spinning ? 1 : 1.6),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OverflowBox(
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: Offset(0, -shift),
                    child: ImageFiltered(
                      enabled: blur > 0.2,
                      imageFilter: ImageFilter.blur(sigmaX: 0, sigmaY: blur),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final spec in strip)
                            SizedBox(height: cell, child: Center(child: _ReelSymbol(spec: spec, large: !spinning))),
                        ],
                      ),
                    ),
                  ),
                ),
                // Curved-drum shading: darker at top/bottom, bright in the middle.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .72),
                            Colors.transparent,
                            Colors.black.withValues(alpha: .72),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                // Payline highlight over the landed target.
                if (!spinning)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: target.color.withValues(alpha: .55)),
                            bottom: BorderSide(color: target.color.withValues(alpha: .55)),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              target.color.withValues(alpha: .16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The casino lever on the side of the cabinet — pulled down as the reels start.
class _SlotLever extends StatelessWidget {
  const _SlotLever({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    final pull = Curves.easeOutCubic.transform((progress / 0.16).clamp(0.0, 1.0).toDouble());
    return SizedBox(
      width: 30,
      height: 132,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 20,
            child: Container(
              width: 7,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBFC6CF), Color(0xFF6B7280)],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, pull * 70),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFFFF5A63), Color(0xFFB01019)]),
                border: Border.all(color: Colors.white.withValues(alpha: .5), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFFD62330).withValues(alpha: .6), blurRadius: 12)],
              ),
            ),
          ),
        ],
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

/// Animated king-knighting ceremony (medieval reveal): a crowned king above, a
/// kneeling figure below, and a sword that sweeps to touch the right then the
/// left shoulder — a spark at each touch — before the parchment is sealed.
class _KnightingCeremony extends StatelessWidget {
  const _KnightingCeremony({required this.sweep, required this.rise, required this.color});
  final double sweep; // 0..1 sword sweep (right shoulder at .5, left at 1)
  final double rise; // 0..1 intro (king + knight appear)
  final Color color;

  @override
  Widget build(BuildContext context) {
    final r = Curves.easeOutBack.transform(rise.clamp(0.0, 1.0).toDouble()).clamp(0.0, 1.0).toDouble();
    // 0 -> +0.35 (right shoulder) by .5 -> -0.35 (left shoulder) by 1.
    final angle = sweep < .5 ? (sweep / .5) * .35 : .35 + ((sweep - .5) / .5) * -.70;
    final rightSpark = sweep >= .42 && sweep <= .60;
    final leftSpark = sweep >= .9;
    return SizedBox(
      width: 300,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // King (crown) descending in.
          Positioned(
            top: 6,
            child: Opacity(
              opacity: r,
              child: Transform.translate(
                offset: Offset(0, (1 - r) * -24),
                child: Column(children: const [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFC9A227), size: 48),
                  SizedBox(height: 4),
                  Text('KRÓL', style: TextStyle(color: Color(0xFFC9A227), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ]),
              ),
            ),
          ),
          // Kneeling knight rising in.
          Positioned(
            bottom: 22,
            child: Opacity(
              opacity: r,
              child: Column(children: [
                Icon(Icons.shield_moon_rounded, color: color.withValues(alpha: .9), size: 38),
                const SizedBox(height: 2),
                Icon(Icons.person_rounded, color: AppColors.white.withValues(alpha: .85), size: 66),
              ]),
            ),
          ),
          // The sword, pivoting from the king's hand.
          Positioned(
            top: 82,
            child: Transform.rotate(
              angle: angle,
              alignment: Alignment.topCenter,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 11, height: 20, decoration: BoxDecoration(color: const Color(0xFF6B4A2B), borderRadius: BorderRadius.circular(3))),
                Container(width: 42, height: 8, decoration: BoxDecoration(color: const Color(0xFFC9A227), borderRadius: BorderRadius.circular(2))),
                Container(
                  width: 8,
                  height: 122,
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDE0C8), Color(0xFF9AA0A6)])),
                ),
              ]),
            ),
          ),
          if (rightSpark) const Positioned(right: 88, bottom: 128, child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFE39B), size: 32)),
          if (leftSpark) const Positioned(left: 88, bottom: 128, child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFE39B), size: 32)),
        ],
      ),
    );
  }
}

/// The medieval edition's "papyrus tożsamości" — a parchment scroll with a wax
/// seal showing the drawn court class, in place of the base printed ID card.
class _MedievalParchment extends StatelessWidget {
  const _MedievalParchment({required this.def, required this.playerName, required this.playerId, required this.roomCode});
  final MedievalClassDefinition def;
  final String playerName;
  final String playerId;
  final String roomCode;

  String _factionLabel(MedievalFaction f) => switch (f) {
        MedievalFaction.antagonisci => 'Ród Węża (Antagoniści)',
        MedievalFaction.korona => 'Korona',
        MedievalFaction.neutralny => 'Neutralny',
        MedievalFaction.niezdeklarowany => 'Niezdeklarowany',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE0C8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7A1F2B), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .6), blurRadius: 30, offset: const Offset(0, 18)),
          BoxShadow(color: const Color(0xFFC9A227).withValues(alpha: .2), blurRadius: 26),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('DWÓR KRÓLEWSKI', style: TextStyle(color: const Color(0xFF7A1F2B).withValues(alpha: .85), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 3, fontFamily: 'BernierDistressed')),
          const SizedBox(height: 14),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: def.color.withValues(alpha: .16), border: Border.all(color: def.color, width: 2)),
            child: Icon(def.icon, color: def.color, size: 52),
          ),
          const SizedBox(height: 16),
          Text(def.name, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF20120E), fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'BernierDistressed')),
          const SizedBox(height: 4),
          Text(_factionLabel(def.faction), style: const TextStyle(color: Color(0xFF7A1F2B), fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(def.description, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF3B2A1E), fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF7A1F2B).withValues(alpha: .3)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF20120E), fontSize: 16, fontWeight: FontWeight.w900)),
                  Text('Pokój $roomCode  •  $playerId', style: TextStyle(color: const Color(0xFF3B2A1E).withValues(alpha: .8), fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF7A1F2B), boxShadow: [BoxShadow(color: const Color(0xFF7A1F2B).withValues(alpha: .5), blurRadius: 10)]),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFEDE0C8), size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrintedMafiaId extends StatelessWidget {
  const PrintedMafiaId({
    super.key,
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
    final curved = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0).toDouble());
    return Transform.translate(
      offset: Offset(0, (1 - curved) * 26),
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
                          'Identyfikator',
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
      pageBuilder: (_, _, _) {
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
      transitionBuilder: (_, animation, _, child) {
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
    if (power <= 0) return;
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

    for (var i = 0; i < 28; i++) {
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
            .withValues(alpha: (1 - t) * .32 * power);
      canvas.drawCircle(pos, 1.6 + seed * 2.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CasinoGlowPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.power != power;
  }
}
