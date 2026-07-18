enum MafiaChatChannelType { general, mafia, private, dead }

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
    this.imageBase64,
  });

  final String id;
  final String channelId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final bool isSystem;

  /// Optional inline sticker: a compressed JPG encoded as base64.
  final String? imageBase64;

  Map<String, dynamic> toMap() => {
        'channelId': channelId,
        'senderName': senderName,
        'text': text,
        'imageData': imageBase64,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'isSystem': isSystem,
      };

  factory MafiaChatMessage.fromDoc(
    String docId,
    Map<String, dynamic> map, {
    required String myName,
  }) =>
      MafiaChatMessage(
        id: docId,
        channelId: map['channelId'] as String? ?? 'general',
        senderName: map['senderName'] as String? ?? '',
        text: map['text'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
        isSystem: map['isSystem'] as bool? ?? false,
        isMine: (map['senderName'] as String?) == myName,
        imageBase64: map['imageData'] as String?,
      );
}

/// Deterministic id for a 1:1 private channel between two players.
/// Sorted case-insensitively so both participants resolve to the same channel.
String dmChannelId(String a, String b) {
  final pair = [a, b]..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
  return 'dm::${pair[0]}::${pair[1]}';
}
