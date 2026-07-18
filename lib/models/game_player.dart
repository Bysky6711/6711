import '../data/medieval_classes.dart';
import '../data/roles.dart';

class GamePlayer {
  const GamePlayer({
    required this.id,
    required this.name,
    required this.joinedAt,
    this.role,
    this.alive = true,
    this.statuses = const [],
    this.medievalClass,
    this.podrzutekFaction,
  });

  final String id;
  final String name;
  final DateTime joinedAt;
  final MafiaRoleCardType? role;

  /// Whether the player is still in the game (host toggles this).
  final bool alive;

  /// Active card-effect tags (e.g. poisoned, blocked, protected, marked, bound).
  final List<String> statuses;

  /// Assigned class in the medieval edition (null in the base game).
  final MedievalClassType? medievalClass;

  /// Podrzutek's declared faction (medieval edition), once chosen.
  final MedievalFaction? podrzutekFaction;

  bool get hasRole => role != null;

  GamePlayer copyWith({
    String? id,
    String? name,
    DateTime? joinedAt,
    MafiaRoleCardType? role,
    bool clearRole = false,
    bool? alive,
    List<String>? statuses,
    MedievalClassType? medievalClass,
    bool clearMedievalClass = false,
    MedievalFaction? podrzutekFaction,
    bool clearPodrzutek = false,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
      role: clearRole ? null : role ?? this.role,
      alive: alive ?? this.alive,
      statuses: statuses ?? this.statuses,
      medievalClass: clearMedievalClass ? null : medievalClass ?? this.medievalClass,
      podrzutekFaction: clearPodrzutek ? null : podrzutekFaction ?? this.podrzutekFaction,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'joinedAt': joinedAt.millisecondsSinceEpoch,
        'role': role?.name,
        'alive': alive,
        'statuses': statuses,
        'medievalClass': medievalClass?.name,
        'podrzutekFaction': podrzutekFaction?.name,
      };

  factory GamePlayer.fromMap(Map<String, dynamic> map) => GamePlayer(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        joinedAt: DateTime.fromMillisecondsSinceEpoch(
          (map['joinedAt'] as num?)?.toInt() ?? 0,
        ),
        role: map['role'] == null
            ? null
            : MafiaRoleCardType.values.byName(map['role'] as String),
        alive: map['alive'] as bool? ?? true,
        statuses: ((map['statuses'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        medievalClass: map['medievalClass'] == null
            ? null
            : MedievalClassType.values.byName(map['medievalClass'] as String),
        podrzutekFaction: map['podrzutekFaction'] == null
            ? null
            : MedievalFaction.values.byName(map['podrzutekFaction'] as String),
      );
}
