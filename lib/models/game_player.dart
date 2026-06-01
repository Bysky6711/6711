import '../data/roles.dart';

class GamePlayer {
  const GamePlayer({
    required this.id,
    required this.name,
    required this.joinedAt,
    this.role,
  });

  final String id;
  final String name;
  final DateTime joinedAt;
  final MafiaRoleCardType? role;

  bool get hasRole => role != null;

  GamePlayer copyWith({
    String? id,
    String? name,
    DateTime? joinedAt,
    MafiaRoleCardType? role,
    bool clearRole = false,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
      role: clearRole ? null : role ?? this.role,
    );
  }
}
