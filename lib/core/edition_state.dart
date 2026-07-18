import '../models/game_edition.dart';

/// Global "which edition is currently being played" flag. Set when a room loads
/// (base vs medieval) so shared chrome — background, glow, reveal ceremony —
/// can theme itself without threading `edition` through every widget.
GameEdition activeEdition = GameEdition.standard;
