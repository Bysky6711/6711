import 'package:flutter/material.dart';

import '../models/game_phase.dart';
import 'medieval_cards.dart';

/// Resolves a card id across both editions (base + medieval).
PowerCardDefinition _resolveAnyCard(String id) {
  for (final c in PowerCards.all) {
    if (c.id == id) return c;
  }
  for (final c in MedievalCards.all) {
    if (c.id == id) return c;
  }
  return PowerCards.all.first;
}

enum PowerCardTargetMode { none, onePlayer, twoPlayers, selfOrPlayer, cardOrEffect }

enum PowerCardTiming { day, night, voting, automatic, death, any }

class PowerCardDefinition {
  const PowerCardDefinition({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.effectDescription,
    required this.timing,
    required this.targetMode,
    required this.icon,
    required this.color,
    this.consumesOnUse = true,
    this.requiresHostApproval = true,
    this.requiresConsent = false,
    this.citizenOnly = false,
    this.automatic = false,
    this.secret = true,
  });

  final String id;
  final String name;
  final String shortDescription;
  final String effectDescription;
  final PowerCardTiming timing;
  final PowerCardTargetMode targetMode;
  final IconData icon;
  final Color color;
  final bool consumesOnUse;
  final bool requiresHostApproval;
  final bool requiresConsent;
  final bool citizenOnly;
  final bool automatic;
  final bool secret;

  String get timingLabel {
    switch (timing) {
      case PowerCardTiming.day:
        return 'Dzień';
      case PowerCardTiming.night:
        return 'Noc';
      case PowerCardTiming.voting:
        return 'Głosowanie';
      case PowerCardTiming.automatic:
        return 'Automatyczna';
      case PowerCardTiming.death:
        return 'Przy śmierci';
      case PowerCardTiming.any:
        return 'Dowolna faza';
    }
  }

  String get targetLabel {
    switch (targetMode) {
      case PowerCardTargetMode.none:
        return 'Bez celu';
      case PowerCardTargetMode.onePlayer:
        return 'Jeden gracz';
      case PowerCardTargetMode.twoPlayers:
        return 'Dwóch graczy';
      case PowerCardTargetMode.selfOrPlayer:
        return 'Ty lub gracz';
      case PowerCardTargetMode.cardOrEffect:
        return 'Efekt/karta';
    }
  }

  bool canBePlayedIn(GamePhase phase) {
    switch (timing) {
      case PowerCardTiming.day:
        return phase == GamePhase.day;
      case PowerCardTiming.night:
        return phase == GamePhase.night;
      case PowerCardTiming.voting:
        return phase == GamePhase.voting;
      case PowerCardTiming.automatic:
      case PowerCardTiming.death:
      case PowerCardTiming.any:
        return true;
    }
  }
}

class PlayedPowerCardAction {
  const PlayedPowerCardAction({
    required this.card,
    required this.sourcePlayerName,
    this.targetPlayerName,
    this.secondTargetPlayerName,
    required this.createdAt,
    this.note,
    this.phasePlayed,
    this.resolved = false,
    this.negated = false,
    this.negatedReason,
  });

  final PowerCardDefinition card;
  final String sourcePlayerName;
  final String? targetPlayerName;
  final String? secondTargetPlayerName;
  final DateTime createdAt;
  final String? note;
  final String? phasePlayed;
  final bool resolved;

  /// Set true when this card's effect was cancelled by a defensive card on the
  /// target (e.g. "Nie tym razem" / "Kukła"). [negatedReason] explains why.
  final bool negated;
  final String? negatedReason;

  /// Stable identity for de-duping UI effects (overlay/toast) across snapshots.
  String get key =>
      '${createdAt.millisecondsSinceEpoch}_${card.id}_${targetPlayerName ?? ''}_$sourcePlayerName';

  String get targetsLabel {
    final targets = [targetPlayerName, secondTargetPlayerName]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toList();
    return targets.isEmpty ? 'Brak celu' : targets.join(' → ');
  }

  Map<String, dynamic> toMap() => {
        'cardId': card.id,
        'sourcePlayerName': sourcePlayerName,
        'targetPlayerName': targetPlayerName,
        'secondTargetPlayerName': secondTargetPlayerName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'note': note,
        'phasePlayed': phasePlayed,
        'resolved': resolved,
        'negated': negated,
        'negatedReason': negatedReason,
      };

