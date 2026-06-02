import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../data/roles.dart';
import '../models/role_setting.dart';
import '../models/role_summary.dart';
import '../services/local_room_service.dart';
import '../services/room_service.dart';
import '../widgets/shared_widgets.dart';
import 'lobby_screen.dart';

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  final TextEditingController hostNameController = TextEditingController();

  final RoomService roomService = const LocalRoomService();

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

    final room = roomService.createRoom(
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
