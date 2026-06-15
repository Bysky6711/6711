enum MafiaChatChannelType { general, mafia, private }

class MafiaChatChannel {
  const MafiaChatChannel({
    required this.id,
    required this.name,
    required this.type,
    this.targetPlayerName,
  });

  final String id;
  final String name;
  final MafiaChatChannelType type;
  final String? targetPlayerName;
}

class MafiaChatMessage {
  const MafiaChatMessage({
    required this.id,
    required this.channelId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isMine = false,
    this.isSystem = false,
  });

  final String id;
  final String channelId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final bool isSystem;
}
