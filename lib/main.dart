import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_colors.dart';
import 'core/responsive.dart';
import 'data/card.dart';
import 'data/roles.dart';
import 'models/game_room.dart';
import 'models/room_status.dart';
import 'services/local_room_service.dart';
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
  const RoleSummary({required this.name, required this.value, this.valueColor});

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
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
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
                          SizedBox(height: Responsive.height(context) * 0.24),
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
                                Shadow(color: Colors.white, blurRadius: 4),
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
                          SizedBox(height: Responsive.height(context) * 0.14),
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

  int get citizens =>
      GameRoles.citizensCount(players: players, roleCounts: roleCounts);

  bool get isValid => specialRoles <= players;

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
      roleCounts = {...roleCounts, type: value};

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
    final maxSpecial = players;
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
    final maxSpecial = players;

    var otherRolesCount = 0;

    for (final otherRole in GameRoles.configurable) {
      if (otherRole.type == role.type) continue;
      otherRolesCount += roleCounts[otherRole.type] ?? 0;
    }

    final availableForThisRole = maxSpecial - otherRolesCount;
    final safeAvailable = math.max(role.min, availableForThisRole);

    return math.min(role.max, safeAvailable);
  }

  void createRoom() {
    normalizeRoleCounts();

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfiguracja gry jest niepoprawna.')),
      );
      return;
    }

    final hostName = hostNameController.text.trim().isEmpty
        ? 'Gospodarz'
        : hostNameController.text.trim();

    final room = LocalRoomService.createRoom(
      hostName: hostName,
      maxPlayers: players,
      roleCounts: roleCounts,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LobbyScreen(initialRoom: room, isHostView: true),
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
                                  label: 'Nazwa gospodarza',
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

    setState(() {
      errorMessage =
          'Dołączanie po kodzie dodamy przy prawdziwym lobby online. Na razie testuj lobby przez hostowanie.';
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
                                Shadow(color: Colors.white, blurRadius: 5),
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
                                    style: GoogleFonts.cormorantGaramond(
                                      color: Colors.redAccent,
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                const HelpHint(
                                  text:
                                      'Na razie lokalne lobby testujemy z poziomu gospodarza.',
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

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.initialRoom,
    required this.isHostView,
  });

  final GameRoom initialRoom;
  final bool isHostView;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late GameRoom room;

  int testPlayerNumber = 1;

  @override
  void initState() {
    super.initState();
    room = widget.initialRoom;
  }

  int get citizensCount {
    return GameRoles.citizensCount(
      players: room.maxPlayers,
      roleCounts: room.roleCounts,
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void addTestPlayer() {
    try {
      final updatedRoom = LocalRoomService.addPlayer(
        room: room,
        playerName: 'Gracz $testPlayerNumber',
      );

      setState(() {
        room = updatedRoom;
        testPlayerNumber++;
      });
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void startGame() {
    final error = LocalRoomService.startGameError(room);

    if (error != null) {
      showMessage(error);
      return;
    }

    try {
      final startedRoom = LocalRoomService.startGame(room);

      setState(() {
        room = startedRoom;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StartedGameScreen(room: startedRoom),
        ),
      );
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleSummary = <RoleSummary>[
      ...GameRoles.configurable.map((role) {
        return RoleSummary(
          name: role.name,
          value: GameRoles.countOf(room.roleCounts, role.type).toString(),
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
                                  room.roomCode,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cinzel(
                                    color: AppColors.neonWhite,
                                    fontSize: Responsive.isSmall(context)
                                        ? 36
                                        : 46,
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
                                  room.status == RoomStatus.waiting
                                      ? 'Przekaż ten kod graczom.'
                                      : 'Gra została rozpoczęta.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cormorantGaramond(
                                    color: Colors.white70,
                                    fontSize: Responsive.isSmall(context)
                                        ? 18
                                        : 20,
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
                                      '${room.players.length}/${room.maxPlayers}',
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
                                LobbyPlayerTile(
                                  name: room.hostName,
                                  isHost: true,
                                ),
                                ...room.players.map<Widget>((player) {
                                  return LobbyPlayerTile(
                                    name: player.name,
                                    isHost: false,
                                  );
                                }),
                                for (var i = 0; i < room.emptySlots; i++)
                                  EmptyPlayerSlot(
                                    slotNumber: room.players.length + i + 1,
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
                            height: Responsive.isSmall(context) ? 22 : 30,
                          ),
                          if (widget.isHostView &&
                              room.status == RoomStatus.waiting) ...[
                            MafiaButton(
                              text: 'Dodaj gracza testowego',
                              icon: Icons.person_add_alt_rounded,
                              onPressed: addTestPlayer,
                            ),
                            const SizedBox(height: 14),
                            MafiaButton(
                              text: 'Start gry',
                              icon: Icons.play_arrow_rounded,
                              onPressed: startGame,
                            ),
                          ] else if (room.status == RoomStatus.inProgress)
                            MafiaButton(
                              text: 'Karta gospodarza',
                              icon: Icons.style_rounded,
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
                                fontSize: Responsive.isSmall(context) ? 20 : 24,
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
// STARTED GAME SCREEN
// -----------------------------------------------------------------------------

class StartedGameScreen extends StatelessWidget {
  const StartedGameScreen({super.key, required this.room});

  final GameRoom room;

  void openHostCard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const RoleRevealScreen(roleType: MafiaRoleCardType.host),
      ),
    );
  }

  void openPlayerCard(BuildContext context, int playerIndex) {
    final player = room.players[playerIndex];
    final role = player.role;

    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ten gracz nie ma jeszcze przypisanej roli.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RoleRevealScreen(roleType: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleSummary = <RoleSummary>[
      ...GameRoles.configurable.map((role) {
        return RoleSummary(
          name: role.name,
          value: GameRoles.countOf(room.roleCounts, role.type).toString(),
        );
      }),
      RoleSummary(
        name: GameRoles.nameOf(MafiaRoleCardType.citizen),
        value: GameRoles.citizensCount(
          players: room.maxPlayers,
          roleCounts: room.roleCounts,
        ).toString(),
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
                            title: 'Gra rozpoczęta',
                            icon: Icons.play_arrow_rounded,
                            onBack: () => Navigator.pop(context),
                            showTitle: true,
                            showIcon: false,
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 28,
                          ),

                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Gospodarz',
                                  icon: Icons.person_rounded,
                                  showIcon: false,
                                ),

                                const SizedBox(height: 16),

                                LobbyPlayerTile(
                                  name: room.hostName,
                                  isHost: true,
                                ),

                                const SizedBox(height: 8),

                                MafiaButton(
                                  text: 'Karta gospodarza',
                                  icon: Icons.style_rounded,
                                  onPressed: () => openHostCard(context),
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
                                        title: 'Karty graczy',
                                        icon: Icons.style_outlined,
                                        showIcon: false,
                                      ),
                                    ),
                                    Text(
                                      '${room.players.length}/${room.maxPlayers}',
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

                                if (room.players.isEmpty)
                                  Text(
                                    'Brak graczy w pokoju.',
                                    style: GoogleFonts.cormorantGaramond(
                                      color: Colors.white70,
                                      fontSize: 19,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                else
                                  Column(
                                    children: List.generate(
                                      room.players.length,
                                      (index) {
                                        final player = room.players[index];
                                        final roleName = player.role == null
                                            ? 'Brak'
                                            : GameRoles.nameOf(player.role!);

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _StartedPlayerCardTile(
                                            playerName: player.name,
                                            playerNumber: index + 1,
                                            roleName: roleName,
                                            hasRole: player.role != null,
                                            onShowCard: () {
                                              openPlayerCard(context, index);
                                            },
                                          ),
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
                                  title: 'Podsumowanie talii',
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
                            height: Responsive.isSmall(context) ? 22 : 30,
                          ),

                          MafiaButton(
                            text: 'Wróć do menu',
                            icon: Icons.home_rounded,
                            onPressed: () {
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
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

class _StartedPlayerCardTile extends StatelessWidget {
  const _StartedPlayerCardTile({
    required this.playerName,
    required this.playerNumber,
    required this.roleName,
    required this.hasRole,
    required this.onShowCard,
  });

  final String playerName;
  final int playerNumber;
  final String roleName;
  final bool hasRole;
  final VoidCallback onShowCard;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 12 : 14,
        vertical: small ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.frame.withValues(alpha: 0.72)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 34,
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.neonWhite,
                    size: small ? 22 : 24,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: small ? 15 : 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Klasa: $roleName',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cormorantGaramond(
                      color: AppColors.neonWhite,
                      fontSize: small ? 17 : 19,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 4),
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
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: small ? 46 : 50,
            child: ElevatedButton(
              onPressed: hasRole ? onShowCard : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.58),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.black.withValues(alpha: 0.25),
                disabledForegroundColor: Colors.white38,
                side: BorderSide(
                  color: hasRole
                      ? AppColors.frame
                      : AppColors.frame.withValues(alpha: 0.28),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                hasRole ? 'POKAŻ KARTĘ' : 'BRAK KARTY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cinzel(
                  fontSize: small ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: hasRole ? Colors.white : Colors.white38,
                  shadows: hasRole
                      ? const [
                          Shadow(color: Colors.white, blurRadius: 4),
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: Offset(2, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
