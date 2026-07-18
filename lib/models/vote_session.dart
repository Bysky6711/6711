/// A live day-vote stored at rooms/{code}/votes/current.
///
/// [ballots] maps a voter's playerId to the candidate name they voted for.
/// An empty string means the voter explicitly abstained ("Wstrzymaj się").
///
/// Ties are handled with a runoff: [round] is 1 for the first vote and 2 for a
/// runoff. When a runoff is running, [runoffCandidates] holds the tied names and
/// only those may be voted for. A tie in the runoff eliminates nobody.
enum VoteState { open, closed }

class VoteSession {
  const VoteSession({
    required this.state,
    this.startedAt,
    this.ballots = const {},
    this.round = 1,
    this.runoffCandidates = const [],
  });

  final VoteState state;
  final DateTime? startedAt;
  final Map<String, String> ballots;
  final int round;
  final List<String> runoffCandidates;

  bool get isOpen => state == VoteState.open;

  /// True while a runoff (2nd round) is in progress.
  bool get isRunoff => round >= 2 && runoffCandidates.isNotEmpty;

  /// Candidate name -> number of votes (abstentions/empty are ignored).
  Map<String, int> get tally {
    final counts = <String, int>{};
    for (final target in ballots.values) {
      if (target.trim().isEmpty) continue;
      counts[target] = (counts[target] ?? 0) + 1;
    }
    return counts;
  }

  /// How many voters have cast a real (non-abstain) vote.
  int get castCount =>
      ballots.values.where((t) => t.trim().isNotEmpty).length;

  /// The current front-runner, or null when nobody has votes yet.
  String? get leader {
    String? best;
    var bestVotes = 0;
    tally.forEach((name, votes) {
      if (votes > bestVotes) {
        bestVotes = votes;
        best = name;
      }
    });
    return best;
  }

  /// Names tied for the highest vote count (empty when no votes cast).
  List<String> get topCandidates {
    final t = tally;
    if (t.isEmpty) return const [];
    final max = t.values.reduce((a, b) => a > b ? a : b);
    return [
      for (final e in t.entries)
        if (e.value == max) e.key,
    ];
  }

  /// True when the highest vote count is shared by more than one candidate.
  bool get isTie => topCandidates.length > 1;

  /// The single candidate to eliminate, or null on a tie / when nobody voted.
  String? get decisiveTarget =>
      topCandidates.length == 1 ? topCandidates.first : null;

  Map<String, dynamic> toMap() => {
        'state': state.name,
        'startedAt': startedAt?.millisecondsSinceEpoch,
        'ballots': ballots,
        'round': round,
        'runoffCandidates': runoffCandidates,
      };

  factory VoteSession.fromMap(Map<String, dynamic> map) => VoteSession(
        state: VoteState.values.firstWhere(
          (e) => e.name == (map['state'] as String?),
          orElse: () => VoteState.closed,
        ),
        startedAt: map['startedAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((map['startedAt'] as num).toInt()),
        ballots: ((map['ballots'] as Map?) ?? const {}).map(
          (key, value) => MapEntry(key as String, (value as String?) ?? ''),
        ),
        round: (map['round'] as num?)?.toInt() ?? 1,
        runoffCandidates: ((map['runoffCandidates'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}
