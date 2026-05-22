import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  static const Color neonWhite = Color(0xFFF8F4E8);
  static const Color frame = Color(0xCCF8F4E8);
  static const Color deepRed = Color(0xFF4A0500);
  static const Color fieldGrey = Color(0xFFB7B7B7);
}

class Responsive {
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static double height(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

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

  static double contentMaxWidth(BuildContext context) {
    final w = width(context);

    if (w >= 900) return 520;
    if (w >= 600) return 500;
    return double.infinity;
  }

  static double mainTitleSize(BuildContext context) {
    final w = width(context);
    return clamp(w * 0.23, 62, 112);
  }

  static double buttonWidth(BuildContext context) {
    final w = width(context);
    return math.min(w - (horizontalPadding(context) * 2), 380);
  }
}

class RoleSetting {
  const RoleSetting({
    required this.name,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String name;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
}

class RoleSummary {
  const RoleSummary({
    required this.name,
    required this.value,
    this.valueColor,
  });

  final String name;
  final String value;
  final Color? valueColor;
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
                        children: [
                          SizedBox(
                            height: Responsive.height(context) * 0.24,
                          ),
                          NeonMafiaTitle(
                            fontSize: Responsive.mainTitleSize(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Work in progress',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: Responsive.isSmall(context) ? 28 : 34,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              shadows: const [
                                Shadow(
                                  color: Colors.white,
                                  blurRadius: 4,
                                ),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 48 : 64,
                          ),
                          MafiaButton(
                            text: 'Hostuj',
                            icon: Icons.groups_rounded,
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
                            text: 'Dołącz do gry',
                            icon: Icons.login_rounded,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const JoinGameScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(
                            height: Responsive.height(context) * 0.14,
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          roomCode: roomCode,
          playerName: hostName,
          isHost: true,
          maxPlayers: players,
          mafiaCount: mafia,
          detectiveCount: detective,
          doctorCount: doctor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleSettings = <RoleSetting>[
      RoleSetting(
        name: 'Liczba graczy',
        value: players,
        min: 4,
        max: 20,
        onChanged: setPlayers,
      ),
      RoleSetting(
        name: 'Mafia',
        value: mafia,
        min: 1,
        max: math.min(6, players),
        onChanged: (value) {
          setState(() {
            mafia = value;
          });
        },
      ),
      RoleSetting(
        name: 'Detektyw',
        value: detective,
        min: 0,
        max: math.min(3, players),
        onChanged: (value) {
          setState(() {
            detective = value;
          });
        },
      ),
      RoleSetting(
        name: 'Lekarz',
        value: doctor,
        min: 0,
        max: math.min(3, players),
        onChanged: (value) {
          setState(() {
            doctor = value;
          });
        },
      ),
    ];

    final summary = <RoleSummary>[
      RoleSummary(name: 'Mafia', value: mafia.toString()),
      RoleSummary(name: 'Detektyw', value: detective.toString()),
      RoleSummary(name: 'Lekarz', value: doctor.toString()),
      RoleSummary(name: 'Mieszkańcy', value: citizens.toString()),
      RoleSummary(
        name: 'Łącznie role specjalne',
        value: specialRoles.toString(),
      ),
      RoleSummary(
        name: 'Status',
        value: isValid ? 'Konfiguracja poprawna' : 'Za dużo ról',
        valueColor: isValid ? Colors.greenAccent : Colors.redAccent,
      ),
    ];

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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScreenHeader(
                            title: 'Hostowanie',
                            icon: Icons.groups_rounded,
                            onBack: () => Navigator.pop(context),
                            showTitle: false,
                            showIcon: true,
                            largeIcon: true,
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 20 : 28,
                          ),
                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Ustawienia pokoju',
                                  icon: Icons.tune_rounded,
                                  showIcon: false,
                                ),
                                const SizedBox(height: 20),
                                MafiaTextField(
                                  controller: hostNameController,
                                  label: 'Nazwa hosta',
                                  hint: 'np. Wiktor',
                                  mutedText: false,
                                ),
                                const SizedBox(height: 18),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 245,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: roleSettings.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final role = roleSettings[index];

                                      return CounterSetting(
                                        title: role.name,
                                        value: role.value,
                                        min: role.min,
                                        max: role.max,
                                        onChanged: role.onChanged,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 24,
                          ),
                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Podsumowanie ról',
                                  icon: Icons.analytics_outlined,
                                  showIcon: false,
                                ),
                                const SizedBox(height: 18),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 205,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: summary.map<Widget>((item) {
                                        return SummaryText(
                                          label: item.name,
                                          value: item.value,
                                          valueColor: item.valueColor,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 22 : 30,
                          ),
                          MafiaButton(
                            text: 'Utwórz',
                            icon: Icons.arrow_forward_rounded,
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          roomCode: roomCode,
          playerName: playerName,
          isHost: false,
          maxPlayers: 6,
          mafiaCount: 1,
          detectiveCount: 1,
          doctorCount: 1,
        ),
      ),
    );
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScreenHeader(
                            title: 'Dołącz',
                            icon: Icons.login_rounded,
                            onBack: () => Navigator.pop(context),
                            showTitle: false,
                            showIcon: true,
                            largeIcon: true,
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 34 : 52,
                          ),
                          Text(
                            'Wejdź do miasta',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: Responsive.isSmall(context) ? 36 : 46,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.2,
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
                          const SizedBox(height: 10),
                          Text(
                            'Dołącz do pokoju gry',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white70,
                              fontSize: Responsive.isSmall(context) ? 22 : 26,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 34 : 48,
                          ),
                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Dane gracza',
                                  icon: Icons.person_outline_rounded,
                                  showIcon: false,
                                ),
                                const SizedBox(height: 22),
                                MafiaTextField(
                                  controller: playerNameController,
                                  label: 'Nazwa gracza',
                                  hint: 'np. Wiktor',
                                  mutedText: true,
                                ),
                                const SizedBox(height: 18),
                                MafiaTextField(
                                  controller: roomCodeController,
                                  label: 'Kod pokoju',
                                  hint: 'np. A7K9Q',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  mutedText: true,
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
                                const HelpHint(
                                  text: 'Kod pokoju otrzymasz od hosta.',
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 28 : 40,
                          ),
                          MafiaButton(
                            text: 'Dołącz',
                            icon: Icons.arrow_forward_rounded,
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
// LOBBY SCREEN
// -----------------------------------------------------------------------------

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.isHost,
    required this.maxPlayers,
    required this.mafiaCount,
    required this.detectiveCount,
    required this.doctorCount,
  });

  final String roomCode;
  final String playerName;
  final bool isHost;
  final int maxPlayers;
  final int mafiaCount;
  final int detectiveCount;
  final int doctorCount;

  int get citizensCount {
    final result = maxPlayers - mafiaCount - detectiveCount - doctorCount;
    return result < 0 ? 0 : result;
  }

  @override
  Widget build(BuildContext context) {
    final players = <Map<String, Object>>[
      {
        'name': playerName,
        'isHost': isHost,
      },
      {
        'name': 'Gracz 2',
        'isHost': false,
      },
      {
        'name': 'Gracz 3',
        'isHost': false,
      },
    ];

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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScreenHeader(
                            title: 'Lobby',
                            icon: Icons.meeting_room_rounded,
                            onBack: () => Navigator.pop(context),
                            showTitle: true,
                            showIcon: false,
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 28,
                          ),
                          MafiaPanel(
                            child: Column(
                              children: [
                                SectionHeader(
                                  title: 'Kod pokoju',
                                  icon: Icons.key_rounded,
                                  showIcon: false,
                                ),
                                const SizedBox(height: 14),
                                SelectableText(
                                  roomCode,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cinzel(
                                    color: AppColors.neonWhite,
                                    fontSize:
                                        Responsive.isSmall(context) ? 36 : 46,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 6,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 6,
                                      ),
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 12,
                                        offset: Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isHost
                                      ? 'Przekaż ten kod graczom.'
                                      : 'Czekaj, aż host rozpocznie grę.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cormorantGaramond(
                                    color: Colors.white70,
                                    fontSize:
                                        Responsive.isSmall(context) ? 18 : 20,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 24,
                          ),
                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: SectionHeader(
                                        title: 'Gracze',
                                        icon: Icons.people_alt_outlined,
                                        showIcon: false,
                                      ),
                                    ),
                                    Text(
                                      '${players.length}/$maxPlayers',
                                      style: GoogleFonts.cinzel(
                                        color: AppColors.neonWhite,
                                        fontSize: Responsive.isSmall(context)
                                            ? 20
                                            : 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...players.map<Widget>((player) {
                                  final name = player['name'] as String;
                                  final playerIsHost =
                                      player['isHost'] as bool;

                                  return LobbyPlayerTile(
                                    name: name,
                                    isHost: playerIsHost,
                                  );
                                }),
                                if (players.length < maxPlayers)
                                  EmptyPlayerSlot(
                                    slotNumber: players.length + 1,
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 24,
                          ),
                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Podsumowanie ról',
                                  icon: Icons.analytics_outlined,
                                  showIcon: false,
                                ),
                                const SizedBox(height: 18),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 190,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        SummaryText(
                                          label: 'Mafia',
                                          value: mafiaCount.toString(),
                                        ),
                                        SummaryText(
                                          label: 'Detektyw',
                                          value: detectiveCount.toString(),
                                        ),
                                        SummaryText(
                                          label: 'Lekarz',
                                          value: doctorCount.toString(),
                                        ),
                                        SummaryText(
                                          label: 'Mieszkańcy',
                                          value: citizensCount.toString(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 26 : 36,
                          ),
                          if (isHost)
                            MafiaButton(
                              text: 'Start gry',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Tutaj później dodamy start gry i losowanie ról.',
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            Text(
                              'Czekaj na start gry...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cormorantGaramond(
                                color: Colors.white70,
                                fontSize:
                                    Responsive.isSmall(context) ? 20 : 24,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 1,
                              ),
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
  });

  final Widget child;

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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.96),
                  Colors.black.withValues(alpha: 0.78),
                  AppColors.deepRed.withValues(alpha: 0.78),
                  AppColors.deepRed.withValues(alpha: 0.92),
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

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.onBack,
    this.showTitle = true,
    this.showIcon = true,
    this.largeIcon = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onBack;
  final bool showTitle;
  final bool showIcon;
  final bool largeIcon;

  @override
  Widget build(BuildContext context) {
    final iconSize = largeIcon ? 34.0 : 23.0;

    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.neonWhite,
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (showIcon)
          Icon(
            icon,
            color: AppColors.neonWhite,
            size: iconSize,
          ),
        if (showIcon && showTitle) const SizedBox(width: 10),
        if (showTitle)
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                color: AppColors.neonWhite,
                fontSize: Responsive.isSmall(context) ? 24 : 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 6,
                  ),
                  Shadow(
                    color: Colors.black,
                    blurRadius: 12,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
            ),
          )
        else
          const Spacer(),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.showIcon = false,
  });

  final String title;
  final IconData icon;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showIcon) ...[
          Icon(
            icon,
            color: AppColors.neonWhite,
            size: 22,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              color: AppColors.neonWhite,
              fontSize: Responsive.isSmall(context) ? 18 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.4,
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
    final letterSpacing = Responsive.clamp(width * 0.014, 3, 7);

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
                blurRadius: 3,
              ),
              Shadow(
                color: AppColors.neonWhite,
                blurRadius: 8,
              ),
              Shadow(
                color: Colors.black,
                blurRadius: 12,
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
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.frame,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.07),
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
    this.mutedText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextCapitalization textCapitalization;
  final bool mutedText;

  @override
  Widget build(BuildContext context) {
    final textColor = mutedText ? AppColors.fieldGrey : Colors.white;

    return TextField(
      controller: controller,
      textCapitalization: textCapitalization,
      style: GoogleFonts.cinzel(
        color: textColor,
        fontSize: Responsive.isSmall(context) ? 16 : 18,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        hintText: hint,
        labelStyle: GoogleFonts.cinzel(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: mutedText
              ? null
              : const [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 4,
                  ),
                ],
        ),
        hintStyle: TextStyle(
          color: textColor.withValues(alpha: 0.55),
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.35),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.frame,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
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
    final small = Responsive.isSmall(context);

    return SizedBox(
      minHeight: small ? 48 : 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                fontSize: small ? 15 : 18,
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
            ),
          ),
          const SizedBox(width: 8),
          _CounterIconButton(
            icon: Icons.remove_circle_outline,
            enabled: value > min,
            onPressed: () => onChanged(value - 1),
          ),
          SizedBox(
            width: 34,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: small ? 20 : 24,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 4,
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
          _CounterIconButton(
            icon: Icons.add_circle_outline,
            enabled: value < max,
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _CounterIconButton extends StatelessWidget {
  const _CounterIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return SizedBox(
      width: small ? 38 : 42,
      height: small ? 38 : 42,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        iconSize: small ? 30 : 34,
        color: AppColors.neonWhite,
        disabledColor: AppColors.neonWhite.withValues(alpha: 0.28),
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
          style: GoogleFonts.cormorantGaramond(
            color: Colors.white70,
            fontSize: Responsive.isSmall(context) ? 17 : 19,
            fontStyle: FontStyle.italic,
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
          padding: const EdgeInsets.only(bottom: 8),
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

class HelpHint extends StatelessWidget {
  const HelpHint({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.help_outline_rounded,
          color: Colors.white.withValues(alpha: 0.55),
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white60,
              fontSize: Responsive.isSmall(context) ? 17 : 19,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class MafiaButton extends StatelessWidget {
  const MafiaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return SizedBox(
      width: Responsive.buttonWidth(context),
      height: small ? 52 : 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.58),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          side: const BorderSide(
            color: AppColors.frame,
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
                color: AppColors.neonWhite,
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

class LobbyPlayerTile extends StatelessWidget {
  const LobbyPlayerTile({
    super.key,
    required this.name,
    required this.isHost,
  });

  final String name;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isSmall(context) ? 12 : 14,
        vertical: Responsive.isSmall(context) ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHost
              ? AppColors.neonWhite.withValues(alpha: 0.75)
              : AppColors.frame,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(
              child: isHost
                  ? const MafiaHatIcon(
                      size: 24,
                      color: AppColors.neonWhite,
                    )
                  : const Icon(
                      Icons.person_outline,
                      color: AppColors.neonWhite,
                      size: 23,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: Responsive.isSmall(context) ? 15 : 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          if (isHost)
            Text(
              'HOST',
              style: GoogleFonts.cinzel(
                color: Colors.greenAccent,
                fontSize: Responsive.isSmall(context) ? 13 : 15,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class MafiaHatIcon extends StatelessWidget {
  const MafiaHatIcon({
    super.key,
    this.size = 24,
    this.color = AppColors.neonWhite,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0.5, 0),
      child: CustomPaint(
        size: Size(size, size),
        painter: MafiaHatPainter(color: color),
      ),
    );
  }
}

class MafiaHatPainter extends CustomPainter {
  const MafiaHatPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final brim = Path()
      ..moveTo(w * 0.16, h * 0.64)
      ..quadraticBezierTo(w * 0.50, h * 0.76, w * 0.84, h * 0.64);

    canvas.drawPath(brim, strokePaint);

    final crown = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        w * 0.30,
        h * 0.28,
        w * 0.40,
        h * 0.34,
      ),
      Radius.circular(w * 0.08),
    );

    canvas.drawRRect(crown, fillPaint);
    canvas.drawRRect(crown, strokePaint);

    final topLine = Path()
      ..moveTo(w * 0.34, h * 0.28)
      ..quadraticBezierTo(w * 0.50, h * 0.18, w * 0.66, h * 0.28);

    canvas.drawPath(topLine, strokePaint);

    final band = Path()
      ..moveTo(w * 0.32, h * 0.49)
      ..lineTo(w * 0.68, h * 0.49);

    canvas.drawPath(band, strokePaint);
  }

  @override
  bool shouldRepaint(covariant MafiaHatPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class EmptyPlayerSlot extends StatelessWidget {
  const EmptyPlayerSlot({
    super.key,
    required this.slotNumber,
  });

  final int slotNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isSmall(context) ? 12 : 14,
        vertical: Responsive.isSmall(context) ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.frame.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Center(
              child: Icon(
                Icons.person_add_alt_outlined,
                color: Colors.white.withValues(alpha: 0.45),
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Wolne miejsce $slotNumber',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white54,
              fontSize: Responsive.isSmall(context) ? 16 : 18,
              fontStyle: FontStyle.italic,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}