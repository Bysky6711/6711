import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../data/card.dart';
import '../data/roles.dart';
import '../models/game_phase.dart';
import '../models/game_room.dart';
import '../models/role_summary.dart';
import '../services/local_room_service.dart';
import '../services/room_service.dart';
import '../widgets/shared_widgets.dart';

enum _HostPanelTab { roles, tasks, council, phases }

class StartedGameScreen extends StatefulWidget {
  const StartedGameScreen({super.key, required this.room});

  final GameRoom room;

  @override
  State<StartedGameScreen> createState() => _StartedGameScreenState();
}

class _StartedGameScreenState extends State<StartedGameScreen> {
  late GameRoom room;

  final RoomService roomService = const LocalRoomService();

  _HostPanelTab selectedTab = _HostPanelTab.phases;

  final List<_TableCardPlay> playedCards = [];

  int nextTestCardNumber = 1;
  int unreadCouncilCards = 0;

  @override
  void initState() {
    super.initState();
    room = widget.room;
  }

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

  void changePhase(GamePhase phase) {
    setState(() {
      room = roomService.changePhase(room: room, phase: phase);
    });
  }

  void addTestPlayedCard() {
    if (room.players.isEmpty) return;

    final playerIndex = (nextTestCardNumber - 1) % room.players.length;
    final player = room.players[playerIndex];

    setState(() {
      playedCards.add(
        _TableCardPlay(
          playerName: player.name,
          cardName: 'Karta $nextTestCardNumber',
        ),
      );

      nextTestCardNumber++;

      if (selectedTab != _HostPanelTab.council) {
        unreadCouncilCards++;
      }
    });
  }

