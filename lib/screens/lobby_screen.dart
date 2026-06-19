import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../data/card.dart';
import '../data/roles.dart';
import '../models/game_room.dart';
import '../models/role_summary.dart';
import '../models/room_status.dart';
import '../services/local_room_service.dart';
import '../services/room_service.dart';
import '../ui_system/mafia_ios_system.dart';
import '../widgets/shared_widgets.dart';
import 'started_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.initialRoom, required this.isHostView});
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

  int get citizensCount => GameRoles.citizensCount(players: room.maxPlayers, roleCounts: room.roleCounts);

  void showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  void addTestPlayer() {
    try {
      final updatedRoom = roomService.addPlayer(room: room, playerName: 'Gracz $testPlayerNumber');
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
      setState(() => room = startedRoom);
      await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => RoleRevealScreen(roleType: MafiaRoleCardType.host, playerName: room.hostName, playerId: room.hostId, roomCode: room.roomCode)));
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => StartedGameScreen(room: startedRoom)));
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleSummary = <RoleSummary>[
      ...GameRoles.configurable.map((role) => RoleSummary(name: role.name, value: GameRoles.countOf(room.roleCounts, role.type).toString())),
      RoleSummary(name: GameRoles.nameOf(MafiaRoleCardType.citizen), value: citizensCount.toString()),
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
                child: Column(children: [
                  Row(children: [IOSBackButton(onTap: () => Navigator.pop(context)), const Expanded(child: LockClock(subtitle: 'Lobby')), const SizedBox(width: 50)]),
                  const SizedBox(height: 22),
                  LockNotificationTile(title: 'Kod pokoju', subtitle: room.roomCode, trailingIcon: Icons.key_rounded, onTap: () {}),
                  const SizedBox(height: 12),
                  LockGlassPanel(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text('Gracze', style: TextStyle(color: AppColors.white.withValues(alpha: .90), fontSize: 18, fontWeight: FontWeight.w900))), Text('${room.players.length}/${room.maxPlayers}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900))]),
                      const SizedBox(height: 12),
                      _PlayerLine(name: room.hostName, isHost: true),
                      ...room.players.map((player) => _PlayerLine(name: player.name, isHost: false)),
                      for (var i = 0; i < room.emptySlots; i++) _EmptyLine(number: room.players.length + i + 1),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  LockGlassPanel(opacity: .14, child: Column(children: roleSummary.map((item) => _SummaryLine(label: item.name, value: item.value)).toList())),
                  const SizedBox(height: 18),
                  if (widget.isHostView && room.status == RoomStatus.waiting) ...[
                    LockButton(text: 'Dodaj gracza testowego', icon: Icons.person_add_alt_rounded, onTap: addTestPlayer),
                    const SizedBox(height: 12),
                    LockButton(text: 'Start gry', icon: Icons.play_arrow_rounded, light: true, onTap: startGame),
                  ] else
                    Text('Czekaj na start gry...', style: TextStyle(color: AppColors.white.withValues(alpha: .70), fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({required this.name, required this.isHost});
  final String name;
  final bool isHost;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [Icon(isHost ? Icons.local_activity_rounded : Icons.person_rounded, color: AppColors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900))), if (isHost) const Text('HOST', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 12))]),
      );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.number});
  final int number;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.person_add_alt_rounded, color: AppColors.white.withValues(alpha: .52), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Wolne miejsce $number', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.white.withValues(alpha: .58), fontWeight: FontWeight.w900))),
          Text('PUSTE', style: TextStyle(color: AppColors.white.withValues(alpha: .34), fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [Expanded(child: Text(label, style: TextStyle(color: AppColors.white.withValues(alpha: .64), fontWeight: FontWeight.w800))), Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900))]),
      );
}
