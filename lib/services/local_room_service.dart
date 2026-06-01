import 'dart:math' as math;

import '../data/roles.dart';
import '../models/game_player.dart';
import '../models/game_room.dart';
import '../models/room_status.dart';

class LocalRoomService {
  const LocalRoomService._();

  static GameRoom createRoom({
    required String hostName,
    required int maxPlayers,
    required Map<MafiaRoleCardType, int> roleCounts,
  }) {
    final hostId = _generateId(prefix: 'host');
    final roomCode = generateRoomCode();

    return GameRoom(
      roomCode: roomCode,
      hostId: hostId,
      hostName: hostName,
      maxPlayers: maxPlayers,
      roleCounts: Map<MafiaRoleCardType, int>.from(roleCounts),
      players: const [],
      status: RoomStatus.waiting,
      createdAt: DateTime.now(),
    );
  }

  static GameRoom addPlayer({
    required GameRoom room,
    required String playerName,
  }) {
    if (!room.isWaiting) {
      throw Exception('Nie można dołączyć. Gra już wystartowała.');
    }

    if (room.isFull) {
      throw Exception('Pokój jest pełny.');
    }

    final trimmedName = playerName.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Nazwa gracza nie może być pusta.');
    }

    final player = GamePlayer(
      id: _generateId(prefix: 'player'),
      name: trimmedName,
      joinedAt: DateTime.now(),
    );

    return room.copyWith(players: [...room.players, player]);
  }

  static GameRoom removePlayer({
    required GameRoom room,
    required String playerId,
  }) {
    if (!room.isWaiting) {
      throw Exception('Nie można usunąć gracza po rozpoczęciu gry.');
    }

    final updatedPlayers = room.players.where((player) {
      return player.id != playerId;
    }).toList();

    return room.copyWith(players: updatedPlayers);
  }

  static bool canStartGame(GameRoom room) {
    return room.canStartGame;
  }

  static String? startGameError(GameRoom room) {
    if (!room.isWaiting) {
      return 'Gra już została rozpoczęta.';
    }

    if (room.currentPlayersCount < room.maxPlayers) {
      return 'Brakuje graczy: ${room.currentPlayersCount}/${room.maxPlayers}.';
    }

    if (room.currentPlayersCount > room.maxPlayers) {
      return 'W pokoju jest za dużo graczy.';
    }

    if (!room.hasValidDeck) {
      return 'Liczba kart ról nie zgadza się z liczbą graczy.';
    }

    return null;
  }

  static GameRoom startGame(GameRoom room) {
    final error = startGameError(room);

    if (error != null) {
      throw Exception(error);
    }

    final deck = GameRoles.buildDeck(
      players: room.maxPlayers,
      roleCounts: room.roleCounts,
    );

    if (deck.length != room.players.length) {
      throw Exception('Liczba kart nie pasuje do liczby graczy.');
    }

    final shuffledDeck = List<MafiaRoleCardType>.from(deck)..shuffle();

    final updatedPlayers = <GamePlayer>[];

    for (var i = 0; i < room.players.length; i++) {
      updatedPlayers.add(room.players[i].copyWith(role: shuffledDeck[i]));
    }

    return room.copyWith(
      players: updatedPlayers,
      status: RoomStatus.inProgress,
    );
  }

  static GameRoom resetToLobby(GameRoom room) {
    final playersWithoutRoles = room.players.map((player) {
      return player.copyWith(clearRole: true);
    }).toList();

    return room.copyWith(
      players: playersWithoutRoles,
      status: RoomStatus.waiting,
    );
  }

  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random.secure();

    return List.generate(
      5,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  static String _generateId({required String prefix}) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random().nextInt(999999);

    return '${prefix}_${timestamp}_$random';
  }
}
