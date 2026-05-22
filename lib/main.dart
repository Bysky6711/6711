import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  static const Color neonWhite = Color(0xFFF8F4E8);
  static const Color redDark = Color(0xFF7A0C0C);
  static const Color redLight = Color(0xFFB82222);
}

class Responsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isVerySmall(BuildContext context) => width(context) < 350;

  static bool isSmall(BuildContext context) => width(context) < 390;

  static double clamp(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }

  static double horizontalPadding(BuildContext context) {
    final w = width(context);

    if (w < 360) return 12;
    if (w < 600) return 18;
    return 24;
  }

  static double mainTitleSize(BuildContext context) {
    final w = width(context);
    return clamp(w * 0.24, 62, 120);
  }

  static double screenTitleSize(BuildContext context) {
    final w = width(context);
    return clamp(w * 0.18, 48, 88);
  }

  static double buttonWidth(BuildContext context) {
    final w = width(context);
    return math.min(w - (horizontalPadding(context) * 2), 380);
  }

  static double contentMaxWidth(BuildContext context) {
    final w = width(context);

    if (w >= 900) return 520;
    if (w >= 600) return 500;
    return double.infinity;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mafia',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.neonWhite,
            disabledForegroundColor: Colors.white24,
          ),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// MAIN MENU
// -----------------------------------------------------------------------------

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaBackground(
        overlayAlpha: 0.45,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth(context),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          NeonMafiaTitle(
                            fontSize: Responsive.mainTitleSize(context),
                          ),

                          const SizedBox(height: 10),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Work in progress',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fondamento(
                                fontSize: Responsive.isSmall(context) ? 22 : 28,
                                color: Colors.white,
                                letterSpacing: 2,
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

                          SizedBox(
                            height: Responsive.isSmall(context) ? 32 : 48,
                          ),

                          MafiaButton(
                            text: 'HOSTUJ',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HostGameScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          MafiaButton(
                            text: 'DOŁĄCZ DO GRY',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JoinGameScreen(),
                                ),
                              );
                            },
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

