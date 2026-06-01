import 'dart:math' as math;

enum MafiaRoleCardType {
  host,
  mafia,
  detective,
  doctor,
  sheriff,
  citizen,
}

class GameRoleDefinition {
  const GameRoleDefinition({
    required this.type,
    required this.name,
    required this.min,
    required this.max,
    required this.defaultCount,
    required this.isConfigurable,
    this.imagePath,
  });

  final MafiaRoleCardType type;
  final String name;
  final int min;
  final int max;
  final int defaultCount;
  final bool isConfigurable;
  final String? imagePath;
}

class GameRoles {
  const GameRoles._();

  static const List<GameRoleDefinition> all = [
    GameRoleDefinition(
      type: MafiaRoleCardType.host,
      name: 'Gospodarz',
      min: 0,
      max: 1,
      defaultCount: 0,
      isConfigurable: false,
    ),
    GameRoleDefinition(
      type: MafiaRoleCardType.mafia,
      name: 'Mafia',
      min: 1,
      max: 6,
      defaultCount: 1,
      isConfigurable: true,
    ),
    GameRoleDefinition(
      type: MafiaRoleCardType.detective,
      name: 'Detektyw',
      min: 0,
      max: 3,
      defaultCount: 1,
      isConfigurable: true,
    ),
    GameRoleDefinition(
      type: MafiaRoleCardType.doctor,
      name: 'Lekarz',
      min: 0,
      max: 3,
      defaultCount: 1,
      isConfigurable: true,
    ),
    GameRoleDefinition(
      type: MafiaRoleCardType.sheriff,
      name: 'Szeryf',
      min: 0,
      max: 2,
      defaultCount: 1,
      isConfigurable: true,
    ),
    GameRoleDefinition(
      type: MafiaRoleCardType.citizen,
      name: 'Mieszkańcy',
      min: 0,
      max: 99,
      defaultCount: 0,
      isConfigurable: false,
    ),
  ];

  static List<GameRoleDefinition> get configurable {
    return all.where((role) => role.isConfigurable).toList();
  }

  static GameRoleDefinition definitionOf(MafiaRoleCardType type) {
    return all.firstWhere((role) => role.type == type);
  }

  static String nameOf(MafiaRoleCardType type) {
    return definitionOf(type).name;
  }

  static Map<MafiaRoleCardType, int> defaultRoleCounts() {
    return {
      for (final role in configurable) role.type: role.defaultCount,
    };
  }

  static int countOf(
    Map<MafiaRoleCardType, int> roleCounts,
    MafiaRoleCardType type,
  ) {
    return roleCounts[type] ?? 0;
  }

  static int specialRolesCount(Map<MafiaRoleCardType, int> roleCounts) {
    var result = 0;

    for (final role in configurable) {
      result += roleCounts[role.type] ?? 0;
    }

    return result;
  }

  static int citizensCount({
    required int players,
    required Map<MafiaRoleCardType, int> roleCounts,
  }) {
    final citizens = players - specialRolesCount(roleCounts);

    return math.max(0, citizens);
  }

  static bool isConfigurationValid({
    required int players,
    required Map<MafiaRoleCardType, int> roleCounts,
  }) {
    return citizensCount(
          players: players,
          roleCounts: roleCounts,
        ) >=
        0;
  }

  static List<MafiaRoleCardType> buildDeck({
    required int players,
    required Map<MafiaRoleCardType, int> roleCounts,
  }) {
    final deck = <MafiaRoleCardType>[];

    for (final role in configurable) {
      final count = roleCounts[role.type] ?? 0;

      for (var i = 0; i < count; i++) {
        deck.add(role.type);
      }
    }

    final citizens = citizensCount(
      players: players,
      roleCounts: roleCounts,
    );

    for (var i = 0; i < citizens; i++) {
      deck.add(MafiaRoleCardType.citizen);
    }

    return deck;
  }
}