import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  static const Color neonWhite = Color(0xFFF8F4E8);
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

  static double hostTitleSize(BuildContext context) {
    final w = width(context);
    return clamp(w * 0.18, 48, 84);
  }

  static double buttonWidth(BuildContext context) {
    final w = width(context);
    return math.min(w - (horizontalPadding(context) * 2), 380);
  }

  static double contentMaxWidth(BuildContext context) {
    final w = width(context);

    if (w >= 900) return 560;
    if (w >= 600) return 520;
    return double.infinity;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white24,
          ),
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}

// ---------------- MAIN MENU ----------------

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaBackground(
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

                          const SizedBox(height: 8),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Work in progress',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.fondamento(
                                fontSize: Responsive.isSmall(context) ? 22 : 26,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 30 : 42,
                          ),

                          MafiaButton(
                            text: "HOSTUJ",
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
                            text: "DOŁĄCZ DO GRY",
                            onPressed: () {},
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

// ---------------- HOST SCREEN ----------------

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  int players = 6;
  int mafia = 1;
  int detective = 1;
  int doctor = 1;

  int get citizens => players - (mafia + detective + doctor);

  void setPlayers(int value) {
    setState(() {
      players = value;

      final specialRoles = mafia + detective + doctor;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaBackground(
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
                            fontSize: Responsive.hostTitleSize(context),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 14 : 22,
                          ),

                          MafiaPanel(
                            child: Column(
                              children: [
                                CounterSetting(
                                  title: "LICZBA GRACZY",
                                  value: players,
                                  min: 4,
                                  max: 20,
                                  onChanged: setPlayers,
                                ),
                                CounterSetting(
                                  title: "MAFIA",
                                  value: mafia,
                                  min: 1,
                                  max: math.min(6, players),
                                  onChanged: (v) {
                                    setState(() => mafia = v);
                                  },
                                ),
                                CounterSetting(
                                  title: "DETEKTYW",
                                  value: detective,
                                  min: 0,
                                  max: math.min(3, players),
                                  onChanged: (v) {
                                    setState(() => detective = v);
                                  },
                                ),
                                CounterSetting(
                                  title: "LEKARZ",
                                  value: doctor,
                                  min: 0,
                                  max: math.min(3, players),
                                  onChanged: (v) {
                                    setState(() => doctor = v);
                                  },
                                ),

                                const SizedBox(height: 12),

                                SummaryText(
                                  label: "Mieszkańcy",
                                  value: citizens.toString(),
                                ),
                                SummaryText(
                                  label: "Łącznie role specjalne",
                                  value: (mafia + detective + doctor).toString(),
                                ),
                                SummaryText(
                                  label: "Status",
                                  value: citizens >= 0
                                      ? "Konfiguracja poprawna"
                                      : "Za dużo ról",
                                  valueColor: citizens >= 0
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 24,
                          ),

                          MafiaButton(
                            text: "UTWÓRZ POKÓJ",
                            onPressed: citizens >= 0 ? () {} : () {},
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

// ---------------- UI ELEMENTY ----------------

class MafiaBackground extends StatelessWidget {
  const MafiaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/backgrounds/miasto.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.55),
          ),
        ),
        Positioned.fill(
          child: child,
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
          "MAFIA",
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BernierShade',
            fontSize: fontSize,
            color: AppColors.neonWhite,
            letterSpacing: letterSpacing,
          ),
        ),
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
    final verySmall = Responsive.isVerySmall(context);

    final labelStyle = TextStyle(
      color: Colors.white70,
      fontSize: verySmall ? 14 : 15,
    );

    final valueStyle = TextStyle(
      color: valueColor ?? Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: verySmall ? 14 : 15,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: verySmall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: labelStyle,
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: valueStyle,
                    softWrap: true,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: labelStyle,
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: valueStyle,
                    softWrap: true,
                  ),
                ),
              ],
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
          style: TextStyle(
            fontSize: Responsive.isSmall(context) ? 16 : 18,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          softWrap: true,
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 34,
              child: Text(
                "$value",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
      padding: EdgeInsets.all(small ? 14 : 22),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
      height: small ? 50 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.85),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
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
            style: GoogleFonts.rubikDistressed(
              fontSize: small ? 22 : 26,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}