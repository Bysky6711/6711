enum AuctionState { open, closed }

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
  });

  final String cardId;
  final AuctionState state;
  final Map<String, int> bids;
  final String? winnerId;
  final String? winnerName;
  final int winningBid;

  bool get isOpen => state == AuctionState.open;

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
      );
}
