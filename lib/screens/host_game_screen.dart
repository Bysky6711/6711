import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../core/edition_state.dart';
import '../data/medieval_classes.dart';
import '../data/roles.dart';
import '../models/game_edition.dart';
import '../models/role_setting.dart';
import '../models/role_summary.dart';
import '../services/online_room_service.dart';
import '../ui_system/mafia_ios_system.dart';
import 'lobby_screen.dart';

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({super.key});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  final TextEditingController hostNameController = TextEditingController();
  final OnlineRoomService roomService = OnlineRoomService();
  int players = 6;
  bool creating = false;
  GameEdition edition = GameEdition.standard;
  Map<MafiaRoleCardType, int> roleCounts = GameRoles.defaultRoleCounts();

  int get specialRoles => GameRoles.specialRolesCount(roleCounts);
  int get citizens => GameRoles.citizensCount(players: players, roleCounts: roleCounts);
  bool get isValid => specialRoles <= players;

  @override
  void initState() {
    super.initState();
    activeEdition = edition; // theme this screen from the start
  }

  @override
  void dispose() {
    activeEdition = GameEdition.standard; // don't leak the medieval theme to the menu
    hostNameController.dispose();
    super.dispose();
  }

  int roleValue(MafiaRoleCardType type) => roleCounts[type] ?? 0;

  String _faction(MedievalFaction f) => switch (f) {
        MedievalFaction.antagonisci => 'Ród Węża',
        MedievalFaction.korona => 'Korona',
        MedievalFaction.neutralny => 'Neutralny',
        MedievalFaction.niezdeklarowany => 'Podrzutek',
      };

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

  Future<void> createRoom() async {
    if (creating) return;
    normalizeRoleCounts();
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfiguracja gry jest niepoprawna.')));
      return;
    }
    setState(() => creating = true);
    activeEdition = edition; // theme the lobby/game immediately
    final hostName = hostNameController.text.trim().isEmpty ? 'Gospodarz' : hostNameController.text.trim();
    try {
      final room = await roomService.createRoom(hostName: hostName, maxPlayers: players, roleCounts: roleCounts, edition: edition);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(roomCode: room.roomCode, myPlayerId: room.hostId, isHost: true),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nie udało się utworzyć pokoju: ${error.toString().replaceFirst('Exception: ', '')}')));
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  Widget _editionOption(GameEdition e, String title, String desc, IconData icon, Color color) {
    final selected = edition == e;
    return GestureDetector(
      onTap: () => setState(() {
        edition = e;
        activeEdition = e; // live-preview the background/theme
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .16) : Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? color : Colors.white.withValues(alpha: .12), width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: .2), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: .6))),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(desc, style: TextStyle(color: AppColors.white.withValues(alpha: .62), fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3)),
            ]),
          ),
          const SizedBox(width: 8),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? color : Colors.white.withValues(alpha: .3)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medieval = edition.isMedieval;
    final roleSettings = <RoleSetting>[
      RoleSetting(name: 'Liczba graczy', value: players, min: 4, max: 20, onChanged: setPlayers),
      if (!medieval) ...GameRoles.configurable.map((role) => RoleSetting(name: role.name, value: roleValue(role.type), min: role.min, max: maxForRole(role), onChanged: (value) => setRoleValue(role.type, value))),
    ];
    final summary = medieval
        ? <RoleSummary>[
            RoleSummary(name: 'Antagoniści (Ród Węża)', value: '${players <= 6 ? 1 : players <= 11 ? 2 : 3}'),
            RoleSummary(name: 'Klasy Korony', value: 'losowane'),
            RoleSummary(name: 'Status', value: 'Gotowe', valueColor: Colors.greenAccent),
          ]
        : <RoleSummary>[
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
                        Text('Wybierz edycję', style: TextStyle(color: AppColors.white.withValues(alpha: .74), fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        _editionOption(GameEdition.standard, 'Edycja standardowa', 'Klasyczna Mafia: role, karty mocy, zadania i licytacja.', Icons.local_fire_department_rounded, const Color(0xFFE5404F)),
                        const SizedBox(height: 10),
                        _editionOption(GameEdition.medieval, 'Edycja Średniowiecze', 'Intrygi dworskie: 10 klas, 30 kart, Wpływy i kompromitacja.', Icons.castle_rounded, const Color(0xFFC9A227)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    LockGlassPanel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(medieval ? 'Imię króla' : 'Nazwa gospodarza', style: TextStyle(color: AppColors.white.withValues(alpha: .74), fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        LockTextField(controller: hostNameController, hint: medieval ? 'Imię króla' : 'Twój nick'),
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
                    if (medieval) ...[
                      const SizedBox(height: 14),
                      LockGlassPanel(
                        opacity: .14,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Klasy dworskie (losowane automatycznie)', style: TextStyle(color: AppColors.white.withValues(alpha: .74), fontSize: 13, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          ...MedievalClasses.all.map((c) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Icon(c.icon, color: const Color(0xFFC9A227), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(c.name, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w800))),
                                  Text(_faction(c.faction), style: TextStyle(color: AppColors.white.withValues(alpha: .55), fontSize: 11, fontWeight: FontWeight.w700)),
                                ]),
                              )),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 18),
                    LockButton(text: creating ? 'Tworzenie…' : 'Utwórz pokój', icon: Icons.arrow_upward_rounded, light: true, onTap: createRoom),
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
