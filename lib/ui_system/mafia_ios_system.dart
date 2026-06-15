import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../models/game_phase.dart';
import '../widgets/shared_widgets.dart';

class MafiaAssets {
  const MafiaAssets._();

  // Poprawiona ścieżka: folder `card`, nie `cards`.
  static const String redCard = 'assets/images/card/card_back_red.jpg';
  static const String blueCard = 'assets/images/card/card_back_blue.jpg';
  static const String powerCard = 'assets/images/card/card_back_blue.jpg';
}

String phaseLabel(GamePhase phase) {
  switch (phase) {
    case GamePhase.setup:
      return 'Przygotowanie';
    case GamePhase.day:
      return 'Dzień';
    case GamePhase.night:
      return 'Noc';
    case GamePhase.voting:
      return 'Głosowanie';
    case GamePhase.finished:
      return 'Koniec gry';
  }
}

IconData phaseIcon(GamePhase phase) {
  switch (phase) {
    case GamePhase.day:
      return Icons.wb_sunny_rounded;
    case GamePhase.night:
      return Icons.nightlight_round;
    case GamePhase.voting:
      return Icons.how_to_vote_rounded;
    case GamePhase.finished:
      return Icons.flag_rounded;
    case GamePhase.setup:
      return Icons.hourglass_top_rounded;
  }
}

class MafiaIOSScaffold extends StatelessWidget {
  const MafiaIOSScaffold({
    super.key,
    required this.child,
    this.darkOverlay = 0.035,
    this.rain = true,
    this.lightning = true,
  });

  final Widget child;
  final double darkOverlay;
  final bool rain;
  final bool lightning;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: MafiaIOSBackground(
        darkOverlay: darkOverlay,
        rain: rain,
        lightning: lightning,
        child: SafeArea(child: child),
      ),
    );
  }
}

class MafiaIOSBackground extends StatefulWidget {
  const MafiaIOSBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.035,
    this.rain = true,
    this.lightning = true,
  });

  final Widget child;
  final double darkOverlay;
  final bool rain;
  final bool lightning;

  @override
  State<MafiaIOSBackground> createState() => _MafiaIOSBackgroundState();
}

class _MafiaIOSBackgroundState extends State<MafiaIOSBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    // Długi cykl + modulo w painterze = brak widocznego restartu.
    controller = AnimationController(vsync: this, duration: const Duration(seconds: 120))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: CinematicRainCityPainter(
                    progress: controller.value,
                    rain: widget.rain,
                    lightning: widget.lightning,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.12,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: .22),
                  Colors.black.withValues(alpha: .86),
                ],
                stops: const [.10, .64, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withValues(alpha: widget.darkOverlay))),
        Positioned.fill(child: RepaintBoundary(child: widget.child)),
      ],
    );
  }
}

class CinematicRainCityPainter extends CustomPainter {
  const CinematicRainCityPainter({
    required this.progress,
    required this.rain,
    required this.lightning,
  });

  final double progress;
  final bool rain;
  final bool lightning;

