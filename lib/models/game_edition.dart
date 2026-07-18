/// Which content collection a room is playing.
///
/// [standard] = the base Mafia game (5 base roles + power cards).
/// [medieval] = "Edycja Średniowiecze" (10 court classes + 30 court cards,
/// Wpływy + kompromitacja + dowody). Both coexist in the codebase.
enum GameEdition { standard, medieval }

extension GameEditionX on GameEdition {
  bool get isMedieval => this == GameEdition.medieval;
  String get label => this == GameEdition.medieval ? 'Edycja Średniowiecze' : 'Edycja standardowa';
}
