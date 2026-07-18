import 'package:shared_preferences/shared_preferences.dart';

/// The player's active room membership, persisted on the device so a browser
/// refresh (or app restart) can reconnect to the same game.
class GameSession {
  const GameSession({required this.roomCode, required this.playerId, required this.isHost});

  final String roomCode;
  final String playerId;
  final bool isHost;
}

class SessionStore {
  const SessionStore._();

  static const _kCode = 'mafia_room_code';
  static const _kId = 'mafia_player_id';
  static const _kHost = 'mafia_is_host';

  static Future<void> save(GameSession s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCode, s.roomCode);
    await p.setString(_kId, s.playerId);
    await p.setBool(_kHost, s.isHost);
  }

  static Future<GameSession?> load() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_kCode);
    if (code == null || code.isEmpty) return null;
    return GameSession(
      roomCode: code,
      playerId: p.getString(_kId) ?? '',
      isHost: p.getBool(_kHost) ?? false,
    );
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kCode);
    await p.remove(_kId);
    await p.remove(_kHost);
  }
}