  String phaseName(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup:
        return 'Przygotowanie';
      case GamePhase.day:
        return 'Dzień';
      case GamePhase.night:
        return 'Noc';
      case GamePhase.voting:
        return 'Głosowanie';
      case GamePhase.finished:
        return 'Koniec gry';
    }
  }

  String phaseDescription(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup:
        return 'Gospodarz decyduje, kiedy rozpocząć pierwszą część gry.';
      case GamePhase.day:
        return 'Trwa dzień. Gracze mogą rozmawiać, analizować i zagrywać karty dnia.';
      case GamePhase.night:
        return 'Trwa noc. Gospodarz prowadzi działania nocne i pilnuje kolejności wydarzeń.';
      case GamePhase.voting:
        return 'Trwa głosowanie. Gospodarz obserwuje głosy i decyduje o zakończeniu etapu.';
      case GamePhase.finished:
        return 'Gra została zakończona.';
    }
  }

  List<RoleSummary> currentRoleSummary() {
    final counts = <MafiaRoleCardType, int>{};

    for (final role in GameRoles.configurable) {
      counts[role.type] = 0;
    }

    counts[MafiaRoleCardType.citizen] = 0;

    for (final player in room.players) {
      final role = player.role;

      if (role == null) continue;

      counts[role] = (counts[role] ?? 0) + 1;
    }

    return [
      ...GameRoles.configurable.map((role) {
        return RoleSummary(
          name: role.name,
          value: (counts[role.type] ?? 0).toString(),
        );
      }),
      RoleSummary(
        name: GameRoles.nameOf(MafiaRoleCardType.citizen),
        value: (counts[MafiaRoleCardType.citizen] ?? 0).toString(),
      ),
    ];
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
                  vertical: 14,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 28,
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
                            title: 'Panel gospodarza',
                            icon: Icons.admin_panel_settings_rounded,
                            onBack: () => Navigator.pop(context),
                            showTitle: true,
                            showIcon: false,
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 14 : 18,
                          ),

                          _HostPanelTabs(
                            selectedTab: selectedTab,
                            councilBadgeCount: unreadCouncilCards,
                            onChanged: (tab) {
                              setState(() {
                                selectedTab = tab;

                                if (tab == _HostPanelTab.council) {
                                  unreadCouncilCards = 0;
                                }
                              });
                            },
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 14 : 18,
                          ),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 360),
                            switchInCurve: Curves.easeOutExpo,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              return _NeonPanelTransition(
                                animation: animation,
                                child: child,
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey<_HostPanelTab>(selectedTab),
                              child: _buildSelectedTab(context),
                            ),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 18 : 24,
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

  Widget _buildSelectedTab(BuildContext context) {
    switch (selectedTab) {
      case _HostPanelTab.roles:
        return _buildRolesTab(context);
      case _HostPanelTab.tasks:
        return _buildTasksTab(context);
      case _HostPanelTab.council:
        return _buildCouncilTab(context);
      case _HostPanelTab.phases:
        return _buildPhasesTab(context);
    }
  }

  Widget _buildRolesTab(BuildContext context) {
    final roleSummary = currentRoleSummary();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Gospodarz',
                icon: Icons.person_rounded,
                showIcon: false,
              ),
              const SizedBox(height: 14),
              LobbyPlayerTile(name: room.hostName, isHost: true),
              const SizedBox(height: 8),
              MafiaButton(
                text: 'Karta gospodarza',
                icon: Icons.style_rounded,
                onPressed: () => openHostCard(context),
              ),
            ],
          ),
        ),

        SizedBox(height: Responsive.isSmall(context) ? 14 : 18),

        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Role graczy',
                      icon: Icons.style_outlined,
                      showIcon: false,
                    ),
                  ),
                  Text(
                    '${room.players.length}/${room.maxPlayers}',
                    style: GoogleFonts.cinzel(
                      color: AppColors.neonWhite,
                      fontSize: Responsive.isSmall(context) ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                  children: List.generate(room.players.length, (index) {
                    final player = room.players[index];

                    final roleName = player.role == null
                        ? 'Brak'
                        : GameRoles.nameOf(player.role!);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
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
                  }),
                ),
            ],
          ),
        ),

        SizedBox(height: Responsive.isSmall(context) ? 14 : 18),

        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Pozostałe role',
                icon: Icons.analytics_outlined,
                showIcon: false,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 190),
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
      ],
    );
  }

  Widget _buildTasksTab(BuildContext context) {
    return MafiaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Zadania',
            icon: Icons.assignment_outlined,
            showIcon: false,
          ),
          const SizedBox(height: 16),
          Text(
            'Moduł zadań dodamy później.',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white70,
              fontSize: Responsive.isSmall(context) ? 19 : 22,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tutaj gospodarz będzie wybierał uczestników zadania, zwycięzców oraz liczbę kart przyznawanych jako nagroda.',
            style: GoogleFonts.cormorantGaramond(
              color: Colors.white54,
              fontSize: Responsive.isSmall(context) ? 16 : 18,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouncilTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Narada',
                icon: Icons.table_bar_rounded,
                showIcon: false,
              ),
              const SizedBox(height: 10),
              Text(
                'Wspólny stół gry. Tutaj pojawią się karty zagrane przez graczy.',
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white70,
                  fontSize: Responsive.isSmall(context) ? 16 : 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 14),
              _DealerPanel(hostName: room.hostName),
            ],
          ),
        ),

        SizedBox(height: Responsive.isSmall(context) ? 14 : 18),

        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Stół narady',
                icon: Icons.style_outlined,
                showIcon: false,
              ),
              const SizedBox(height: 14),
              _CouncilTableArea(playedCards: playedCards),
              const SizedBox(height: 14),
              Center(
                child: MafiaButton(
                  text: 'Dodaj testową kartę',
                  icon: Icons.add_card_rounded,
                  onPressed: addTestPlayedCard,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: Responsive.isSmall(context) ? 14 : 18),

        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SectionHeader(
                      title: 'Gracze przy naradzie',
                      icon: Icons.people_alt_outlined,
                      showIcon: false,
                    ),
                  ),
                  Text(
                    room.players.length.toString(),
                    style: GoogleFonts.cinzel(
                      color: AppColors.neonWhite,
                      fontSize: Responsive.isSmall(context) ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CouncilPlayersGrid(
                players: room.players.map((player) => player.name).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhasesTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Aktualna faza',
                icon: Icons.timelapse_rounded,
                showIcon: false,
              ),
              const SizedBox(height: 14),
              Text(
                phaseName(room.phase).toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.cinzel(
                  color: AppColors.neonWhite,
                  fontSize: Responsive.isSmall(context) ? 30 : 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 6),
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
                phaseDescription(room.phase),
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  color: Colors.white70,
                  fontSize: Responsive.isSmall(context) ? 17 : 20,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: Responsive.isSmall(context) ? 14 : 18),

        MafiaPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SectionHeader(
                title: 'Akcje gospodarza',
                icon: Icons.tune_rounded,
                showIcon: false,
              ),
              const SizedBox(height: 16),
              _PhaseActions(
                currentPhase: room.phase,
                onDay: () => changePhase(GamePhase.day),
                onNight: () => changePhase(GamePhase.night),
                onVoting: () => changePhase(GamePhase.voting),
                onFinish: () => changePhase(GamePhase.finished),
              ),
            ],
          ),
        ),

        if (room.phase == GamePhase.voting) ...[
          SizedBox(height: Responsive.isSmall(context) ? 14 : 18),
          _VotingLivePanel(
            players: room.players.map((player) => player.name).toList(),
            onEndVoting: () => changePhase(GamePhase.day),
          ),
        ],
      ],
    );
  }
}

