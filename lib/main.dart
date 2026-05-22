import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  static const Color neonWhite = Color(0xFFF8F4E8);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const NeonMafiaTitle(fontSize: 120),
                      const SizedBox(height: 10),

                      Text(
                        'Work in progress',
                        style: GoogleFonts.fondamento(
                          fontSize: 26,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 40),

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              children: [
                const NeonMafiaTitle(fontSize: 80),
                const SizedBox(height: 20),

                MafiaPanel(
                  child: Column(
                    children: [
                      CounterSetting(
                        title: "LICZBA GRACZY",
                        value: players,
                        min: 4,
                        max: 20,
                        onChanged: (v) => setState(() => players = v),
                      ),
                      CounterSetting(
                        title: "MAFIA",
                        value: mafia,
                        min: 1,
                        max: 6,
                        onChanged: (v) => setState(() => mafia = v),
                      ),
                      CounterSetting(
                        title: "DETEKTYW",
                        value: detective,
                        min: 0,
                        max: 3,
                        onChanged: (v) => setState(() => detective = v),
                      ),
                      CounterSetting(
                        title: "LEKARZ",
                        value: doctor,
                        min: 0,
                        max: 3,
                        onChanged: (v) => setState(() => doctor = v),
                      ),

                      const SizedBox(height: 10),

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

                const SizedBox(height: 20),

                MafiaButton(
                  text: "UTWÓRZ POKÓJ",
                  onPressed: () {},
                ),
              ],
            ),
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
        Image.asset(
          'assets/images/backgrounds/miasto.jpg',
          fit: BoxFit.cover,
          height: double.infinity,
        ),
        Container(color: Colors.black.withOpacity(0.5)),
        child,
      ],
    );
  }
}

// ✅ NAPRAWA MAFIA
class NeonMafiaTitle extends StatelessWidget {
  const NeonMafiaTitle({super.key, this.fontSize = 92});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return FittedBox(
      child: Text(
        "MAFIA",
        maxLines: 1,
        style: TextStyle(
          fontFamily: 'BernierShade',
          fontSize: width < 390 ? fontSize * 0.75 : fontSize,
          color: AppColors.neonWhite,
          letterSpacing: width < 390 ? 4 : 8,
        ),
      ),
    );
  }
}

// ✅ NAPRAWA STATUSU
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
    final small = MediaQuery.of(context).size.width < 350;

    if (small) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white),
            ),
          ),
          const SizedBox(height: 6),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ✅ LEPSZE LICZNIKI
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
    final small = MediaQuery.of(context).size.width < 390;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: small ? 16 : 18, color: Colors.white),
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text("$value", style: const TextStyle(fontSize: 22)),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

// ✅ PANEL MOBILE
class MafiaPanel extends StatelessWidget {
  const MafiaPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 390;

    return Container(
      padding: EdgeInsets.all(small ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

// ✅ BUTTON AUTO WIDTH
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
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      width: width - 50,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          side: const BorderSide(color: Colors.white),
        ),
        child: FittedBox(
          child: Text(
            text,
            style: GoogleFonts.rubikDistressed(fontSize: 26),
          ),
        ),
      ),
    );
  }
}