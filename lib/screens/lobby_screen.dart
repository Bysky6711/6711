import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../data/card.dart';
import '../data/roles.dart';
import '../models/game_room.dart';
import '../models/role_summary.dart';
import '../models/room_status.dart';
import '../services/local_room_service.dart';
import '../services/room_service.dart';
import '../widgets/shared_widgets.dart';
import 'started_game_screen.dart';

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

  final RoomService roomService = const LocalRoomService();

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
      final updatedRoom = roomService.addPlayer(
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

  Future<void> startGame() async {
    final error = roomService.startGameError(room);

    if (error != null) {
      showMessage(error);
      return;
    }

    try {
      final startedRoom = roomService.startGame(room);

      setState(() {
        room = startedRoom;
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const RoleRevealScreen(roleType: MafiaRoleCardType.host),
        ),
      );

      if (!mounted) return;

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