class _NeonPanelTransition extends StatelessWidget {
  const _NeonPanelTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final slideAnimation =
        Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutExpo,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    final scaleAnimation = Tween<double>(begin: 0.965, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final glow = animation.value.clamp(0.0, 1.0);

              return DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF2F7CFF,
                      ).withValues(alpha: 0.14 * glow),
                      blurRadius: 26 * glow,
                      spreadRadius: 1 * glow,
                    ),
                    BoxShadow(
                      color: const Color(
                        0xFFFF2BFF,
                      ).withValues(alpha: 0.10 * glow),
                      blurRadius: 34 * glow,
                      spreadRadius: 1 * glow,
                    ),
                  ],
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HostPanelTabs extends StatelessWidget {
  const _HostPanelTabs({
    required this.selectedTab,
    required this.councilBadgeCount,
    required this.onChanged,
  });

  final _HostPanelTab selectedTab;
  final int councilBadgeCount;
  final ValueChanged<_HostPanelTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return MafiaPanel(
      child: Row(
        children: [
          _HostPanelTabButton(
            label: 'Role',
            selected: selectedTab == _HostPanelTab.roles,
            onTap: () => onChanged(_HostPanelTab.roles),
          ),
          _HostPanelTabButton(
            label: 'Zadania',
            selected: selectedTab == _HostPanelTab.tasks,
            onTap: () => onChanged(_HostPanelTab.tasks),
          ),
          _HostPanelTabButton(
            label: 'Narada',
            selected: selectedTab == _HostPanelTab.council,
            badgeCount: councilBadgeCount,
            onTap: () => onChanged(_HostPanelTab.council),
          ),
          _HostPanelTabButton(
            label: 'Fazy',
            selected: selectedTab == _HostPanelTab.phases,
            onTap: () => onChanged(_HostPanelTab.phases),
          ),
        ],
      ),
    );
  }
}

class _HostPanelTabButton extends StatelessWidget {
  const _HostPanelTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: small ? 38 : 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.neonWhite.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? AppColors.neonWhite
                        : AppColors.frame.withValues(alpha: 0.45),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    style: GoogleFonts.cinzel(
                      color: selected ? AppColors.neonWhite : Colors.white70,
                      fontSize: small ? 11 : 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -3,
                  top: -7,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
        horizontal: small ? 10 : 12,
        vertical: small ? 10 : 12,
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
                width: 30,
                child: Center(
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.neonWhite,
                    size: small ? 20 : 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: small ? 14 : 16,
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
                    'Rola: $roleName',
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cormorantGaramond(
                      color: AppColors.neonWhite,
                      fontSize: small ? 16 : 18,
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: small ? 42 : 46,
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
                  fontSize: small ? 14 : 16,
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

class _DealerPanel extends StatelessWidget {
  const _DealerPanel({required this.hostName});

  final String hostName;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return Container(
      padding: EdgeInsets.all(small ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.frame.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          const MafiaHatIcon(size: 24, color: AppColors.neonWhite),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hostName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: small ? 14 : 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            'GOSPODARZ',
            style: GoogleFonts.cinzel(
              color: Colors.greenAccent,
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouncilTableArea extends StatelessWidget {
  const _CouncilTableArea({required this.playedCards});

  final List<_TableCardPlay> playedCards;

  void showLargeCard(BuildContext context, _TableCardPlay card) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Zamknij kartę',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _LargePlayedCardOverlay(
          cardName: card.cardName,
          playerName: card.playerName,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: Responsive.isSmall(context) ? 130 : 150,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF07101B).withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF6EA8FF).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: const Color(0xFF2E7BFF).withValues(alpha: 0.10),
            blurRadius: 20,
          ),
        ],
      ),
      child: playedCards.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Brak zagranych kart.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white60,
                    fontSize: Responsive.isSmall(context) ? 16 : 19,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: playedCards.map((card) {
                return _BlankPlayedCard(
                  cardName: card.cardName,
                  playerName: card.playerName,
                  onTap: () => showLargeCard(context, card),
                );
              }).toList(),
            ),
    );
  }
}