// -----------------------------------------------------------------------------
// HOST GAME SCREEN
// -----------------------------------------------------------------------------

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  final TextEditingController hostNameController = TextEditingController();

  int players = 6;
  int mafia = 1;
  int detective = 1;
  int doctor = 1;

  int get specialRoles => mafia + detective + doctor;

  int get citizens => players - specialRoles;

  bool get isValid => citizens >= 0;

  @override
  void dispose() {
    hostNameController.dispose();
    super.dispose();
  }

  void setPlayers(int value) {
    setState(() {
      players = value;

      if (specialRoles > players) {
        final overflow = specialRoles - players;

        if (doctor >= overflow) {
          doctor -= overflow;
        } else if (detective >= overflow - doctor) {
          final rest = overflow - doctor;
          doctor = 0;
          detective -= rest;
        } else {
          final rest = overflow - doctor - detective;
          doctor = 0;
          detective = 0;
          mafia = math.max(1, mafia - rest);
        }
      }
    });
  }

  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random();

    return List.generate(
      5,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void createRoom() {
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfiguracja gry jest niepoprawna.'),
        ),
      );
      return;
    }

    final hostName = hostNameController.text.trim().isEmpty
        ? 'Host'
        : hostNameController.text.trim();

    final roomCode = generateRoomCode();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(
              color: AppColors.neonWhite,
              width: 1.4,
            ),
          ),
          title: Text(
            'Pokój utworzony',
            style: GoogleFonts.cinzel(
              color: AppColors.neonWhite,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: const [
                Shadow(
                  color: Colors.white,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Host: $hostName',
                textAlign: TextAlign.center,
                style: GoogleFonts.fondamento(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Kod pokoju:',
                style: GoogleFonts.cinzel(
                  color: Colors.white70,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                roomCode,
                textAlign: TextAlign.center,
                style: GoogleFonts.rubikDistressed(
                  color: AppColors.neonWhite,
                  fontSize: 42,
                  letterSpacing: 4,
                  shadows: const [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 8,
                    ),
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Na razie jest to lokalny ekran testowy. Później podepniemy prawdziwe lobby online.',
                textAlign: TextAlign.center,
                style: GoogleFonts.fondamento(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.cinzel(
                  color: AppColors.neonWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaBackground(
        overlayAlpha: 0.48,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth(context),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MafiaTopBar(
                            title: 'HOSTOWANIE',
                            onBack: () => Navigator.pop(context),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 16 : 24,
                          ),

                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ustawienia pokoju',
                                  style: GoogleFonts.cinzel(
                                    color: AppColors.neonWhite,
                                    fontSize:
                                        Responsive.isSmall(context) ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                MafiaTextField(
                                  controller: hostNameController,
                                  label: 'Nazwa hosta',
                                  hint: 'np. Wiktor',
                                ),

                                const SizedBox(height: 22),

                                CounterSetting(
                                  title: 'Liczba graczy',
                                  value: players,
                                  min: 4,
                                  max: 20,
                                  onChanged: setPlayers,
                                ),

                                CounterSetting(
                                  title: 'Mafia',
                                  value: mafia,
                                  min: 1,
                                  max: math.min(6, players),
                                  onChanged: (value) {
                                    setState(() {
                                      mafia = value;
                                    });
                                  },
                                ),

                                CounterSetting(
                                  title: 'Detektyw',
                                  value: detective,
                                  min: 0,
                                  max: math.min(3, players),
                                  onChanged: (value) {
                                    setState(() {
                                      detective = value;
                                    });
                                  },
                                ),

                                CounterSetting(
                                  title: 'Lekarz',
                                  value: doctor,
                                  min: 0,
                                  max: math.min(3, players),
                                  onChanged: (value) {
                                    setState(() {
                                      doctor = value;
                                    });
                                  },
                                ),

                                const SizedBox(height: 14),

                                StatusPanel(
                                  isValid: isValid,
                                  children: [
                                    SummaryText(
                                      label: 'Mieszkańcy',
                                      value: citizens.toString(),
                                    ),
                                    SummaryText(
                                      label: 'Łącznie role specjalne',
                                      value: specialRoles.toString(),
                                    ),
                                    SummaryText(
                                      label: 'Status',
                                      value: isValid
                                          ? 'Konfiguracja poprawna'
                                          : 'Za dużo ról',
                                      valueColor: isValid
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 26,
                          ),

                          MafiaButton(
                            text: 'UTWÓRZ POKÓJ',
                            onPressed: createRoom,
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

// -----------------------------------------------------------------------------
// JOIN GAME SCREEN
// -----------------------------------------------------------------------------

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController playerNameController = TextEditingController();
  final TextEditingController roomCodeController = TextEditingController();

  String? errorMessage;

  @override
  void dispose() {
    playerNameController.dispose();
    roomCodeController.dispose();
    super.dispose();
  }

  void joinGame() {
    final playerName = playerNameController.text.trim();
    final roomCode = roomCodeController.text.trim().toUpperCase();

    if (playerName.isEmpty) {
      setState(() {
        errorMessage = 'Podaj nazwę gracza.';
      });
      return;
    }

    if (roomCode.isEmpty) {
      setState(() {
        errorMessage = 'Podaj kod pokoju.';
      });
      return;
    }

    if (roomCode.length < 4) {
      setState(() {
        errorMessage = 'Kod pokoju jest za krótki.';
      });
      return;
    }

    setState(() {
      errorMessage = null;
    });

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(
              color: AppColors.neonWhite,
              width: 1.4,
            ),
          ),
          title: Text(
            'Dołączanie',
            style: GoogleFonts.cinzel(
              color: AppColors.neonWhite,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: const [
                Shadow(
                  color: Colors.white,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          content: Text(
            'Gracz "$playerName" próbuje dołączyć do pokoju "$roomCode".\n\nNa razie to ekran testowy. Później podepniemy prawdziwe pokoje online.',
            style: GoogleFonts.fondamento(
              color: Colors.white,
              fontSize: 17,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.cinzel(
                  color: AppColors.neonWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaBackground(
        overlayAlpha: 0.45,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth(context),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MafiaTopBar(
                            title: 'DOŁĄCZ',
                            onBack: () => Navigator.pop(context),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 28,
                          ),

                          NeonMafiaTitle(
                            fontSize: Responsive.screenTitleSize(context),
                          ),

                          const SizedBox(height: 14),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Wejdź do miasta po kodzie pokoju',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fondamento(
                                fontSize:
                                    Responsive.isSmall(context) ? 20 : 24,
                                color: Colors.white,
                                letterSpacing: 1.5,
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

                          SizedBox(
                            height: Responsive.isSmall(context) ? 22 : 34,
                          ),

                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dane gracza',
                                  style: GoogleFonts.cinzel(
                                    color: AppColors.neonWhite,
                                    fontSize:
                                        Responsive.isSmall(context) ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 7,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                MafiaTextField(
                                  controller: playerNameController,
                                  label: 'Nazwa gracza',
                                  hint: 'np. Wiktor',
                                ),

                                const SizedBox(height: 18),

                                MafiaTextField(
                                  controller: roomCodeController,
                                  label: 'Kod pokoju',
                                  hint: 'np. A7K9Q',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                ),

                                if (errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    style: GoogleFonts.cinzel(
                                      color: Colors.redAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                InfoBox(
                                  text: 'Kod pokoju otrzymasz od hosta gry.',
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 20 : 30,
                          ),

                          MafiaButton(
                            text: 'DOŁĄCZ',
                            onPressed: joinGame,
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

// -----------------------------------------------------------------------------
// SHARED UI
// -----------------------------------------------------------------------------

class MafiaBackground extends StatelessWidget {
  const MafiaBackground({
    super.key,
    required this.child,
    this.overlayAlpha = 0.45,
  });

  final Widget child;
  final double overlayAlpha;

  static const String backgroundPath = 'assets/images/backgrounds/miasto.jpg';

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
            color: Colors.black.withOpacity(overlayAlpha),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}

class MafiaTopBar extends StatelessWidget {
  const MafiaTopBar({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.neonWhite,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rubikDistressed(
              color: AppColors.neonWhite,
              fontSize: Responsive.isSmall(context) ? 28 : 34,
              letterSpacing: 2,
              shadows: const [
                Shadow(
                  color: Colors.white,
                  blurRadius: 8,
                ),
                Shadow(
                  color: AppColors.neonWhite,
                  blurRadius: 18,
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 12,
                  offset: Offset(3, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NeonMafiaTitle extends StatelessWidget {
  const NeonMafiaTitle({
    super.key,
    this.fontSize = 92,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final width = Responsive.width(context);
    final letterSpacing = Responsive.clamp(width * 0.015, 3, 8);

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'MAFIA',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BernierShade',
            fontSize: fontSize,
            color: AppColors.neonWhite,
            letterSpacing: letterSpacing,
            shadows: const [
              Shadow(
                color: Colors.white,
                blurRadius: 6,
              ),
              Shadow(
                color: AppColors.neonWhite,
                blurRadius: 16,
              ),
              Shadow(
                color: Color(0xFFFFE7B0),
                blurRadius: 26,
              ),
              Shadow(
                color: Colors.black,
                blurRadius: 14,
                offset: Offset(4, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MafiaPanel extends StatelessWidget {
  const MafiaPanel({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(small ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.64),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neonWhite.withOpacity(0.58),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.65),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }
}

class MafiaTextField extends StatelessWidget {
  const MafiaTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: GoogleFonts.cinzel(
        color: Colors.white,
        fontSize: Responsive.isSmall(context) ? 16 : 18,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.cinzel(
          color: AppColors.neonWhite,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              color: Colors.white,
              blurRadius: 5,
            ),
          ],
        ),
        hintStyle: const TextStyle(
          color: Colors.white38,
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.48),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.neonWhite.withOpacity(0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.neonWhite,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class CounterSetting extends StatelessWidget {
  const CounterSetting({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;

        final titleWidget = Text(
          title,
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cinzel(
            fontSize: Responsive.isSmall(context) ? 16 : 18,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            shadows: const [
              Shadow(
                color: Colors.black,
                blurRadius: 8,
                offset: Offset(2, 2),
              ),
            ],
          ),
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
              padding: EdgeInsets.zero,
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
              iconSize: Responsive.isSmall(context) ? 30 : 34,
              color: AppColors.neonWhite,
            ),
            SizedBox(
              width: 36,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rubikDistressed(
                    color: Colors.white,
                    fontSize: Responsive.isSmall(context) ? 22 : 24,
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        blurRadius: 5,
                      ),
                      Shadow(
                        color: Colors.black,
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
              padding: EdgeInsets.zero,
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
              iconSize: Responsive.isSmall(context) ? 30 : 34,
              color: AppColors.neonWhite,
            ),
          ],
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.isSmall(context) ? 7 : 9,
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: controls,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleWidget),
                    const SizedBox(width: 10),
                    controls,
                  ],
                ),
        );
      },
    );
  }
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.children,
    required this.isValid,
  });

  final List<Widget> children;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.isSmall(context) ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isValid
              ? AppColors.neonWhite.withOpacity(0.45)
              : Colors.redAccent,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isValid
                ? Colors.white.withOpacity(0.06)
                : Colors.red.withOpacity(0.12),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class SummaryText extends StatelessWidget {
  const SummaryText({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final verySmall = constraints.maxWidth < 315;

        final labelWidget = Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.fondamento(
            color: Colors.white70,
            fontSize: Responsive.isSmall(context) ? 16 : 17,
          ),
        );

        final valueWidget = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.right,
            style: GoogleFonts.cinzel(
              color: valueColor ?? Colors.white,
              fontSize: Responsive.isSmall(context) ? 15 : 17,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 8,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        );

        if (verySmall) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: valueWidget,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: labelWidget,
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: valueWidget,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.isSmall(context) ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neonWhite.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 18,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.fondamento(
          color: Colors.white70,
          fontSize: Responsive.isSmall(context) ? 16 : 17,
        ),
      ),
    );
  }
}

class MafiaButton extends StatelessWidget {
  const MafiaButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return SizedBox(
      width: Responsive.buttonWidth(context),
      height: small ? 50 : 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.82),
          foregroundColor: Colors.white,
          elevation: 12,
          shadowColor: Colors.white24,
          side: const BorderSide(
            color: AppColors.neonWhite,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: GoogleFonts.rubikDistressed(
              fontSize: small ? 22 : 26,
              letterSpacing: 1,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.white,
                  blurRadius: 8,
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
    );
  }
}
class LobbyScreen extends StatelessWidget {
  final String roomCode;
  final String playerName;
  final bool isHost;

  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final players = [
      {'name': playerName, 'isHost': isHost},
      {'name': 'Gracz2', 'isHost': false},
      {'name': 'Gracz3', 'isHost': false},
    ];

    return Scaffold(
      body: MafiaBackground(
        overlayAlpha: 0.5,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  MafiaTopBar(
                    title: "LOBBY",
                    onBack: () => Navigator.pop(context),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Kod pokoju",
                    style: GoogleFonts.fondamento(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    roomCode,
                    style: GoogleFonts.rubikDistressed(
                      fontSize: 40,
                      color: AppColors.neonWhite,
                      letterSpacing: 4,
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 8),
                        Shadow(
                          color: Colors.black,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  MafiaPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gracze",
                          style: GoogleFonts.cinzel(
                            color: AppColors.neonWhite,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 14),

                        ...players.map((p) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p['name'] as String,
                                    style: GoogleFonts.cinzel(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                if (p['isHost'] == true)
                                  const Text(
                                    "HOST",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (isHost)
                    MafiaButton(
                      text: "START GRY",
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tu będzie start gry"),
                          ),
                        );
                      },
                    )
                  else
                    const Text(
                      "Czekaj na start gry...",
                      style: TextStyle(color: Colors.white70),
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
