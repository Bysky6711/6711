import 'package:flutter/material.dart';
import '../core/edition_state.dart';
import '../core/responsive.dart';
import '../core/session_store.dart';
import '../models/game_edition.dart';
import '../services/online_room_service.dart';
import '../ui_system/mafia_ios_system.dart';
import 'host_game_screen.dart';
import 'join_game_screen.dart';
import 'lobby_screen.dart';
import 'started_game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final OnlineRoomService _service = OnlineRoomService();
  GameSession? _saved;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final s = await SessionStore.load();
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _reconnect(GameSession s) async {
    final room = await _service.getRoom(s.roomCode);
    if (!mounted) return;
    if (room == null) {
      await SessionStore.clear();
      if (!mounted) return;
      setState(() => _saved = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pokój już nie istnieje.')));
      return;
    }
    activeEdition = room.edition; // theme the reconnected lobby/game by its edition
    final page = room.isInProgress
        ? StartedGameScreen(roomCode: s.roomCode, myPlayerId: s.playerId, isHost: s.isHost)
        : LobbyScreen(roomCode: s.roomCode, myPlayerId: s.playerId, isHost: s.isHost);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _loadSession();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _loadSession());
  }

  @override
  Widget build(BuildContext context) {
    activeEdition = GameEdition.standard; // the menu is neutral — never leave a medieval theme lingering here
    return MafiaIOSScaffold(
      darkOverlay: .03,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context), vertical: 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LockClock(),
                      SizedBox(height: Responsive.height(context) * .06),
                      if (_saved != null) ...[
                        LockNotificationTile(
                          title: 'Wróć do gry',
                          subtitle: 'Pokój ${_saved!.roomCode}',
                          trailingIcon: Icons.replay_rounded,
                          onTap: () => _reconnect(_saved!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      LockNotificationTile(
                        title: 'Mafia',
                        subtitle: 'Dołącz do gry',
                        trailingIcon: Icons.sports_esports_rounded,
                        onTap: () => _open(const JoinGameScreen()),
                      ),
                      const SizedBox(height: 12),
                      LockNotificationTile(
                        title: 'Mafia',
                        subtitle: 'Zostań gospodarzem',
                        trailingIcon: Icons.local_activity_rounded,
                        onTap: () => _open(const HostGameScreen()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
