import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/edition_state.dart';
import '../core/responsive.dart';
import '../core/session_store.dart';
import '../data/card.dart';
import '../data/roles.dart';
import '../models/game_player.dart';
import '../models/game_room.dart';
import '../services/online_room_service.dart';
import '../ui_system/mafia_ios_system.dart';
import 'started_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({
    super.key,
    required this.roomCode,
    required this.myPlayerId,
    required this.isHost,
  });

  final String roomCode;
  final String myPlayerId;
  final bool isHost;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final OnlineRoomService service = OnlineRoomService();
  bool _navigated = false;
  bool _starting = false;
  bool _wasInRoom = false;

  @override
  void initState() {
    super.initState();
    SessionStore.save(GameSession(roomCode: widget.roomCode, playerId: widget.myPlayerId, isHost: widget.isHost));
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  GamePlayer? _findMe(GameRoom room) {
    for (final player in room.players) {
      if (player.id == widget.myPlayerId) return player;
    }
    return null;
  }

  Future<void> leave() async {
    if (!await confirmExitGame(context)) return;
    if (!mounted) return;
    await SessionStore.clear();
    if (!widget.isHost) {
      try {
        await service.removePlayer(code: widget.roomCode, playerId: widget.myPlayerId);
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _kickPlayer(GamePlayer player) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF33221F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Wyrzucić gracza?', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
        content: Text('Usunąć ${player.name} z pokoju?', style: TextStyle(color: AppColors.white.withValues(alpha: .7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Wyrzuć', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.kickPlayer(code: widget.roomCode, playerId: player.id);
    } catch (_) {}
  }

  Future<void> startGame(GameRoom room) async {
    if (_starting) return;
    // Tryb testowy: host o nicku "Byski" może wystartować bez kompletu graczy.
    final force = room.hostName.trim().toLowerCase() == 'byski';
    final error = service.startGameError(room);
    if (error != null && !force) {
      showMessage(error);
      return;
    }
    setState(() => _starting = true);
    try {
      await service.startGame(widget.roomCode, force: force);
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _goToGame(GameRoom room) async {
    if (_navigated || !mounted) return;
    _navigated = true;
    final me = _findMe(room);
    final myRole = widget.isHost ? MafiaRoleCardType.host : (me?.role ?? MafiaRoleCardType.citizen);
    final myName = widget.isHost ? room.hostName : (me?.name ?? 'Gracz');
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RoleRevealScreen(
          roleType: myRole,
          playerName: myName,
          playerId: widget.myPlayerId,
          roomCode: room.roomCode,
          edition: room.edition,
          medievalClass: me?.medievalClass,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StartedGameScreen(
          roomCode: widget.roomCode,
          myPlayerId: widget.myPlayerId,
          isHost: widget.isHost,
        ),
      ),
    );
  }

  int _citizens(GameRoom room) =>
      GameRoles.citizensCount(players: room.maxPlayers, roleCounts: room.roleCounts);

  @override
  Widget build(BuildContext context) {
    // The OS back gesture/button must NOT leave the lobby. Programmatic
    // navigation (boot, kicked, game start, explicit "leave" button) still works.
    //
    // The StreamBuilder sits ABOVE the scaffold on purpose: a player joining a
    // medieval room must get the medieval background. The scaffold reads the
    // global `activeEdition` when it paints the background, so we set it from the
    // room BEFORE building the scaffold — otherwise the background (an ancestor
    // of the stream) would keep the default red theme after joining.
    return PopScope(
      canPop: false,
      child: StreamBuilder<GameRoom?>(
        stream: service.watchRoom(widget.roomCode),
        builder: (context, snapshot) {
          final room = snapshot.data;
          if (room != null) activeEdition = room.edition; // theme by the room's edition
          return MafiaIOSScaffold(child: _lobbyBody(context, snapshot));
        },
      ),
    );
  }

  Widget _lobbyBody(BuildContext context, AsyncSnapshot<GameRoom?> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final room = snapshot.data;
    if (room == null) {
      return _LobbyMessage(
        text: 'Pokój został zamknięty lub nie istnieje.',
        onBack: () => Navigator.pop(context),
      );
    }
    final meInRoom = room.players.any((p) => p.id == widget.myPlayerId);
    if (meInRoom) _wasInRoom = true;
    if (!widget.isHost && !_navigated && _wasInRoom && !meInRoom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SessionStore.clear();
        Navigator.pop(context);
      });
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (room.isInProgress && !_navigated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToGame(room));
    }
    return _buildLobby(context, room);
  }

  Widget _buildLobby(BuildContext context, GameRoom room) {
    final me = _findMe(room);
    final canStart = widget.isHost && room.isWaiting;
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 14, Responsive.horizontalPadding(context), 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
              child: Column(children: [
                Row(children: [IOSBackButton(onTap: leave), const Expanded(child: LockClock(subtitle: 'Lobby')), const SizedBox(width: 50)]),
                const SizedBox(height: 18),
                LockNotificationTile(
                  title: 'Kod pokoju — dotknij, aby skopiować',
                  subtitle: room.roomCode,
                  trailingIcon: Icons.copy_rounded,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: room.roomCode));
                    showMessage('Skopiowano kod: ${room.roomCode}');
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isHost
                      ? 'Podaj ten kod graczom, aby dołączyli.'
                      : me == null
                          ? 'Dołączanie…'
                          : 'Jesteś w grze jako ${me.name}.',
                  style: TextStyle(color: AppColors.white.withValues(alpha: .64), fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                LockGlassPanel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('Gracze', style: TextStyle(color: AppColors.white.withValues(alpha: .90), fontSize: 18, fontWeight: FontWeight.w900))),
                      Text('${room.players.length}/${room.maxPlayers}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
                    ]),
                    const SizedBox(height: 12),
                    _PlayerLine(name: room.hostName, isHost: true, isMe: widget.isHost),
                    ...room.players.map((player) => _PlayerLine(name: player.name, isHost: false, isMe: player.id == widget.myPlayerId, onKick: widget.isHost ? () => _kickPlayer(player) : null)),
                    for (var i = 0; i < room.emptySlots; i++) _EmptyLine(number: room.players.length + i + 1),
                  ]),
                ),
                const SizedBox(height: 14),
                LockGlassPanel(
                  opacity: .14,
                  child: Column(children: [
                    ...GameRoles.configurable.map((role) => _SummaryLine(label: role.name, value: GameRoles.countOf(room.roleCounts, role.type).toString())),
                    _SummaryLine(label: GameRoles.nameOf(MafiaRoleCardType.citizen), value: _citizens(room).toString()),
                  ]),
                ),
                const SizedBox(height: 18),
                if (canStart)
                  LockButton(
                    text: _starting ? 'Startowanie…' : 'Start gry',
                    icon: Icons.play_arrow_rounded,
                    light: true,
                    onTap: () => startGame(room),
                  )
                else
                  Text(
                    'Czekaj, aż gospodarz rozpocznie grę…',
                    style: TextStyle(color: AppColors.white.withValues(alpha: .70), fontWeight: FontWeight.w800),
                  ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

class _LobbyMessage extends StatelessWidget {
  const _LobbyMessage({required this.text, required this.onBack});
  final String text;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.meeting_room_outlined, color: AppColors.white.withValues(alpha: .7), size: 48),
          const SizedBox(height: 14),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          LockButton(text: 'Wróć', icon: Icons.arrow_back_rounded, onTap: onBack),
        ]),
      ),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({required this.name, required this.isHost, this.isMe = false, this.onKick});
  final String name;
  final bool isHost;
  final bool isMe;
  final VoidCallback? onKick;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: isMe ? .18 : .10), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(isHost ? Icons.local_activity_rounded : Icons.person_rounded, color: AppColors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(isMe ? '$name (Ty)' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900))),
          if (isHost) const Text('HOST', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 12)),
          if (onKick != null && !isHost && !isMe)
            GestureDetector(
              onTap: onKick,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.person_remove_rounded, color: Colors.redAccent.withValues(alpha: .85), size: 20),
              ),
            ),
        ]),
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
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(color: AppColors.white.withValues(alpha: .64), fontWeight: FontWeight.w800))),
          Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
        ]),
      );
}