class _BlankPlayedCard extends StatefulWidget {
  const _BlankPlayedCard({
    required this.cardName,
    required this.playerName,
    required this.onTap,
  });

  final String cardName;
  final String playerName;
  final VoidCallback onTap;

  @override
  State<_BlankPlayedCard> createState() => _BlankPlayedCardState();
}

class _BlankPlayedCardState extends State<_BlankPlayedCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    final width = small ? 72.0 : 84.0;
    final height = width * 1.34;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          hovered = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: hovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: width,
            height: height,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFBFD7FF).withValues(alpha: 0.98),
                  const Color(0xFF2F7CFF).withValues(alpha: 0.96),
                  const Color(0xFF06172F).withValues(alpha: 0.98),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: hovered ? 16 : 9,
                  offset: Offset(0, hovered ? 8 : 5),
                ),
                if (hovered)
                  BoxShadow(
                    color: const Color(0xFF5FA8FF).withValues(alpha: 0.34),
                    blurRadius: 18,
                  ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF071B36),
                border: Border.all(
                  color: const Color(0xFFD9EAFF).withValues(alpha: 0.60),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.style_rounded,
                    color: const Color(0xFFD9EAFF),
                    size: small ? 20 : 24,
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      widget.cardName.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: small ? 8.5 : 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.playerName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cormorantGaramond(
                        color: Colors.white70,
                        fontSize: small ? 10 : 11,
                        fontStyle: FontStyle.italic,
                      ),
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

class _LargePlayedCardOverlay extends StatelessWidget {
  const _LargePlayedCardOverlay({
    required this.cardName,
    required this.playerName,
  });

  final String cardName;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 390 ? width * 0.74 : 310.0;
    final cardHeight = cardWidth * 1.48;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
              child: Container(color: Colors.black.withValues(alpha: 0.28)),
            ),
          ),

          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
          ),

          Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFBFD7FF).withValues(alpha: 0.98),
                      const Color(0xFF2F7CFF).withValues(alpha: 0.96),
                      const Color(0xFF06172F).withValues(alpha: 1.00),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.82),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: const Color(0xFF5FA8FF).withValues(alpha: 0.22),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(31),
                      color: const Color(0xFF041022),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.88),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: const Color(0xFF071B36),
                          border: Border.all(
                            color: const Color(
                              0xFFD9EAFF,
                            ).withValues(alpha: 0.76),
                            width: 1.4,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: RadialGradient(
                                  center: Alignment.topCenter,
                                  radius: 1.20,
                                  colors: [
                                    const Color(
                                      0xFF2F7CFF,
                                    ).withValues(alpha: 0.42),
                                    const Color(
                                      0xFF071B36,
                                    ).withValues(alpha: 0.86),
                                    Colors.black.withValues(alpha: 0.72),
                                  ],
                                ),
                              ),
                            ),

                            Positioned.fill(
                              child: CustomPaint(
                                painter: _BlueCardBorderPainter(),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.style_rounded,
                                    color: const Color(0xFFD9EAFF),
                                    size: width < 390 ? 64 : 74,
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    cardName.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cinzel(
                                      color: Colors.white,
                                      fontSize: width < 390 ? 28 : 34,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.8,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.white,
                                          blurRadius: 5,
                                        ),
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 12,
                                          offset: Offset(3, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    playerName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cormorantGaramond(
                                      color: Colors.white70,
                                      fontSize: width < 390 ? 24 : 28,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    'Dotknij poza kartą, aby zamknąć',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cormorantGaramond(
                                      color: Colors.white38,
                                      fontSize: width < 390 ? 15 : 17,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueCardBorderPainter extends CustomPainter {
  const _BlueCardBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE7F2FF), Color(0xFF6EA8FF), Color(0xFF1D4D9A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF6EA8FF).withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final thinPaint = Paint()
      ..color = const Color(0xFFD9EAFF).withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outerRect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);

    final innerRect = Rect.fromLTWH(18, 18, size.width - 36, size.height - 36);

    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(22)),
      glowPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(outerRect, const Radius.circular(22)),
      mainPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(17)),
      thinPaint,
    );

    void drawCorner({required bool right, required bool bottom}) {
      final x = right ? size.width - 30 : 30.0;
      final y = bottom ? size.height - 30 : 30.0;

      final sx = right ? -1.0 : 1.0;
      final sy = bottom ? -1.0 : 1.0;

      final path = Path()
        ..moveTo(x, y + sy * 26)
        ..quadraticBezierTo(x + sx * 2, y + sy * 8, x + sx * 18, y + sy * 2)
        ..moveTo(x, y + sy * 26)
        ..lineTo(x + sx * 10, y + sy * 18)
        ..moveTo(x + sx * 18, y + sy * 2)
        ..lineTo(x + sx * 26, y);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, mainPaint);
    }

    drawCorner(right: false, bottom: false);
    drawCorner(right: true, bottom: false);
    drawCorner(right: false, bottom: true);
    drawCorner(right: true, bottom: true);
  }

  @override
  bool shouldRepaint(covariant _BlueCardBorderPainter oldDelegate) {
    return false;
  }
}

