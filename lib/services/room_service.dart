import '../data/roles.dart';
import '../models/game_phase.dart';
import '../models/game_room.dart';

abstract class RoomService {
  GameRoom createRoom({
    required String hostName,
    required int maxPlayers,
    required Map<MafiaRoleCardType, int> roleCounts,
  });

  GameRoom addPlayer({required GameRoom room, required String playerName});

  GameRoom removePlayer({required GameRoom room, required String playerId});

  bool canStartGame(GameRoom room);

  String? startGameError(GameRoom room);

  GameRoom startGame(GameRoom room);

  GameRoom resetToLobby(GameRoom room);

  GameRoom changePhase({required GameRoom room, required GamePhase phase});

  String generateRoomCode();
}
