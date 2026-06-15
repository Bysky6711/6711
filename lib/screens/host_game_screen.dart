import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../data/roles.dart';
import '../models/role_setting.dart';
import '../models/role_summary.dart';
import '../services/local_room_service.dart';
import '../services/room_service.dart';
import '../ui_system/mafia_ios_system.dart';
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
  int get citizens => GameRoles.citizensCount(players: players, roleCounts: roleCounts);
  bool get isValid => specialRoles <= players;

  @override
  void dispose() {
    hostNameController.dispose();
    super.dispose();
  }

  int roleValue(MafiaRoleCardType type) => roleCounts[type] ?? 0;

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
    var total = GameRoles.specialRolesCount(roleCounts);
    if (total <= players) return;
    var over = total - players;
    for (final role in GameRoles.configurable.reversed) {
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
    var otherRolesCount = 0;
    for (final otherRole in GameRoles.configurable) {
      if (otherRole.type == role.type) continue;
      otherRolesCount += roleCounts[otherRole.type] ?? 0;
    }
    return math.min(role.max, math.max(role.min, players - otherRolesCount));
  }

  void createRoom() {
    normalizeRoleCounts();
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfiguracja gry jest niepoprawna.')));
      return;
    }
    final hostName = hostNameController.text.trim().isEmpty ? 'Gospodarz' : hostNameController.text.trim();
    final room = roomService.createRoom(hostName: hostName, maxPlayers: players, roleCounts: roleCounts);
    Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyScreen(initialRoom: room, isHostView: true)));
  }

  @override
  Widget build(BuildContext context) {
    final roleSettings = <RoleSetting>[
      RoleSetting(name: 'Liczba graczy', value: players, min: 4, max: 20, onChanged: setPlayers),
      ...GameRoles.configurable.map((role) => RoleSetting(name: role.name, value: roleValue(role.type), min: role.min, max: maxForRole(role), onChanged: (value) => setRoleValue(role.type, value))),
    ];
    final summary = <RoleSummary>[
      ...GameRoles.configurable.map((role) => RoleSummary(name: role.name, value: roleValue(role.type).toString())),
      RoleSummary(name: GameRoles.nameOf(MafiaRoleCardType.citizen), value: citizens.toString()),
      RoleSummary(name: 'Status', value: isValid ? 'Poprawna' : 'Za dużo ról', valueColor: isValid ? Colors.greenAccent : Colors.redAccent),
    ];

    return MafiaIOSScaffold(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 14, Responsive.horizontalPadding(context), 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
                child: Column(
                  children: [
                    Row(children: [IOSBackButton(onTap: () => Navigator.pop(context)), const Expanded(child: LockClock(subtitle: 'Nowy pokój')), const SizedBox(width: 50)]),
                    const SizedBox(height: 22),
                    LockNotificationTile(title: 'Mafia', subtitle: 'Panel gospodarza', trailingIcon: Icons.local_activity_rounded, onTap: createRoom),
                    const SizedBox(height: 12),
                    LockGlassPanel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nazwa gospodarza', style: TextStyle(color: AppColors.white.withValues(alpha: .74), fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        LockTextField(controller: hostNameController, hint: 'np. Wiktor'),
                        const SizedBox(height: 16),
                        ...roleSettings.map((role) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: LockCounterRow(title: role.name, value: role.value, min: role.min, max: role.max, onChanged: role.onChanged),
                            )),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    LockGlassPanel(
                      opacity: .14,
                      child: Column(children: summary.map((item) => _SummaryLine(label: item.name, value: item.value, valueColor: item.valueColor)).toList()),
                    ),
                    const SizedBox(height: 18),
                    LockButton(text: 'Utwórz pokój', icon: Icons.arrow_upward_rounded, light: true, onTap: createRoom),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.white.withValues(alpha: .64), fontSize: 15, fontWeight: FontWeight.w800))),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.white, fontSize: 15, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
