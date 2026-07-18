import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/edition_state.dart';
import '../core/responsive.dart';
import '../models/game_edition.dart';
import '../models/game_phase.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/animated_new_background.dart';

// ─────────────────────────────────────────────────────────────────────────
// One UI (Samsung) design tokens — solid surfaces, soft rounding, red accent.
// (The class/widget names below are kept for backwards-compat with screens.)
// ─────────────────────────────────────────────────────────────────────────
const Color kOneSurface = Color(0xFF241619);
const Color kOneSurfaceHigh = Color(0xFF33221F);
const Color kOneAccent = Color(0xFFE5404F);
const Color kOneStroke = Color(0x1FFFFFFF);
const Color kOneDim = Color(0xB3FFFFFF);

class MafiaAssets {
  const MafiaAssets._();

  static const String defaultCard = 'assets/images/card/1.jpg';
  static const String mafiaClassCard = 'assets/images/card/card_class_mafia.jpg';
  static const String redCard = defaultCard;
  static const String blueCard = defaultCard;
  static const String powerCard = defaultCard;
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

/// App scaffold with the animated background and a faux phone status bar on top,
/// which gives every screen the "real smartphone" feel (One UI).
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
        child: SafeArea(
          child: Column(
            children: [
              const _OneUiStatusBar(),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final medieval = activeEdition.isMedieval;
    return AnimatedNewBackground(
      darkOverlay: darkOverlay,
      rain: medieval ? false : rain,
      assetPath: medieval
          ? 'assets/images/backgrounds/medieval_background.jpg'
          : 'assets/images/backgrounds/new_background.jpg',
      glowColors: medieval
          ? const [Color(0xFF7A1F2B), Color(0xFFC9A227)]
          : const [Color(0xFF7A0E14), Color(0xFFD62330)],
      child: child,
    );
  }
}

class _OneUiStatusBar extends StatelessWidget {
  const _OneUiStatusBar();

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final time = '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 18, 2),
      child: Row(
        children: [
          Text(time, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: .3)),
          const Spacer(),
          Icon(Icons.signal_cellular_alt_rounded, color: AppColors.white.withValues(alpha: .9), size: 15),
          const SizedBox(width: 6),
          Icon(Icons.wifi_rounded, color: AppColors.white.withValues(alpha: .9), size: 15),
          const SizedBox(width: 6),
          Icon(Icons.battery_full_rounded, color: AppColors.white.withValues(alpha: .9), size: 16),
        ],
      ),
    );
  }
}

/// Big One UI-style header: the game wordmark + optional title underneath.
class LockClock extends StatelessWidget {
  const LockClock({super.key, this.subtitle});
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mafia',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: Responsive.clamp(Responsive.width(context) * .18, 54, 84),
            fontWeight: FontWeight.w900,
            height: .95,
            letterSpacing: 2,
            shadows: const [Shadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(2, 4))],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kOneDim, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}

/// Confirmation dialog shown before leaving a room / game.
Future<bool> confirmExitGame(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kOneSurfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Wyjść z gry?', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
      content: const Text('Opuścisz pokój i wrócisz do menu głównego.', style: TextStyle(color: kOneDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Zostań', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Wyjdź', style: TextStyle(color: kOneAccent, fontWeight: FontWeight.w900))),
      ],
    ),
  );
  return result ?? false;
}

/// One UI card surface (solid, softly rounded, gentle shadow — no glass blur).
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: kOneSurface,
        borderRadius: BorderRadius.circular(radius < 22 ? 24 : radius),
        border: Border.all(color: kOneStroke),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: child,
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
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: .985,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: kOneSurfaceHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kOneStroke),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kOneAccent.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(trailingIcon ?? Icons.bolt_rounded, color: kOneAccent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 18, height: 1.05, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kOneDim, fontSize: 13, height: 1.1, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.white.withValues(alpha: .5), size: 24),
          ],
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
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w700),
      cursorColor: kOneAccent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.white.withValues(alpha: .40), fontWeight: FontWeight.w600),
        filled: true,
        fillColor: kOneSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kOneStroke)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: kOneStroke)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kOneAccent, width: 1.6)),
      ),
    );
  }
}

/// One UI filled button. [light] = solid accent (primary), else tonal surface.
class LockButton extends StatelessWidget {
  const LockButton({super.key, required this.text, required this.onTap, this.icon, this.light = false});
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Colors.white : AppColors.white;
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: .97,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: light ? kOneAccent : kOneSurfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: light ? null : Border.all(color: kOneStroke),
          boxShadow: light
              ? [BoxShadow(color: kOneAccent.withValues(alpha: .36), blurRadius: 18, offset: const Offset(0, 8))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: .2))),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kOneSurfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOneStroke),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w700))),
          _RoundControl(icon: Icons.remove_rounded, enabled: safe > min, onTap: () => onChanged(safe - 1)),
          SizedBox(width: 40, child: Text('$safe', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800))),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? kOneAccent.withValues(alpha: .20) : Colors.white.withValues(alpha: .05),
          border: Border.all(color: enabled ? kOneAccent.withValues(alpha: .55) : Colors.white.withValues(alpha: .10)),
        ),
        child: Icon(icon, color: enabled ? kOneAccent : Colors.white.withValues(alpha: .22), size: 22),
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
    final alt = assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => Image.asset(
        alt,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => MafiaPlayingCard(color: fallbackColor, compact: compact, title: title),
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
  Widget build(BuildContext context) => PressableScale(
        onTap: onTap,
        haptic: HapticFeedbackType.selection,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kOneSurfaceHigh,
            shape: BoxShape.circle,
            border: Border.all(color: kOneStroke),
          ),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 24),
        ),
      );
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

/// One UI squircle app icon.
class IOSAppIcon extends StatelessWidget {
  const IOSAppIcon({super.key, required this.label, required this.icon, required this.onTap, this.badge = 0, this.isPremium = false, this.tint});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final bool isPremium;
  final Color? tint;
  @override
  Widget build(BuildContext context) {
    final size = Responsive.isSmall(context) ? 62.0 : 70.0;
    final tintColor = isPremium ? AppColors.goldAccent : (tint ?? kOneAccent);
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: .92,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tintColor.withValues(alpha: .34), kOneSurfaceHigh],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kOneStroke),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .30), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Icon(icon, color: isPremium ? AppColors.goldAccent : AppColors.white, size: size * .5),
          ),
          if (badge > 0)
            Positioned(
              right: -5,
              top: -6,
              child: Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: kOneAccent, shape: BoxShape.circle),
                child: Text(badge > 9 ? '9+' : badge.toString(), style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ),
        ]),
        const SizedBox(height: 7),
        SizedBox(width: 82, child: Text(label.toLowerCase(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700, shadows: [Shadow(color: AppColors.shadow, blurRadius: 8)]))),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(width: w, height: w * 1.08, child: CardAsset(assetPath: assetPath, fallbackColor: color, compact: true)),
        ),
        const SizedBox(height: 7),
        Text(label.toLowerCase(), style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700, shadows: [Shadow(color: AppColors.shadow, blurRadius: 8)])),
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
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: kOneSurfaceHigh, shape: BoxShape.circle, border: Border.all(color: kOneStroke)),
          child: icon == null ? Text(value!, style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w800)) : Icon(icon, color: AppColors.white, size: 27),
        ),
      );
}
