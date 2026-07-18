import '../data/roles.dart';
import 'game_edition.dart';
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
    this.wallets = const {},
    this.edition = GameEdition.standard,
    this.wplywy = const {},
    this.roundNumber = 1,
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
  final Map<String, int> wallets;

  /// Which content collection this room plays (base vs medieval edition).
  final GameEdition edition;

  /// "Wpływy" — the medieval edition's second resource, parallel to [wallets].
  final Map<String, int> wplywy;

  /// Full turn counter (day+night+vote cycles), incremented when phase returns
  /// to day. Used by the medieval edition (Podrzutek 3-turn window etc).
  final int roundNumber;

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
    Map<String, int>? wallets,
    GameEdition? edition,
    Map<String, int>? wplywy,
    int? roundNumber,
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
      wallets: wallets ?? this.wallets,
      edition: edition ?? this.edition,
      wplywy: wplywy ?? this.wplywy,
      roundNumber: roundNumber ?? this.roundNumber,
    );
  }

  Map<String, dynamic> toMap() => {
        'roomCode': roomCode,
        'hostId': hostId,
        'hostName': hostName,
        'maxPlayers': maxPlayers,
        'roleCounts': {
          for (final entry in roleCounts.entries) entry.key.name: entry.value,
        },
        'players': players.map((player) => player.toMap()).toList(),
        'status': status.name,
        'phase': phase.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'wallets': wallets,
        'edition': edition.name,
        'wplywy': wplywy,
        'roundNumber': roundNumber,
      };

  factory GameRoom.fromMap(Map<String, dynamic> map) => GameRoom(
        roomCode: map['roomCode'] as String? ?? '',
        hostId: map['hostId'] as String? ?? '',
        hostName: map['hostName'] as String? ?? 'Gospodarz',
        maxPlayers: (map['maxPlayers'] as num?)?.toInt() ?? 0,
        roleCounts: <MafiaRoleCardType, int>{
          for (final entry
              in ((map['roleCounts'] as Map?) ?? const {}).entries)
            MafiaRoleCardType.values.byName(entry.key as String):
                (entry.value as num).toInt(),
        },
        players: ((map['players'] as List?) ?? const [])
            .map((e) => GamePlayer.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        status: RoomStatus.values.byName(map['status'] as String? ?? 'waiting'),
        phase: GamePhase.values.byName(map['phase'] as String? ?? 'setup'),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
        wallets: <String, int>{
          for (final entry in ((map['wallets'] as Map?) ?? const {}).entries)
            entry.key as String: (entry.value as num).toInt(),
        },
        edition: GameEdition.values.byName(map['edition'] as String? ?? 'standard'),
        wplywy: <String, int>{
          for (final entry in ((map['wplywy'] as Map?) ?? const {}).entries)
            entry.key as String: (entry.value as num).toInt(),
        },
        roundNumber: (map['roundNumber'] as num?)?.toInt() ?? 1,
      );
}
