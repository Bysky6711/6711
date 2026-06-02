import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../data/card.dart';
import '../data/roles.dart';
import '../models/game_room.dart';
import '../models/role_summary.dart';
import '../widgets/shared_widgets.dart';

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
                    'Rola: $roleName',
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
