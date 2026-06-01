import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'roles.dart';


class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({
    super.key,
    required this.roleType,
    this.imagePath,
  });

  final MafiaRoleCardType roleType;
  final String? imagePath;

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flipAnimation;

  bool cardRevealed = false;

  static const String backgroundPath = 'assets/images/backgrounds/miasto.jpg';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _flipAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void revealCard() {
    if (cardRevealed) return;

    setState(() {
      cardRevealed = true;
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _CardBackground(
        backgroundPath: backgroundPath,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.sizeOf(context).width;
              final small = width < 390;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: width < 360 ? 12 : 18,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 520,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: _CardColors.neonWhite,
                                    size: 21,
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),

                          SizedBox(height: small ? 44 : 62),

                          Text(
                            'Twoja karta',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: small ? 38 : 48,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.3,
                              shadows: const [
                                Shadow(
                                  color: Colors.white,
                                  blurRadius: 5,
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 12,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            cardRevealed
                                ? 'Zapamiętaj kartę i nie pokazuj jej innym.'
                                : 'Dotknij karty, aby ją odkryć.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white70,
                              fontSize: small ? 19 : 23,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.8,
                            ),
                          ),

                          SizedBox(height: small ? 42 : 56),

                          GestureDetector(
                            onTap: revealCard,
                            child: AnimatedBuilder(
                              animation: _flipAnimation,
                              builder: (context, child) {
                                final angle = _flipAnimation.value * math.pi;
                                final showFront = angle > math.pi / 2;

                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0012)
                                    ..rotateY(angle),
                                  child: showFront
                                      ? Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..rotateY(math.pi),
                                          child: _RoleCardFront(
                                            roleType: widget.roleType,
                                            imagePath: widget.imagePath,
                                          ),
                                        )
                                      : const _RoleCardBack(),
                                );
                              },
                            ),
                          ),

                          SizedBox(height: small ? 42 : 56),

                          if (!cardRevealed)
                            _CardButton(
                              text: 'Odkryj kartę',
                              icon: Icons.visibility_rounded,
                              onPressed: revealCard,
                            )
                          else
                            _CardButton(
                              text: 'Gotowe',
                              icon: Icons.check_rounded,
                              onPressed: () => Navigator.pop(context),
                            ),
                        ],
                      ),
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

class _CardBackground extends StatelessWidget {
  const _CardBackground({
    required this.child,
    required this.backgroundPath,
  });

  final Widget child;
  final String backgroundPath;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundPath,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.96),
                  Colors.black.withValues(alpha: 0.80),
                  _CardColors.deepRed.withValues(alpha: 0.78),
                  _CardColors.deepRed.withValues(alpha: 0.94),
                ],
                stops: const [
                  0.00,
                  0.36,
                  0.72,
                  1.00,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class _RoleCardBack extends StatelessWidget {
  const _RoleCardBack();

  @override
  Widget build(BuildContext context) {
    return const _CardFrame(
      child: _FullBackCardImage(),
    );
  }
}

class _FullBackCardImage extends StatelessWidget {
  const _FullBackCardImage();

  static const String cardBackPath = 'assets/images/card/card_back_red.jpg';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          cardBackPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),

        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.92,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.34),
              ],
              stops: const [
                0.45,
                0.78,
                1.00,
              ],
            ),
          ),
        ),

        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.12),
              ],
              stops: const [
                0.00,
                0.42,
                1.00,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleCardFront extends StatelessWidget {
  const _RoleCardFront({
    required this.roleType,
    this.imagePath,
  });

  final MafiaRoleCardType roleType;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black.withValues(alpha: 0.28),
          ),

          if (imagePath == null)
            CustomPaint(
              painter: _RolePlaceholderPainter(
                roleType: roleType,
              ),
            )
          else
            Image.asset(
              imagePath!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.95,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.26),
                ],
                stops: const [
                  0.45,
                  0.78,
                  1.00,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(width * 0.76, 320.0);
    final cardHeight = cardWidth * 1.48;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFF4B8).withValues(alpha: 0.98),
            const Color(0xFF9E7A2E).withValues(alpha: 0.98),
            const Color(0xFFFFE8A3).withValues(alpha: 0.96),
            const Color(0xFF3D2412).withValues(alpha: 1.00),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.82),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xFFFFE8A3).withValues(alpha: 0.16),
            blurRadius: 26,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(31),
            color: const Color(0xFF130705),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.92),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: const Color(0xFF210A07),
                border: Border.all(
                  color: const Color(0xFFFFF0B0).withValues(alpha: 0.78),
                  width: 1.4,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.25,
                        colors: [
                          _CardColors.deepRed.withValues(alpha: 0.62),
                          Colors.black.withValues(alpha: 0.42),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),

                  child,

                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 18,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                  ),

                  IgnorePointer(
                    child: CustomPaint(
                      painter: _CardBorderPainter(),
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
}

class _RolePlaceholderPainter extends CustomPainter {
  const _RolePlaceholderPainter({
    required this.roleType,
  });

  final MafiaRoleCardType roleType;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = _roleColor(roleType).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = _CardColors.neonWhite.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = _roleColor(roleType).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, size.width * 0.34, basePaint);
    canvas.drawCircle(center, size.width * 0.34, glowPaint);
    canvas.drawCircle(center, size.width * 0.34, strokePaint);

    final iconPath = _iconPath(size, roleType);

    canvas.drawPath(iconPath, glowPaint);
    canvas.drawPath(iconPath, strokePaint);
  }

  
