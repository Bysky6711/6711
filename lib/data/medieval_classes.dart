import 'dart:math';

import 'package:flutter/material.dart';

/// Frakcje w Edycji Średniowiecznej — równoległy system do bazowej Mafii.
enum MedievalFaction { antagonisci, korona, neutralny, niezdeklarowany }

/// Klasy postaci dostępne w Edycji Średniowiecznej.
enum MedievalClassType {
  emisariusz,
  straznik,
  kanonik,
  skarbnik,
  rycerz,
  dziedziczka,
  trubadur,
  kat,
  podrzutek,
  wrogPubliczny,
}

/// Rodzaj zautomatyzowanej akcji nocnej / turowej, jaką może wykonać klasa.
enum MedievalAbilityKind {
  none,
  compromise,
  evidence,
  confess,
  treasury,
  duel,
  gossip,
  sentence,
  declare,
}

/// Definicja pojedynczej klasy w Edycji Średniowiecznej.
class MedievalClassDefinition {
  const MedievalClassDefinition({
    required this.type,
    required this.name,
    required this.faction,
    required this.description,
    required this.abilityTitle,
    required this.abilityKind,
    required this.icon,
    required this.color,
    required this.min,
    required this.max,
    required this.defaultCount,
    required this.publicClass,
    required this.hasNightAction,
  });

  final MedievalClassType type;
  final String name;
  final MedievalFaction faction;

  /// Pełny opis zdolności klasy.
  final String description;
  final String abilityTitle;
  final MedievalAbilityKind abilityKind;
  final IconData icon;
  final Color color;
  final int min;
  final int max;
  final int defaultCount;

  /// Czy klasa jest jawna dla wszystkich od początku gry.
  final bool publicClass;

  /// Czy klasa dysponuje akcją wykonywaną w nocy.
  final bool hasNightAction;
}

class MedievalClasses {
  const MedievalClasses._();

