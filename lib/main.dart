import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  static const Color redDark = Color(0xFF7A0C0C);
  static const Color redLight = Color(0xFFB82222);
  static const Color neonWhite = Color(0xFFF8F4E8);
  static const Color panelBlack = Color(0xFF080505);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String backgroundPath = 'assets/images/backgrounds/miasto.jpg';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mafia',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonWhite,
          brightness: Brightness.dark,
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
      backgroundColor: Colors.black,
      body: MafiaBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const NeonMafiaTitle(
                    fontSize: 120,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Work in progress',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fondamento(
                      fontSize: 28,
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

                  const SizedBox(height: 56),

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

                  const SizedBox(height: 18),

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

  int playersCount = 6;
  int mafiaCount = 1;
  int detectiveCount = 1;
  int doctorCount = 1;

  String? roomCode;

  int get citizensCount {
    final specialRoles = mafiaCount + detectiveCount + doctorCount;
    final citizens = playersCount - specialRoles;
    return citizens < 0 ? 0 : citizens;
  }

  bool get isConfigurationValid {
    return mafiaCount + detectiveCount + doctorCount <= playersCount;
  }

  @override
  void dispose() {
    hostNameController.dispose();
    super.dispose();
  }

  void createRoom() {
    if (!isConfigurationValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liczba ról jest większa niż liczba graczy.'),
        ),
      );
      return;
    }

    final generatedCode = generateRoomCode();

    setState(() {
      roomCode = generatedCode;
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
                'Kod pokoju:',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                generatedCode,
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
                'Na razie pokój jest lokalny. Później podepniemy Firebase albo inne połączenie online.',
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

  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();

    return List.generate(
      5,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MafiaBackground(
        overlayAlpha: 0.42,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              children: [
                MafiaTopBar(
                  title: 'HOSTOWANIE',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 28),

                MafiaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ustawienia pokoju',
                        style: GoogleFonts.cinzel(
                          color: AppColors.neonWhite,
                          fontSize: 24,
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
                        controller: hostNameController,
                        label: 'Nazwa hosta',
                        hint: 'np. Wiktor',
                      ),

                      const SizedBox(height: 24),

                      CounterSetting(
                        title: 'Liczba graczy',
                        value: playersCount,
                        min: 4,
                        max: 20,
                        onChanged: (value) {
                          setState(() {
                            playersCount = value;
                          });
                        },
                      ),

                      CounterSetting(
                        title: 'Mafia',
                        value: mafiaCount,
                        min: 1,
                        max: 6,
                        onChanged: (value) {
                          setState(() {
                            mafiaCount = value;
                          });
                        },
                      ),

                      CounterSetting(
                        title: 'Detektyw',
                        value: detectiveCount,
                        min: 0,
                        max: 3,
                        onChanged: (value) {
                          setState(() {
                            detectiveCount = value;
                          });
                        },
                      ),

                      CounterSetting(
                        title: 'Lekarz',
                        value: doctorCount,
                        min: 0,
                        max: 3,
                        onChanged: (value) {
                          setState(() {
                            doctorCount = value;
                          });
                        },
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConfigurationValid
                                ? AppColors.neonWhite.withValues(alpha: 0.45)
                                : Colors.redAccent,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.08),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SummaryText(
                              label: 'Mieszkańcy',
                              value: citizensCount.toString(),
                            ),
                            SummaryText(
                              label: 'Łącznie role specjalne',
                              value:
                                  '${mafiaCount + detectiveCount + doctorCount}',
                            ),
                            SummaryText(
                              label: 'Status',
                              value: isConfigurationValid
                                  ? 'Konfiguracja poprawna'
                                  : 'Za dużo ról',
                              valueColor: isConfigurationValid
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                MafiaButton(
                  text: 'UTWÓRZ POKÓJ',
                  onPressed: createRoom,
                ),

                const SizedBox(height: 16),

                if (roomCode != null)
                  Text(
                    'Kod pokoju: $roomCode',
                    style: GoogleFonts.cinzel(
                      color: AppColors.neonWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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
              ],
            ),
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
            'Gracz "$playerName" próbuje dołączyć do pokoju "$roomCode".\n\nNa razie to ekran testowy. Później podepniemy realne pokoje online.',
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
      backgroundColor: Colors.black,
      body: MafiaBackground(
        overlayAlpha: 0.42,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              children: [
                MafiaTopBar(
                  title: 'DOŁĄCZ',
                  onBack: () => Navigator.pop(context),
                ),

                const SizedBox(height: 34),

                const NeonMafiaTitle(
                  fontSize: 92,
                ),

                const SizedBox(height: 18),

                Text(
                  'Wejdź do miasta po kodzie pokoju',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fondamento(
                    fontSize: 24,
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

                const SizedBox(height: 38),

                MafiaPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dane gracza',
                        style: GoogleFonts.cinzel(
                          color: AppColors.neonWhite,
                          fontSize: 24,
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

                      const SizedBox(height: 22),

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
                        textCapitalization: TextCapitalization.characters,
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

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.neonWhite.withValues(alpha: 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.08),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Text(
                          'Kod pokoju otrzymasz od hosta gry.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fondamento(
                            color: Colors.white70,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

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
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundPath,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
          Container(
            color: Colors.black.withValues(alpha: overlayAlpha),
          ),
          child,
        ],
      ),
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
        Text(
          title,
          style: GoogleFonts.rubikDistressed(
            color: AppColors.neonWhite,
            fontSize: 34,
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
    return Text(
      'MAFIA',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'BernierShade',
        fontSize: fontSize,
        color: AppColors.neonWhite,
        letterSpacing: 8,
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
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neonWhite.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.08),
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
        fontSize: 18,
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
        fillColor: Colors.black.withValues(alpha: 0.48),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.neonWhite.withValues(alpha: 0.45),
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

  void decrease() {
    if (value > min) {
      onChanged(value - 1);
    }
  }

  void increase() {
    if (value < max) {
      onChanged(value + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: decrease,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.neonWhite,
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.rubikDistressed(
                color: Colors.white,
                fontSize: 24,
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
          IconButton(
            onPressed: increase,
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.neonWhite,
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.fondamento(
                color: Colors.white70,
                fontSize: 17,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.cinzel(
              color: valueColor ?? Colors.white,
              fontSize: 17,
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
        ],
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
    return SizedBox(
      width: 280,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.72),
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
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.rubikDistressed(
            fontSize: 26,
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
    );
  }
}