  static const List<double> _widths = [28, 46, 34, 62, 39, 76, 52, 32, 66, 44, 56, 30];
  static const List<double> _heights = [.18, .34, .24, .42, .28, .38, .21, .32, .45, .26, .36, .30];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _paintSky(canvas, rect);
    _paintMovingCityLayer(canvas, size, layer: 0, speed: 16, alpha: .22);
    _paintMovingCityLayer(canvas, size, layer: 1, speed: 28, alpha: .42);
    _paintMovingCityLayer(canvas, size, layer: 2, speed: 42, alpha: .92);
    if (rain) _paintRain(canvas, size);
    if (lightning) _paintLightning(canvas, size);
    _paintBottomFade(canvas, rect);
  }

  void _paintSky(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF020000),
            Color(0xFF1B0303),
            Color(0xFF8B1818),
            Color(0xFF190202),
            Color(0xFF000000),
          ],
          stops: [0, .18, .47, .77, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.14),
          radius: .76,
          colors: [
            AppColors.cityGlowRed.withValues(alpha: .48),
            AppColors.cityGlowRed.withValues(alpha: .10),
            Colors.transparent,
          ],
          stops: const [0, .46, 1],
        ).createShader(rect),
    );
  }

  // Ruchoma panorama, ale płynnie zapętlona: rysujemy dwa zestawy za sobą.
  void _paintMovingCityLayer(Canvas canvas, Size size, {required int layer, required double speed, required double alpha}) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: alpha);
    final baseY = [size.height * .58, size.height * .67, size.height * .76][layer];
    final patternWidth = _patternWidth(layer);
    final shift = (progress * speed * 120) % patternWidth;
    for (var repeat = -1; repeat < 3; repeat++) {
      var x = repeat * patternWidth - shift - 40;
      var i = 0;
      while (x < (repeat + 1) * patternWidth - shift + 40) {
        final w = _widths[(i + layer * 3) % _widths.length] * (1 + layer * .10);
        final h = size.height * _heights[(i + layer) % _heights.length];
        final rect = Rect.fromLTWH(x, baseY - h, w, h);
        canvas.drawRect(rect, paint);
        if ((i + layer) % 2 == 0) {
          final sx = x + w * (.38 + ((i % 4) * .12));
          canvas.drawLine(
            Offset(sx, baseY - h),
            Offset(sx, baseY - h - 38 - layer * 18),
            Paint()
              ..color = paint.color
              ..strokeWidth = 2.2 + layer
              ..strokeCap = StrokeCap.round,
          );
        }
        x += w + 7 + (i % 3) * 5;
        i++;
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(0, baseY, size.width, size.height - baseY),
      Paint()..color = layer == 2 ? Colors.black : Colors.black.withValues(alpha: .12 + layer * .18),
    );
  }

  double _patternWidth(int layer) {
    var total = 0.0;
    for (var i = 0; i < 24; i++) {
      total += _widths[(i + layer * 3) % _widths.length] * (1 + layer * .10) + 7 + (i % 3) * 5;
    }
    return total;
  }

  void _paintRain(Canvas canvas, Size size) {
    final p = (progress * 120) % 1.0;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .16)
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.round;
    const count = 150;
    for (var i = 0; i < count; i++) {
      final seed = (i * 37) % 997;
      final xBase = (seed / 997) * (size.width + 210) - 105;
      final local = (p + i * .031) % 1.0;
      final y = local * (size.height + 165) - 105;
      final x = xBase - y * .13;
      final len = 12 + (i % 5) * 4;
      canvas.drawLine(Offset(x, y), Offset(x - len * .24, y + len), paint);
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    final cycle = (progress * 120) % 17.0;
    final pulse = cycle > 16.35 ? (1 - ((cycle - 16.35) / .65)).clamp(0.0, 1.0) : 0.0;
    if (pulse <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD8E8FF).withValues(alpha: .10 * pulse));
    final path = Path();
    var x = size.width * .63;
    var y = 0.0;
    path.moveTo(x, y);
    for (final s in const [Offset(-28, 48), Offset(34, 68), Offset(-24, 52), Offset(42, 70), Offset(-34, 58)]) {
      x += s.dx;
      y += s.dy;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8F1FF).withValues(alpha: .68 * pulse)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintBottomFade(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: .18),
            Colors.black.withValues(alpha: .96),
          ],
          stops: const [.48, .80, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CinematicRainCityPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rain != rain || oldDelegate.lightning != lightning;
  }
}

class LockClock extends StatelessWidget {
  const LockClock({super.key, this.subtitle});
  final String? subtitle;

  String _time() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _time(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: Responsive.clamp(Responsive.width(context) * .22, 78, 108),
            fontWeight: FontWeight.w900,
            height: .9,
            letterSpacing: 2,
            shadows: const [Shadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(4, 5))],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white.withValues(alpha: .78), fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ],
    );
  }
}

class LockGlassPanel extends StatelessWidget {
  const LockGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.opacity = .085,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 38, sigmaY: 38),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: .28)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 30, offset: const Offset(0, 16)),
              BoxShadow(color: Colors.white.withValues(alpha: .08), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class LockNotificationTile extends StatelessWidget {
  const LockNotificationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingIcon,
    this.assetPath = MafiaAssets.redCard,
    this.compact = false,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final String assetPath;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 64.0 : 72.0;
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: .985,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: h,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .56),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .56)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CardAsset(assetPath: assetPath, fallbackColor: MafiaPlayingCardColor.red, compact: true, title: 'M'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.black, fontSize: 18, height: 1, fontWeight: FontWeight.w900, letterSpacing: .8)),
                      const SizedBox(height: 5),
                      Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.black.withValues(alpha: .72), fontSize: 13, height: 1, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  Icon(trailingIcon, color: AppColors.black, size: 19),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LockTextField extends StatelessWidget {
  const LockTextField({super.key, required this.controller, required this.hint, this.onSubmitted});
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.white.withValues(alpha: .42), fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .075),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .16))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .16))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .70), width: 1.3)),
      ),
    );
  }
}

class LockButton extends StatelessWidget {
  const LockButton({super.key, required this.text, required this.onTap, this.icon, this.light = false});
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: .96,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: .68) : Colors.white.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: light ? .50 : .22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: light ? AppColors.black : AppColors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(text.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: light ? AppColors.black : AppColors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
          ],
        ),
      ),
    );
  }
}

class LockCounterRow extends StatelessWidget {
  const LockCounterRow({super.key, required this.title, required this.value, required this.min, required this.max, required this.onChanged});
  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final safe = value.clamp(min, max);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: .7))),
          _RoundControl(icon: Icons.remove_rounded, enabled: safe > min, onTap: () => onChanged(safe - 1)),
          SizedBox(width: 38, child: Text('$safe', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900))),
          _RoundControl(icon: Icons.add_rounded, enabled: safe < max, onTap: () => onChanged(safe + 1)),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.enabled, required this.onTap});
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: enabled ? onTap : () {},
      haptic: HapticFeedbackType.selection,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: enabled ? .22 : .07),
          border: Border.all(color: Colors.white.withValues(alpha: enabled ? .42 : .10)),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: enabled ? .95 : .22), size: 22),
      ),
    );
  }
}

