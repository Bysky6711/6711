enum AuctionState { open, closed }

/// Length of the auction countdown, in seconds. The clock starts on the first
/// bid and resets to this value on every new bid; when it hits zero the auction
/// auto-closes and the last (highest) bidder wins.
const int kAuctionCountdownSeconds = 5;

/// A single card auction: rooms/{code}/auction/current. Players bid currency;
/// the highest bid wins the card and is charged on close.
class Auction {
  const Auction({
    required this.cardId,
    required this.state,
    this.bids = const {},
    this.winnerId,
    this.winnerName,
    this.winningBid = 0,
    this.endsAt,
  });

  final String cardId;
  final AuctionState state;
  final Map<String, int> bids;
  final String? winnerId;
  final String? winnerName;
  final int winningBid;

  /// Millis-since-epoch deadline for the resetting countdown. Null before the
  /// first bid (clock only starts once someone bids); each new bid pushes it to
  /// now + [kAuctionCountdownSeconds]. When it elapses the host auto-closes and
  /// the last (= highest) bidder wins.
  final int? endsAt;

  bool get isOpen => state == AuctionState.open;

  /// Whole seconds left on the countdown for [now], or null when no clock is
  /// running yet (no bids). Never negative.
  int? secondsLeft(DateTime now) {
    if (endsAt == null) return null;
    final ms = endsAt! - now.millisecondsSinceEpoch;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  int get highBid {
    var m = 0;
    for (final v in bids.values) {
      if (v > m) m = v;
    }
    return m;
  }

  String? get highBidderId {
    String? id;
    var m = -1;
    bids.forEach((key, value) {
      if (value > m) {
        m = value;
        id = key;
      }
    });
    return id;
  }

  Map<String, dynamic> toMap() => {
        'cardId': cardId,
        'state': state.name,
        'bids': bids,
        'winnerId': winnerId,
        'winnerName': winnerName,
        'winningBid': winningBid,
        'endsAt': endsAt,
      };

  factory Auction.fromMap(Map<String, dynamic> map) => Auction(
        cardId: map['cardId'] as String? ?? '',
        state: AuctionState.values.byName(map['state'] as String? ?? 'open'),
        bids: <String, int>{
          for (final e in ((map['bids'] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
        winnerId: map['winnerId'] as String?,
        winnerName: map['winnerName'] as String?,
        winningBid: (map['winningBid'] as num?)?.toInt() ?? 0,
        endsAt: (map['endsAt'] as num?)?.toInt(),
      );
}