Path _iconPath(Size size, MafiaRoleCardType roleType) {
  switch (roleType) {
    case MafiaRoleCardType.host:
      return _hostPath(size);
    case MafiaRoleCardType.mafia:
      return _hatPath(size);
    case MafiaRoleCardType.detective:
      return _magnifierPath(size);
    case MafiaRoleCardType.doctor:
      return _crossPath(size);
    case MafiaRoleCardType.sheriff:
      return _sheriffPath(size);
    case MafiaRoleCardType.citizen:
      return _personPath(size);
  }
}


  Path _hostPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.30, h * 0.56)
      ..lineTo(w * 0.70, h * 0.56)
      ..moveTo(w * 0.36, h * 0.56)
      ..lineTo(w * 0.42, h * 0.38)
      ..lineTo(w * 0.50, h * 0.50)
      ..lineTo(w * 0.58, h * 0.38)
      ..lineTo(w * 0.64, h * 0.56)
      ..moveTo(w * 0.42, h * 0.63)
      ..lineTo(w * 0.58, h * 0.63);
  }

  Path _hatPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.25, h * 0.58)
      ..quadraticBezierTo(w * 0.50, h * 0.66, w * 0.75, h * 0.58)
      ..moveTo(w * 0.36, h * 0.55)
      ..lineTo(w * 0.38, h * 0.38)
      ..quadraticBezierTo(w * 0.50, h * 0.31, w * 0.62, h * 0.38)
      ..lineTo(w * 0.64, h * 0.55)
      ..moveTo(w * 0.39, h * 0.49)
      ..lineTo(w * 0.61, h * 0.49);
  }

  Path _magnifierPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(w * 0.46, h * 0.46),
          radius: w * 0.13,
        ),
      )
      ..moveTo(w * 0.56, h * 0.56)
      ..lineTo(w * 0.70, h * 0.70);
  }

  Path _crossPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(w * 0.50, h * 0.34)
      ..lineTo(w * 0.50, h * 0.68)
      ..moveTo(w * 0.34, h * 0.51)
      ..lineTo(w * 0.66, h * 0.51);
  }
  Path _sheriffPath(Size size) {
  final w = size.width;
  final h = size.height;

  final path = Path();

  final centerX = w * 0.50;
  final centerY = h * 0.52;
  final outerRadius = w * 0.20;
  final innerRadius = w * 0.085;

  for (int i = 0; i < 12; i++) {
    final angle = -math.pi / 2 + i * math.pi / 6;
    final radius = i.isEven ? outerRadius : innerRadius;

    final x = centerX + math.cos(angle) * radius;
    final y = centerY + math.sin(angle) * radius;

    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }

  path.close();

  path.moveTo(w * 0.42, h * 0.52);
  path.lineTo(w * 0.58, h * 0.52);

  path.moveTo(w * 0.50, h * 0.44);
  path.lineTo(w * 0.50, h * 0.60);

  return path;
}

  Path _personPath(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(w * 0.50, h * 0.43),
          radius: w * 0.095,
        ),
      )
      ..moveTo(w * 0.34, h * 0.70)
      ..quadraticBezierTo(w * 0.50, h * 0.56, w * 0.66, h * 0.70);
  }

  Color _roleColor(MafiaRoleCardType roleType) {
    switch (roleType) {
      case MafiaRoleCardType.host:
        return const Color(0xFFF8F4E8);
      case MafiaRoleCardType.mafia:
        return const Color(0xFFB00000);
      case MafiaRoleCardType.detective:
        return const Color(0xFF4DA3FF);
      case MafiaRoleCardType.doctor:
        return const Color(0xFF55FF99);  
      case MafiaRoleCardType.sheriff:
      return const Color(0xFFFFD54F);
      case MafiaRoleCardType.citizen:
        return const Color(0xFFD8D8D8);
    }
  }

  @override
  bool shouldRepaint(covariant _RolePlaceholderPainter oldDelegate) {
    return oldDelegate.roleType != roleType;
  }
}

