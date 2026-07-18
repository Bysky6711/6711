enum GameTaskType { quiz }

enum GameTaskState { waiting, active, finished }

/// A competitive quiz round run by the host. Stored at rooms/{code}/tasks/current;
/// player submissions live in its `submissions` subcollection. 1st place wins
/// [prizeCardId]; the rest get decreasing money.
class GameTask {
  const GameTask({
    this.type = GameTaskType.quiz,
    required this.state,
    required this.prizeCardId,
    this.question,
    this.options = const [],
    this.correctIndex,
    this.createdAt,
    this.resultLines = const [],
    this.winnerName,
    this.imageUrl,
  });

  final GameTaskType type;
  final GameTaskState state;
  final String prizeCardId;
  final String? question;
  final List<String> options;
  final int? correctIndex;
  final int? createdAt;

  /// Optional image (https URL) shown above an image quiz question; null for a
  /// plain text question.
  final String? imageUrl;

  /// Human-readable ranking, filled in when the round is finished.
  final List<String> resultLines;
  final String? winnerName;

  bool get isQuiz => true;
  String get typeLabel => 'Quiz';

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'state': state.name,
        'prizeCardId': prizeCardId,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'createdAt': createdAt,
        'resultLines': resultLines,
        'winnerName': winnerName,
        'imageUrl': imageUrl,
      };

  factory GameTask.fromMap(Map<String, dynamic> map) => GameTask(
        state: GameTaskState.values.byName(map['state'] as String? ?? 'waiting'),
        prizeCardId: map['prizeCardId'] as String? ?? '',
        question: map['question'] as String?,
        options: ((map['options'] as List?) ?? const []).cast<String>(),
        correctIndex: (map['correctIndex'] as num?)?.toInt(),
        createdAt: (map['createdAt'] as num?)?.toInt(),
        resultLines: ((map['resultLines'] as List?) ?? const []).cast<String>(),
        winnerName: map['winnerName'] as String?,
        imageUrl: map['imageUrl'] as String?,
      );
}