  static const List<MedievalClassDefinition> all = [
    MedievalClassDefinition(
      type: MedievalClassType.emisariusz,
      name: 'Emisariusz Węża',
      faction: MedievalFaction.antagonisci,
      description:
          'Co noc cała frakcja Antagonistów wspólnie wskazuje jeden cel — nakłada mu kolejny poziom kompromitacji. Presja narasta z każdą nocą.',
      abilityTitle: 'Naznaczenie Węża',
      abilityKind: MedievalAbilityKind.compromise,
      icon: Icons.visibility_off_rounded,
      color: Color(0xFF7A1F2B),
      min: 1,
      max: 6,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: true,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.straznik,
      name: 'Strażniczka Tajemnic',
      faction: MedievalFaction.korona,
      description:
          'Co noc zbiera dowód na jednej osobie. Nowy dowód na tej samej osobie zajmuje całą kolejną noc.',
      abilityTitle: 'Zbieranie dowodów',
      abilityKind: MedievalAbilityKind.evidence,
      icon: Icons.key_rounded,
      color: Color(0xFF3B3540),
      min: 0,
      max: 1,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: true,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.kanonik,
      name: 'Kanonik Pokutny',
      faction: MedievalFaction.korona,
      description:
          'Co noc wysłuchuje spowiedzi — wymusza szczerą odpowiedź tak/nie na jedno pytanie zadane w tajemnicy. Jeśli publicznie zdradzi treść spowiedzi, trwale traci moc.',
      abilityTitle: 'Spowiedź',
      abilityKind: MedievalAbilityKind.confess,
      icon: Icons.menu_book_rounded,
      color: Color(0xFF4B3621),
      min: 0,
      max: 1,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: true,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.skarbnik,
      name: 'Skarbnik Korony',
      faction: MedievalFaction.korona,
      description:
          'Raz na turę opodatkowuje albo dotuje jedną osobę — Wpływy płyną przez wspólny skarbiec, który rozdziela wyłącznie on (także sobie). Cel poboczny: zakończyć grę z największą liczbą Wpływów.',
      abilityTitle: 'Skarbiec Korony',
      abilityKind: MedievalAbilityKind.treasury,
      icon: Icons.account_balance_rounded,
      color: Color(0xFFC9A227),
      min: 0,
      max: 1,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: false,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.rycerz,
      name: 'Rycerz Bez Herbu',
      faction: MedievalFaction.neutralny,
      description:
          'Raz na całą grę wyzywa kogoś na pojedynek — przegrany natychmiast odpada (może odpaść sam Rycerz). Decyzja nieodwracalna. Cel: przetrwać do końca gry, niezależnie kto wygra.',
      abilityTitle: 'Pojedynek',
      abilityKind: MedievalAbilityKind.duel,
      icon: Icons.military_tech_rounded,
      color: Color(0xFF6B7280),
      min: 0,
      max: 1,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: false,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.dziedziczka,
      name: 'Dziedziczka',
      faction: MedievalFaction.korona,
      description:
          'Nosicielka Pieczęci Następcy. Brak aktywnej mocy — jej siła to bycie celem obu frakcji. Jeśli przeżyje do końca, Korona wygrywa natychmiast; jeśli Antagoniści wygnają konkretnie ją, wygrywają natychmiast.',
      abilityTitle: 'Pieczęć Następcy',
      abilityKind: MedievalAbilityKind.none,
      icon: Icons.diamond_rounded,
      color: Color(0xFFD4AF37),
      min: 1,
      max: 1,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: false,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.trubadur,
      name: 'Trubadur',
      faction: MedievalFaction.korona,
      description:
          'Raz dziennie za darmo wywołuje efekt Plotki Dworskiej (cel trafia na listę głosowania i mówi pierwszy). Nie można użyć drugi raz na tę samą osobę. +15 Wpływów, jeśli oplotkowana osoba zostanie wygnana w najbliższym głosowaniu.',
      abilityTitle: 'Plotka Trubadura',
      abilityKind: MedievalAbilityKind.gossip,
      icon: Icons.campaign_rounded,
      color: Color(0xFF7C6A9C),
      min: 0,
      max: 1,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: false,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.kat,
      name: 'Kat Miejski',
      faction: MedievalFaction.korona,
      description:
          'Raz na dwie tury dopisuje osobę do listy wyroków — wykonywanych automatycznie, chyba że zwykła większość zagłosuje za ułaskawieniem. Jeśli wyrok trafi w lojalistę, trwale traci moc.',
      abilityTitle: 'Wyrok',
      abilityKind: MedievalAbilityKind.sentence,
      icon: Icons.gavel_rounded,
      color: Color(0xFF1C1410),
      min: 0,
      max: 1,
      defaultCount: 1,
      publicClass: false,
      hasNightAction: false,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.podrzutek,
      name: 'Podrzutek',
      faction: MedievalFaction.niezdeklarowany,
      description:
          'Jawny dla wszystkich jako Podrzutek. W ciągu pierwszych 3 tur może jawnie i nieodwołalnie zadeklarować przynależność do Korony albo Antagonistów. Jeśli nie zdąży — host losuje stronę 50/50.',
      abilityTitle: 'Deklaracja',
      abilityKind: MedievalAbilityKind.declare,
      icon: Icons.help_center_rounded,
      color: Color(0xFF8C7853),
      min: 1,
      max: 1,
      defaultCount: 1,
      publicClass: true,
      hasNightAction: false,
    ),
    MedievalClassDefinition(
      type: MedievalClassType.wrogPubliczny,
      name: 'Wróg Publiczny',
      faction: MedievalFaction.korona,
      description:
          'Zdemaskowany lojalista — klasa jawna od startu. Pasywnie +5 Wpływów przy każdej zmianie fazy. Jednorazowo, gdy jest liderem głosowania: przekierowuje wygnanie na losową osobę spośród tych, którzy głosowali na niego. Poza tym zero odporności.',
      abilityTitle: 'Ostatnie słowo',
      abilityKind: MedievalAbilityKind.none,
      icon: Icons.report_rounded,
      color: Color(0xFF5B3A8C),
      min: 1,
      max: 1,
      defaultCount: 1,
      publicClass: true,
      hasNightAction: false,
    ),
  ];

  static MedievalClassDefinition definitionOf(MedievalClassType t) {
    return all.firstWhere((c) => c.type == t);
  }

  static String nameOf(MedievalClassType t) {
    return definitionOf(t).name;
  }

  static List<MedievalClassType> buildDeck({required int players}) {
    final rng = Random();
    final antagonists = players <= 6 ? 1 : (players <= 11 ? 2 : 3);
    const uniques = [
      MedievalClassType.dziedziczka,
      MedievalClassType.straznik,
      MedievalClassType.kanonik,
      MedievalClassType.skarbnik,
      MedievalClassType.trubadur,
      MedievalClassType.kat,
      MedievalClassType.wrogPubliczny,
      MedievalClassType.podrzutek,
      MedievalClassType.rycerz,
    ];
    final deck = <MedievalClassType>[];
    for (var i = 0; i < antagonists; i++) {
      deck.add(MedievalClassType.emisariusz);
    }
    for (final u in uniques) {
      if (deck.length >= players) break;
      deck.add(u);
    }
    // if still short (very large lobby), pad with extra antagonists to keep balance
    while (deck.length < players) {
      deck.add(MedievalClassType.emisariusz);
    }
    deck.shuffle(rng);
    return deck..length = players <= deck.length ? players : deck.length;
  }
}