class CardAsset extends StatelessWidget {
  const CardAsset({super.key, required this.assetPath, required this.fallbackColor, this.compact = false, this.title = 'MAFIA'});
  final String assetPath;
  final MafiaPlayingCardColor fallbackColor;
  final bool compact;
  final String title;

  @override
  Widget build(BuildContext context) {
    // Jeśli pubspec wpisuje folder jako `assets/images/card/`, web URL będzie wyglądał jak `assets/assets/images/card/...` — to jest poprawne.
    // Fallback zostaje na wypadek starego wpisu bez prefiksu assets.
    final alt = assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Image.asset(
        alt,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => MafiaPlayingCard(color: fallbackColor, compact: compact, title: title),
      ),
    );
  }
}

class IOSGlass extends StatelessWidget {
  const IOSGlass({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = 22, this.opacity = .085, this.blur = 22, this.borderOpacity = .18});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;
  final double blur;
  final double borderOpacity;
  @override
  Widget build(BuildContext context) => LockGlassPanel(padding: padding, radius: radius, opacity: opacity, child: child);
}

class IOSBackButton extends StatelessWidget {
  const IOSBackButton({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PressableScale(onTap: onTap, haptic: HapticFeedbackType.selection, child: const SizedBox(width: 50, height: 50, child: Icon(Icons.chevron_left_rounded, color: AppColors.white, size: 38)));
}

class BigIOSClock extends StatelessWidget {
  const BigIOSClock({super.key, this.subtitle, this.compact = false});
  final String? subtitle;
  final bool compact;
  @override
  Widget build(BuildContext context) => LockClock(subtitle: subtitle);
}

class IOSNotificationTile extends StatelessWidget {
  const IOSNotificationTile({super.key, required this.title, required this.subtitle, required this.onTap, required this.trailingIcon, this.assetPath = MafiaAssets.redCard});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData trailingIcon;
  final String assetPath;
  @override
  Widget build(BuildContext context) => LockNotificationTile(title: title, subtitle: subtitle, onTap: onTap, trailingIcon: trailingIcon, assetPath: assetPath);
}

class IOSAppIcon extends StatelessWidget {
  const IOSAppIcon({super.key, required this.label, required this.icon, required this.onTap, this.badge = 0, this.isPremium = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final bool isPremium;
  @override
  Widget build(BuildContext context) {
    final size = Responsive.isSmall(context) ? 62.0 : 70.0;
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: .92,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .11), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .16))),
                child: Icon(icon, color: isPremium ? AppColors.goldAccent : AppColors.white, size: size * .58),
              ),
            ),
          ),
          if (badge > 0) Positioned(right: -5, top: -6, child: Container(width: 21, height: 21, alignment: Alignment.center, decoration: const BoxDecoration(color: AppColors.redAccent, shape: BoxShape.circle), child: Text(badge > 9 ? '9+' : badge.toString(), style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w900)))),
        ]),
        const SizedBox(height: 6),
        SizedBox(width: 82, child: Text(label.toLowerCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w900, shadows: [Shadow(color: AppColors.shadow, blurRadius: 8)]))),
      ]),
    );
  }
}

class IOSCardIcon extends StatelessWidget {
  const IOSCardIcon({super.key, required this.label, required this.assetPath, required this.color, required this.onTap});
  final String label;
  final String assetPath;
  final MafiaPlayingCardColor color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final w = Responsive.isSmall(context) ? 128.0 : 146.0;
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: .94,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(borderRadius: BorderRadius.circular(18), child: SizedBox(width: w, height: w * 1.08, child: CardAsset(assetPath: assetPath, fallbackColor: color, compact: true))),
        const SizedBox(height: 7),
        Text(label.toLowerCase(), style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w900, shadows: [Shadow(color: AppColors.shadow, blurRadius: 8)])),
      ]),
    );
  }
}

class NumericPinPad extends StatelessWidget {
  const NumericPinPad({super.key, required this.onDigit, required this.onBackspace});
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  @override
  Widget build(BuildContext context) {
    final rows = const [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ...rows.map((row) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row.map((d) => _PinKey(value: d, onTap: () => onDigit(d))).toList()))),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        const SizedBox(width: 72, height: 72),
        _PinKey(value: '0', onTap: () => onDigit('0')),
        _PinKey(icon: Icons.backspace_outlined, onTap: onBackspace),
      ]),
    ]);
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({this.value, this.icon, required this.onTap});
  final String? value;
  final IconData? icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => PressableScale(
    onTap: onTap,
    haptic: HapticFeedbackType.selection,
    pressedScale: .90,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .16))),
          child: icon == null ? Text(value!, style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w900)) : Icon(icon, color: AppColors.white, size: 27),
        ),
      ),
    ),
  );
}
