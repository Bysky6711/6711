import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../widgets/shared_widgets.dart';
import '../models/game_phase.dart';

class MafiaPhoneAssets {
  const MafiaPhoneAssets._();

  // Jeśli Twoje pliki w assets mają inne nazwy, zmień tylko te ścieżki.
  static const String redCard = 'assets/images/cards/mafia_red.png';
  static const String blueCard = 'assets/images/cards/mafia_blue.png';
  static const String powerCard = 'assets/images/cards/power_blue.png';
}

class MafiaPhoneBackground extends StatefulWidget {
  const MafiaPhoneBackground({
    super.key,
    required this.child,
    this.darkOverlay = 0.08,
    this.enableParallax = true,
  });

  final Widget child;
  final double darkOverlay;
  final bool enableParallax;

  @override
  State<MafiaPhoneBackground> createState() => _MafiaPhoneBackgroundState();
}

class _MafiaPhoneBackgroundState extends State<MafiaPhoneBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        final motion = widget.enableParallax
            ? math.sin(controller.value * math.pi * 2)
            : 0.0;
        return MafiaCityBackground(
          darkOverlay: widget.darkOverlay,
          blur: 0,
          parallaxOffset: Offset(motion * 10, -motion * 5),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        AppColors.cityGlowRed.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.56),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.38, 0.77, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: widget.child),
            ],
          ),
        );
      },
    );
  }
}

class MafiaBigClock extends StatelessWidget {
  const MafiaBigClock({super.key, this.topPadding = 40, this.subtitle});

  final double topPadding;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final size = Responsive.clamp(Responsive.width(context) * 0.23, 76, 112);
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          MafiaClockText(fontSize: size),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.88),
                fontSize: Responsive.isSmall(context) ? 15 : 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MafiaGlassCard extends StatelessWidget {
  const MafiaGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 14,
    this.opacity = 0.72,
    this.blur = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassWhite.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class MafiaMenuTile extends StatelessWidget {
  const MafiaMenuTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.leadingAsset = MafiaPhoneAssets.redCard,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String leadingAsset;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: 0.975,
      child: MafiaGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 44,
                height: 44,
                child: MafiaCardAsset(
                  assetPath: leadingAsset,
                  fallbackColor: MafiaPhoneAssets.redCard == leadingAsset
                      ? MafiaPlayingCardColor.red
                      : MafiaPlayingCardColor.blue,
                  compact: true,
                  title: 'M',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.black.withValues(alpha: 0.82),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(icon, color: AppColors.black, size: 18),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class MafiaInputPanel extends StatelessWidget {
  const MafiaInputPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.hint,
    required this.onSubmit,
    this.icon = Icons.arrow_upward_rounded,
  });

  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmit;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MafiaGlassCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: MafiaCardAsset(
                    assetPath: MafiaPhoneAssets.redCard,
                    fallbackColor: MafiaPlayingCardColor.red,
                    compact: true,
                    title: 'M',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.black.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            height: 48,
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '...',
                      hintStyle: TextStyle(
                        color: AppColors.black.withValues(alpha: 0.42),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                PressableScale(
                  onTap: onSubmit,
                  haptic: HapticFeedbackType.medium,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.white, size: 25),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MafiaPhoneIconButton extends StatefulWidget {
  const MafiaPhoneIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  @override
  State<MafiaPhoneIconButton> createState() => _MafiaPhoneIconButtonState();
}

class _MafiaPhoneIconButtonState extends State<MafiaPhoneIconButton> {
  bool editMode = false;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: 0.92,
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() => editMode = !editMode);
        },
        child: AnimatedRotation(
          turns: editMode ? 0.012 : 0,
          duration: const Duration(milliseconds: 130),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: Responsive.isSmall(context) ? 58 : 66,
                    height: Responsive.isSmall(context) ? 58 : 66,
                    decoration: BoxDecoration(
                      color: AppColors.black,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.white,
                      size: Responsive.isSmall(context) ? 36 : 42,
                    ),
                  ),
                  if (widget.badge > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          widget.badge > 9 ? '9+' : widget.badge.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 76,
                child: Text(
                  widget.label.toLowerCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
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

class MafiaPhoneCardButton extends StatelessWidget {
  const MafiaPhoneCardButton({
    super.key,
    required this.label,
    required this.assetPath,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final MafiaPlayingCardColor color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = Responsive.isSmall(context) ? 126.0 : 146.0;
    return PressableScale(
      onTap: onTap,
      haptic: HapticFeedbackType.medium,
      pressedScale: 0.94,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: width,
              height: width * 1.10,
              child: MafiaCardAsset(
                assetPath: assetPath,
                fallbackColor: color,
                compact: true,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label.toLowerCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: AppColors.shadow, blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

class MafiaCardAsset extends StatelessWidget {
  const MafiaCardAsset({
    super.key,
    required this.assetPath,
    required this.fallbackColor,
    this.compact = false,
    this.title = 'MAFIA',
  });

  final String assetPath;
  final MafiaPlayingCardColor fallbackColor;
  final bool compact;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return MafiaPlayingCard(
          color: fallbackColor,
          compact: compact,
          title: title,
        );
      },
    );
  }
}

class MafiaPhoneScaffold extends StatelessWidget {
  const MafiaPhoneScaffold({
    super.key,
    required this.child,
    this.darkOverlay = 0.08,
  });

  final Widget child;
  final double darkOverlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaPhoneBackground(
        darkOverlay: darkOverlay,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String mafiaPhaseLabel(GamePhase phase) {
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