class _CouncilPlayersGrid extends StatelessWidget {
  const _CouncilPlayersGrid({required this.players});

  final List<String> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Text(
        'Brak graczy przy naradzie.',
        style: GoogleFonts.cormorantGaramond(
          color: Colors.white70,
          fontSize: 18,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columns = width < 340
            ? 3
            : width < 520
            ? 4
            : width < 760
            ? 5
            : 6;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            return _CouncilPlayerTile(
              playerName: players[index],
              number: index + 1,
            );
          },
        );
      },
    );
  }
}

class _CouncilPlayerTile extends StatelessWidget {
  const _CouncilPlayerTile({required this.playerName, required this.number});

  final String playerName;
  final int number;

  @override
  Widget build(BuildContext context) {
    final small = Responsive.isSmall(context);

    return Container(
      padding: EdgeInsets.all(small ? 5 : 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.frame.withValues(alpha: 0.40)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: small ? 11 : 12,
            backgroundColor: Colors.black.withValues(alpha: 0.45),
            child: Text(
              number.toString(),
              style: GoogleFonts.cinzel(
                color: AppColors.neonWhite,
                fontSize: small ? 8.5 : 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            playerName,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontSize: small ? 8.5 : 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseActions extends StatelessWidget {
  const _PhaseActions({
    required this.currentPhase,
    required this.onDay,
    required this.onNight,
    required this.onVoting,
    required this.onFinish,
  });

  final GamePhase currentPhase;
  final VoidCallback onDay;
  final VoidCallback onNight;
  final VoidCallback onVoting;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (currentPhase != GamePhase.day) ...[
          Center(
            child: MafiaButton(
              text: 'Rozpocznij dzień',
              icon: Icons.wb_sunny_outlined,
              onPressed: onDay,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (currentPhase != GamePhase.night) ...[
          Center(
            child: MafiaButton(
              text: 'Rozpocznij noc',
              icon: Icons.nightlight_round,
              onPressed: onNight,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (currentPhase != GamePhase.voting) ...[
          Center(
            child: MafiaButton(
              text: 'Rozpocznij głosowanie',
              icon: Icons.how_to_vote_rounded,
              onPressed: onVoting,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Center(
          child: MafiaButton(
            text: 'Zakończ grę',
            icon: Icons.flag_rounded,
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}

class _VotingLivePanel extends StatelessWidget {
  const _VotingLivePanel({required this.players, required this.onEndVoting});

  final List<String> players;
  final VoidCallback onEndVoting;

  @override
  Widget build(BuildContext context) {
    return MafiaPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Głosowanie',
            icon: Icons.how_to_vote_rounded,
            showIcon: false,
          ),
          const SizedBox(height: 16),
          if (players.isEmpty)
            Text(
              'Brak graczy do głosowania.',
              style: GoogleFonts.cormorantGaramond(
                color: Colors.white70,
                fontSize: 19,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: players.map((player) {
                return SummaryText(
                  label: player,
                  value: 'Brak głosu',
                  valueColor: Colors.white70,
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          Center(
            child: MafiaButton(
              text: 'Zakończ głosowanie',
              icon: Icons.check_rounded,
              onPressed: onEndVoting,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCardPlay {
  const _TableCardPlay({required this.playerName, required this.cardName});

  final String playerName;
  final String cardName;
}
