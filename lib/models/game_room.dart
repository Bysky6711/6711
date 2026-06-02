import '../data/roles.dart';
import 'game_phase.dart';
import 'game_player.dart';
import 'room_status.dart';

class GameRoom {
  const GameRoom({
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    required this.maxPlayers,
    required this.roleCounts,
    required this.players,
    required this.status,
    required this.phase,
    required this.createdAt,
  });

  final String roomCode;
  final String hostId;
  final String hostName;
  final int maxPlayers;
  final Map<MafiaRoleCardType, int> roleCounts;
  final List<GamePlayer> players;
  final RoomStatus status;
  final GamePhase phase;
  final DateTime createdAt;

  int get currentPlayersCount => players.length;

  bool get isWaiting => status == RoomStatus.waiting;

  bool get isInProgress => status == RoomStatus.inProgress;

  bool get isFinished => status == RoomStatus.finished;

  bool get isFull => currentPlayersCount >= maxPlayers;

  int get emptySlots {
    final result = maxPlayers - currentPlayersCount;
    return result < 0 ? 0 : result;
  }

  int get specialRolesCount {
    return GameRoles.specialRolesCount(roleCounts);
  }

  int get citizensCount {
    return GameRoles.citizensCount(players: maxPlayers, roleCounts: roleCounts);
  }

  bool get hasEnoughPlayersToStart {
    return currentPlayersCount == maxPlayers;
  }

  bool get hasValidDeck {
    final deck = GameRoles.buildDeck(
      players: maxPlayers,
      roleCounts: roleCounts,
    );

    return deck.length == maxPlayers;
  }

  bool get canStartGame {
    return isWaiting && hasEnoughPlayersToStart && hasValidDeck;
  }

  GamePlayer? playerById(String playerId) {
    for (final player in players) {
      if (player.id == playerId) {
        return player;
      }
    }

    return null;
  }

  GameRoom copyWith({
    String? roomCode,
    String? hostId,
    String? hostName,
    int? maxPlayers,
    Map<MafiaRoleCardType, int>? roleCounts,
    List<GamePlayer>? players,
    RoomStatus? status,
    GamePhase? phase,
    DateTime? createdAt,
  }) {
    return GameRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      roleCounts: roleCounts ?? this.roleCounts,
      players: players ?? this.players,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
