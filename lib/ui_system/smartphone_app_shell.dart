import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../models/game_phase.dart';
import '../widgets/shared_widgets.dart';

class PhoneAppDefinition {
  const PhoneAppDefinition({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.builder,
    this.badge = 0,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final int badge;
  final WidgetBuilder builder;
}

class PhoneHomeScreen extends StatefulWidget {
  const PhoneHomeScreen({
    super.key,
    required this.phase,
    required this.apps,
    required this.onMenu,
  });

  final GamePhase phase;
  final List<PhoneAppDefinition> apps;
  final VoidCallback onMenu;

  @override
  State<PhoneHomeScreen> createState() => _PhoneHomeScreenState();
}

class _PhoneHomeScreenState extends State<PhoneHomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController parallaxController;

  @override
  void initState() {
    super.initState();
    parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    parallaxController.dispose();
    super.dispose();
  }

  String phaseName(GamePhase phase) {
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
        return 'Koniec';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: parallaxController,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(parallaxController.value);
        final offset = Offset((value - 0.5) * 18, (0.5 - value) * 10);
        return Scaffold(
          body: MafiaCityBackground(
            darkOverlay: 0.10,
            blur: 0.0,
            parallaxOffset: offset,
            child: SafeArea(
              child: PageView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _HomePage(
                    phaseLabel: phaseName(widget.phase),
                    apps: widget.apps,
                    onMenu: widget.onMenu,
                  ),
                  _QuickPanelPage(phaseLabel: phaseName(widget.phase)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.phaseLabel,
    required this.apps,
    required this.onMenu,
  });

  final String phaseLabel;
  final List<PhoneAppDefinition> apps;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 12,
      ),
      child: Column(
        children: [
          PhoneStatusBar(phaseLabel: phaseLabel, onMenu: onMenu),
          const SizedBox(height: 24),
          const PremiumFadeSlide(
            delay: Duration(milliseconds: 40),
            child: DashboardHeader(showMoon: true),
          ),
          SizedBox(height: Responsive.isSmall(context) ? 24 : 34),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
                child: _PhoneAppGrid(apps: apps),
              ),
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    );
  }
}

class PhoneStatusBar extends StatelessWidget {
  const PhoneStatusBar({super.key, required this.phaseLabel, required this.onMenu});

  final String phaseLabel;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const Expanded(
                child: MafiaClockText(fontSize: 24, align: TextAlign.left),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  phaseLabel.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                onTap: onMenu,
                haptic: HapticFeedbackType.medium,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.home_rounded, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneAppGrid extends StatelessWidget {
  const _PhoneAppGrid({required this.apps});
  final List<PhoneAppDefinition> apps;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: apps.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isSmall(context) ? 3 : 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final app = apps[index];
        return PremiumFadeSlide(
          delay: Duration(milliseconds: 45 * index),
          offset: const Offset(0, 18),
          child: PhoneAppIcon(app: app),
        );
      },
    );
  }
}

class PhoneAppIcon extends StatefulWidget {
  const PhoneAppIcon({super.key, required this.app});
  final PhoneAppDefinition app;

  @override
  State<PhoneAppIcon> createState() => _PhoneAppIconState();
}

class _PhoneAppIconState extends State<PhoneAppIcon> {
  bool jiggle = false;

  void openApp() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(_PhoneAppRoute(app: widget.app));
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: openApp,
      haptic: HapticFeedbackType.medium,
      pressedScale: 0.92,
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          setState(() => jiggle = !jiggle);
        },
        child: AnimatedRotation(
          turns: jiggle ? 0.01 : 0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Hero(
                    tag: 'phone_app_${widget.app.id}',
                    child: Container(
                      width: Responsive.isSmall(context) ? 66 : 74,
                      height: Responsive.isSmall(context) ? 66 : 74,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.app.color.withValues(alpha: 0.94),
                            widget.app.color.withValues(alpha: 0.52),
                            Colors.black.withValues(alpha: 0.48),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: widget.app.color.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                          const BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 14,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(widget.app.icon, color: AppColors.white, size: 34),
                    ),
                  ),
                  if (widget.app.badge > 0)
                    Positioned(
                      right: -4,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: const BoxDecoration(color: AppColors.redAccent, shape: BoxShape.circle),
                        child: Text(
                          widget.app.badge > 9 ? '9+' : widget.app.badge.toString(),
                          style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.app.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneAppRoute extends PageRouteBuilder<void> {
  _PhoneAppRoute({required PhoneAppDefinition app})
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          pageBuilder: (context, animation, secondaryAnimation) => PhoneAppContainer(app: app),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        );
}

class PhoneAppContainer extends StatelessWidget {
  const PhoneAppContainer({super.key, required this.app});
  final PhoneAppDefinition app;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${app.id}'),
      direction: DismissDirection.down,
      resizeDuration: null,
      onDismissed: (_) => Navigator.of(context).maybePop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: MafiaCityBackground(
          darkOverlay: 0.16,
          blur: 0.2,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context), vertical: 14),
              child: Column(
                children: [
                  _AppHeader(app: app),
                  SizedBox(height: Responsive.isSmall(context) ? 12 : 16),
                  Expanded(
                    child: Hero(
                      tag: 'phone_app_${app.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.glassDark.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: app.builder(context),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _HomeIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.app});
  final PhoneAppDefinition app;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PressableScale(
          onTap: () => Navigator.pop(context),
          haptic: HapticFeedbackType.selection,
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.white, size: 34),
          ),
        ),
        const SizedBox(width: 8),
        Icon(app.icon, color: AppColors.white, size: 25),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            app.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}

class _QuickPanelPage extends StatelessWidget {
  const _QuickPanelPage({required this.phaseLabel});
  final String phaseLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Column(
        children: [
          PhoneStatusBar(phaseLabel: phaseLabel, onMenu: () => Navigator.popUntil(context, (route) => route.isFirst)),
          const SizedBox(height: 24),
          MafiaPanel(
            child: Text(
              'Panel szybkich akcji pojawi się tutaj. Przesuń w bok, aby wrócić do aplikacji.',
              style: TextStyle(color: AppColors.white.withValues(alpha: 0.78), fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 5,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