class _CardBorderPainter extends CustomPainter {
  const _CardBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF5B8),
          Color(0xFFFFD95A),
          Color(0xFF9D6A16),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softGoldPaint = Paint()
      ..color = const Color(0xFFFFE27A).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final thinPaint = Paint()
      ..color = const Color(0xFFFFF0B0).withValues(alpha: 0.54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outerRect = Rect.fromLTWH(
      10,
      10,
      size.width - 20,
      size.height - 20,
    );

    final innerRect = Rect.fromLTWH(
      18,
      18,
      size.width - 36,
      size.height - 36,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        outerRect,
        const Radius.circular(22),
      ),
      softGoldPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        outerRect,
        const Radius.circular(22),
      ),
      goldPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        innerRect,
        const Radius.circular(17),
      ),
      thinPaint,
    );

    void drawCorner({
      required bool right,
      required bool bottom,
    }) {
      final x = right ? size.width - 30 : 30.0;
      final y = bottom ? size.height - 30 : 30.0;

      final sx = right ? -1.0 : 1.0;
      final sy = bottom ? -1.0 : 1.0;

      final path = Path()
        ..moveTo(x, y + sy * 26)
        ..quadraticBezierTo(
          x + sx * 2,
          y + sy * 8,
          x + sx * 18,
          y + sy * 2,
        )
        ..moveTo(x, y + sy * 26)
        ..lineTo(x + sx * 10, y + sy * 18)
        ..moveTo(x + sx * 18, y + sy * 2)
        ..lineTo(x + sx * 26, y);

      canvas.drawPath(path, softGoldPaint);
      canvas.drawPath(path, goldPaint);
    }

    drawCorner(right: false, bottom: false);
    drawCorner(right: true, bottom: false);
    drawCorner(right: false, bottom: true);
    drawCorner(right: true, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _CardBorderPainter oldDelegate) {
    return false;
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.sizeOf(context).width < 390;

    return SizedBox(
      width: math.min(MediaQuery.sizeOf(context).width - 36, 380),
      height: small ? 52 : 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.58),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: const BorderSide(
            color: _CardColors.frame,
            width: 1.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: _CardColors.neonWhite,
                size: small ? 20 : 22,
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text.toUpperCase(),
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: small ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 5,
                      ),
                      Shadow(
                        color: Colors.black,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardColors {
  static const Color neonWhite = Color(0xFFF8F4E8);
  static const Color frame = Color(0xCCF8F4E8);
  static const Color deepRed = Color(0xFF4A0500);
}
