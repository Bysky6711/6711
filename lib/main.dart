import 'dart:math' as math;
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
      theme: ThemeData.dark(),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const NeonMafiaTitle(),
                          const SizedBox(height: 12),

                          Text(
                            "Work in progress",
                            style: GoogleFonts.fondamento(
                              fontSize: 24,
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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Ekran join jeszcze w budowie"),
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const NeonMafiaTitle(fontSize: 70),
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
                            valueColor:
                                citizens >= 0 ? Colors.green : Colors.red,
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
          child: Container(color: Colors.black.withOpacity(0.55)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class NeonMafiaTitle extends StatelessWidget {
  const NeonMafiaTitle({super.key, this.fontSize = 92});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Text(
        "MAFIA",
        style: TextStyle(
          fontFamily: 'BernierShade',
          fontSize: fontSize,
          color: AppColors.neonWhite,
          letterSpacing: 6,
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
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white))),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text("$value", style: const TextStyle(fontSize: 20)),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class MafiaPanel extends StatelessWidget {
  const MafiaPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
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
    return SizedBox(
      width: 320,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          side: const BorderSide(color: Colors.white),
        ),
        child: Text(
          text,
          style: GoogleFonts.rubikDistressed(fontSize: 24),
        ),
      ),
    );
  }
}
