import '../models/game_edition.dart';
import 'medieval_cards.dart';
import 'power_cards.dart';

/// The card pool for an edition (base power cards vs medieval court cards).
List<PowerCardDefinition> cardsFor(GameEdition edition) =>
    edition.isMedieval ? MedievalCards.all : PowerCards.all;

/// Resolves a card id across BOTH editions (base + medieval), so feeds, hands
/// and logs render the right card regardless of which edition dealt it.
PowerCardDefinition cardById(String id) {
  for (final c in PowerCards.all) {
    if (c.id == id) return c;
  }
  for (final c in MedievalCards.all) {
    if (c.id == id) return c;
  }
  return PowerCards.all.first;
}