  factory PlayedPowerCardAction.fromMap(Map<String, dynamic> map) =>
      PlayedPowerCardAction(
        card: _resolveAnyCard(map['cardId'] as String? ?? ''),
        sourcePlayerName: map['sourcePlayerName'] as String? ?? '',
        targetPlayerName: map['targetPlayerName'] as String?,
        secondTargetPlayerName: map['secondTargetPlayerName'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (map['createdAt'] as num?)?.toInt() ?? 0,
        ),
        note: map['note'] as String?,
        phasePlayed: map['phasePlayed'] as String?,
        resolved: map['resolved'] as bool? ?? false,
        negated: map['negated'] as bool? ?? false,
        negatedReason: map['negatedReason'] as String?,
      );
}

class PlayerPowerStatus {
  const PlayerPowerStatus({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

class PowerCards {
  const PowerCards._();

  static const List<PowerCardDefinition> all = [
    PowerCardDefinition(
      id: 'blood_bond',
      name: 'Więzy krwi',
      shortDescription: 'Połącz siebie i wybranego gracza paktem śmierci.',
      effectDescription: 'Ty i wybrany gracz formujecie pakt. Jeśli jeden z was umrze, drugi również umiera. Efekt jest widoczny dla gospodarza.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.favorite_rounded,
      color: Color(0xFFE11D48),
    ),
    PowerCardDefinition(
      id: 'night_owl',
      name: 'Nocny marek',
      shortDescription: 'Zostajesz obudzony nocą, ale milczysz podczas debaty.',
      effectDescription: 'Pozostajesz obudzony w fazie nocnej. Następnego dnia nie możesz brać udziału w debacie i wracasz dopiero na głosowanie.',
      timing: PowerCardTiming.night,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.nightlight_round,
      color: Color(0xFF60A5FA),
    ),
    PowerCardDefinition(
      id: 'poisoned_whiskey',
      name: 'Zatrute whiskey',
      shortDescription: 'Zatruj gracza. Bez pomocy umrze po dobie gry.',
      effectDescription: 'Możesz zatruć innego gracza. Trucizna zabije go w ciągu 24h gry, jeśli nie otrzyma antidotum albo pomocy lekarza.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.local_bar_rounded,
      color: Color(0xFF8B5CF6),
    ),
    PowerCardDefinition(
      id: 'antidote',
      name: 'Antidotum',
      shortDescription: 'Usuń zatrucie z siebie albo innego gracza.',
      effectDescription: 'Wylecza zatrucie. Może zostać użyte na sobie albo na wskazanym graczu.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.selfOrPlayer,
      icon: Icons.healing_rounded,
      color: Color(0xFF34D399),
    ),
    PowerCardDefinition(
      id: 'liberum_veto',
      name: 'Liberum Veto',
      shortDescription: 'Przerwij głosowanie przed ogłoszeniem wyniku.',
      effectDescription: 'Podczas głosowania możesz przerwać głosowanie. Kartę trzeba zagrać zanim gospodarz ogłosi wynik.',
      timing: PowerCardTiming.voting,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.gavel_rounded,
      color: Color(0xFFF59E0B),
    ),
    PowerCardDefinition(
      id: 'employment',
      name: 'Zatrudnienie',
      shortDescription: 'Obywatel losowo zatrudnia się jako wolna klasa.',
      effectDescription: 'Karta tylko dla zwykłych mieszkańców. Losujesz jedną z klas, w której jest wolne miejsce. Jeśli miejsc nie ma, karta ulega zniszczeniu.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.badge_rounded,
      color: Color(0xFF22C55E),
      citizenOnly: true,
    ),
    PowerCardDefinition(
      id: 'election_day',
      name: 'Dzień wyborów',
      shortDescription: 'Debata i głosowanie skupiają się na dwóch graczach.',
      effectDescription: 'Wybierz siebie i drugiego gracza. W debacie mówi tylko wasza dwójka. W głosowaniu pozostali mogą głosować tylko na was albo pominąć głos. Zwycięzca dostaje kartę.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.twoPlayers,
      icon: Icons.how_to_vote_rounded,
      color: Color(0xFFF97316),
    ),
    PowerCardDefinition(
      id: 'intimidation',
      name: 'Zastraszanie',
      shortDescription: 'Zmuś gracza do głosu na wybraną osobę.',
      effectDescription: 'Wybierz gracza, którego zmuszasz, oraz cel jego głosu. Gospodarz powinien pilnować wymuszonego głosu.',
      timing: PowerCardTiming.voting,
      targetMode: PowerCardTargetMode.twoPlayers,
      icon: Icons.psychology_alt_rounded,
      color: Color(0xFFEF4444),
    ),
    PowerCardDefinition(
      id: 'watchful_eye',
      name: 'Czujne oko',
      shortDescription: 'Sprawdź, czy gracz budził się zeszłej nocy.',
      effectDescription: 'Wybierz gracza. Gospodarz przekazuje informację, czy ten gracz budził się poprzedniej nocy.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.visibility_rounded,
      color: Color(0xFF38BDF8),
    ),
    PowerCardDefinition(
      id: 'deal',
      name: 'Deal',
      shortDescription: 'Za zgodą gracza wymieńcie się kartami.',
      effectDescription: 'Możesz za zgodą innego gracza wymienić się z nim dowolną liczbą kart. Wymiana wymaga akceptacji obu stron.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.handshake_rounded,
      color: Color(0xFFA3E635),
      requiresConsent: true,
    ),
    PowerCardDefinition(
      id: 'not_this_time',
      name: 'Nie tym razem',
      shortDescription: 'Automatycznie blokuje negatywną kartę na tobie.',
      effectDescription: 'Działanie automatyczne. Niweluje negatywne działanie karty innego gracza wymierzonej w ciebie.',
      timing: PowerCardTiming.automatic,
      targetMode: PowerCardTargetMode.cardOrEffect,
      icon: Icons.shield_rounded,
      color: Color(0xFF06B6D4),
      automatic: true,
      requiresHostApproval: false,
    ),
    PowerCardDefinition(
      id: 'puppet',
      name: 'Kukła',
      shortDescription: 'W nocy chroni przed atakiem mafii.',
      effectDescription: 'W fazie nocy możesz uratować się przed atakiem mafii. Karta zużywa się niezależnie od tego, czy mafia cię zaatakuje.',
      timing: PowerCardTiming.night,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.theater_comedy_rounded,
      color: Color(0xFFFACC15),
    ),
    PowerCardDefinition(
      id: 'new_deal',
      name: 'Nowe rozdanie',
      shortDescription: 'Wymień wszystkie swoje karty na nowe.',
      effectDescription: 'Po użyciu oddajesz wszystkie aktualne karty i dobierasz nowe.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.casino_rounded,
      color: Color(0xFFEC4899),
    ),
    PowerCardDefinition(
      id: 'handcuffs',
      name: 'Kajdanki',
      shortDescription: 'Zablokuj graczowi używanie kart na jeden dzień.',
      effectDescription: 'Wybierz gracza. Do następnego dnia nie może używać kart mocy.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.link_rounded,
      color: Color(0xFF94A3B8),
    ),
    PowerCardDefinition(
      id: 'enemy_of_mafia',
      name: 'Wróg Mafii',
      shortDescription: 'Oznacz gracza i zdobądź jego kartę, jeśli zginie.',
      effectDescription: 'Oznaczasz gracza. Jeśli zginie w ciągu dnia, otrzymujesz jedną z jego kart jako nagrodę.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.track_changes_rounded,
      color: Color(0xFFDC2626),
    ),
    PowerCardDefinition(
      id: 'last_first',
      name: 'Ostatni będą pierwszymi',
      shortDescription: 'Odwróć kolejność budzenia się w nocy.',
      effectDescription: 'Zamień kolejność budzenia się graczy w nocy na odwrotną. Gospodarz stosuje efekt przy prowadzeniu nocy.',
      timing: PowerCardTiming.night,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.swap_vert_rounded,
      color: Color(0xFFC084FC),
    ),
    PowerCardDefinition(
      id: 'in_your_hands',
      name: 'Wszystko w twoich rękach',
      shortDescription: 'Po śmierci przekaż wszystkie karty graczowi.',
      effectDescription: 'W momencie śmierci przekazujesz wszystkie swoje karty wybranemu graczowi.',
      timing: PowerCardTiming.death,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFFF43F5E),
    ),
  ];

  static PowerCardDefinition byId(String id) {
    return all.firstWhere((card) => card.id == id, orElse: () => all.first);
  }
}
