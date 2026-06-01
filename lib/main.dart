import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_colors.dart';
import 'core/responsive.dart';
import 'data/card.dart';
import 'data/roles.dart';
import 'widgets/shared_widgets.dart';

void main() {
  runApp(const MyApp());
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
                                  builder: (context) => const HostGameScreen(),
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
                                  builder: (context) => const JoinGameScreen(),
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

  Map<MafiaRoleCardType, int> roleCounts = GameRoles.defaultRoleCounts();

  int get specialRoles => GameRoles.specialRolesCount(roleCounts);

  int get citizens => GameRoles.citizensCount(
        players: players,
        roleCounts: roleCounts,
      );

  bool get isValid => specialRoles <= math.max(0, players - 1);

  @override
  void dispose() {
    hostNameController.dispose();
    super.dispose();
  }

  int roleValue(MafiaRoleCardType type) {
    return roleCounts[type] ?? 0;
  }

  void setRoleValue(MafiaRoleCardType type, int value) {
    setState(() {
      roleCounts = {
        ...roleCounts,
        type: value,
      };
      normalizeRoleCounts();
    });
  }

  void setPlayers(int value) {
    setState(() {
      players = value;
      normalizeRoleCounts();
    });
  }

  void normalizeRoleCounts() {
    final maxSpecial = math.max(0, players - 1);
    var total = GameRoles.specialRolesCount(roleCounts);

    if (total <= maxSpecial) return;

    var over = total - maxSpecial;
    final removableRoles = GameRoles.configurable.reversed.toList();

    for (final role in removableRoles) {
      if (over <= 0) break;

      final current = roleCounts[role.type] ?? 0;
      final removable = math.max(0, current - role.min);
      final decrease = math.min(removable, over);

      if (decrease > 0) {
        roleCounts[role.type] = current - decrease;
        over -= decrease;
      }
    }
  }

  int maxForRole(GameRoleDefinition role) {
    final maxSpecial = math.max(0, players - 1);

    var otherRolesCount = 0;

    for (final otherRole in GameRoles.configurable) {
      if (otherRole.type == role.type) continue;

      otherRolesCount += roleCounts[otherRole.type] ?? 0;
    }

    final availableForThisRole = maxSpecial - otherRolesCount;
    final safeAvailable = math.max(role.min, availableForThisRole);

    return math.min(role.max, safeAvailable);
  }

  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random.secure();

    return List.generate(
      5,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void createRoom() {
    normalizeRoleCounts();

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
        builder: (context) => LobbyScreen(
          roomCode: roomCode,
          playerName: hostName,
          isHost: true,
          maxPlayers: players,
          roleCounts: Map<MafiaRoleCardType, int>.from(roleCounts),
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
      ...GameRoles.configurable.map((role) {
        return RoleSetting(
          name: role.name,
          value: roleValue(role.type),
          min: role.min,
          max: maxForRole(role),
          onChanged: (value) {
            setRoleValue(role.type, value);
          },
        );
      }),
    ];

    final summary = <RoleSummary>[
      ...GameRoles.configurable.map((role) {
        return RoleSummary(
          name: role.name,
          value: roleValue(role.type).toString(),
        );
      }),
      RoleSummary(
        name: GameRoles.nameOf(MafiaRoleCardType.citizen),
        value: citizens.toString(),
      ),
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
                                    maxHeight: 300,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: roleSettings.length,
                                    separatorBuilder: (context, index) =>
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
                                    maxHeight: 230,
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
        builder: (context) => LobbyScreen(
          roomCode: roomCode,
          playerName: playerName,
          isHost: false,
          maxPlayers: 6,
          roleCounts: GameRoles.defaultRoleCounts(),
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
    required this.roleCounts,
  });

  final String roomCode;
  final String playerName;
  final bool isHost;
  final int maxPlayers;
  final Map<MafiaRoleCardType, int> roleCounts;

  int get citizensCount {
    return GameRoles.citizensCount(
      players: maxPlayers,
      roleCounts: roleCounts,
    );
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

    final roleSummary = <RoleSummary>[
      ...GameRoles.configurable.map((role) {
        return RoleSummary(
          name: role.name,
          value: GameRoles.countOf(roleCounts, role.type).toString(),
        );
      }),
      RoleSummary(
        name: GameRoles.nameOf(MafiaRoleCardType.citizen),
        value: citizensCount.toString(),
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
                                    maxHeight: 220,
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: roleSummary.map<Widget>((item) {
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
                            height: Responsive.isSmall(context) ? 26 : 36,
                          ),
                          if (isHost)
                            MafiaButton(
                              text: 'Start gry',
                              icon: Icons.play_arrow_rounded,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RoleRevealScreen(
                                      roleType: MafiaRoleCardType.host,
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