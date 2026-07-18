import 'package:flutter/material.dart';

import 'power_cards.dart';

/// Karty mocy dla edycji średniowiecznej (dworskie intrygi).
///
/// Wykorzystuje istniejącą definicję [PowerCardDefinition] oraz enumy
/// [PowerCardTiming] i [PowerCardTargetMode] z `power_cards.dart`.
class MedievalCards {
  const MedievalCards._();

  static const List<PowerCardDefinition> all = [
    // 1
    PowerCardDefinition(
      id: 'zebrane_grzechy',
      name: 'Zebrane Grzechy',
      shortDescription: 'Gospodarz zapisuje ci ukryty dowód na wskazaną osobę.',
      effectDescription:
          'Grasz kartę na wskazaną osobę: gospodarz po cichu zapisuje ci na nią dowód. Karta zużywa się przy tym kroku. Spalenie dowodu to osobna, darmowa akcja w dowolnym późniejszym momencie.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.description_rounded,
      color: Color(0xFF7A1F2B),
    ),
    // 2
    PowerCardDefinition(
      id: 'cien_przeszlosci',
      name: 'Cień Przeszłości',
      shortDescription: 'Nakłada na cel 1 poziom kompromitacji.',
      effectDescription:
          'Natychmiast nakłada na cel 1 poziom kompromitacji.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.history_rounded,
      color: Color(0xFF7A1F2B),
    ),
    // 3
    PowerCardDefinition(
      id: 'list_milosny',
      name: 'List Miłosny',
      shortDescription: 'Cel oddaje ci kartę albo zostaje jawnie oskarżony.',
      effectDescription:
          'Grozisz ujawnieniem kompromitującej korespondencji — cel oddaje ci jedną kartę ze swojej ręki albo zostaje jawnie oskarżony przed całym dworem.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.mail_rounded,
      color: Color(0xFF7A1F2B),
    ),
    // 4
    PowerCardDefinition(
      id: 'falszywy_swiadek',
      name: 'Fałszywy Świadek',
      shortDescription: 'Zmuszasz jednego gracza, by oskarżył drugiego.',
      effectDescription:
          'Zmuszasz pierwszą wskazaną osobę, by następnego dnia publicznie oskarżyła drugą, wskazaną przez ciebie.',
      timing: PowerCardTiming.voting,
      targetMode: PowerCardTargetMode.twoPlayers,
      icon: Icons.record_voice_over_rounded,
      color: Color(0xFF7A1F2B),
    ),
    // 5
    PowerCardDefinition(
      id: 'pieczec_milczenia',
      name: 'Pieczęć Milczenia',
      shortDescription: 'Cel milczy w debacie, ale wciąż może głosować.',
      effectDescription:
          'Cel nie może zabierać głosu w debacie tej fazy (ale wciąż może głosować).',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.speaker_notes_off_rounded,
      color: Color(0xFF7A1F2B),
    ),
    // 6
    PowerCardDefinition(
      id: 'podrobiona_pieczec',
      name: 'Podrobiona Pieczęć Króla',
      shortDescription: 'Twój najbliższy głos liczy się podwójnie.',
      effectDescription: 'Twój najbliższy głos liczy się podwójnie.',
      timing: PowerCardTiming.voting,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.approval_rounded,
      color: Color(0xFF3B3540),
    ),
    // 7
    PowerCardDefinition(
      id: 'sfalszowany_list',
      name: 'Sfałszowany List',
      shortDescription: 'Przekierowuje wrogi efekt karty na inną osobę.',
      effectDescription:
          'Przekierowuje najbliższy efekt karty wymierzony w ciebie na inną, wskazaną przez ciebie osobę.',
      timing: PowerCardTiming.automatic,
      targetMode: PowerCardTargetMode.cardOrEffect,
      icon: Icons.edit_note_rounded,
      color: Color(0xFF3B3540),
      automatic: true,
      requiresHostApproval: false,
    ),
    // 8
    PowerCardDefinition(
      id: 'zniszczone_dowody',
      name: 'Zniszczone Dowody',
      shortDescription: 'Anuluje jeden dowód trzymany przeciwko tobie.',
      effectDescription:
          'Anuluje jeden dowód trzymany przeciwko tobie. Nie dotyczy poziomów kompromitacji.',
      timing: PowerCardTiming.automatic,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.delete_forever_rounded,
      color: Color(0xFF3B3540),
      automatic: true,
      requiresHostApproval: false,
    ),
    // 9
    PowerCardDefinition(
      id: 'skradziona_tozsamosc',
      name: 'Skradziona Tożsamość',
      shortDescription: 'Na jeden dzień zamieniasz się tożsamością z celem.',
      effectDescription:
          'Na jeden dzień przejmujesz jawną tożsamość celu — głosy oddane na niego trafiają na ciebie i odwrotnie.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.masks_rounded,
      color: Color(0xFF3B3540),
    ),
    // 10
    PowerCardDefinition(
      id: 'podatek_nadzwyczajny',
      name: 'Podatek Nadzwyczajny',
      shortDescription: 'Zabierasz część Wpływów celu do skarbca.',
      effectDescription: 'Zabierasz część Wpływów celu do skarbca korony.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.request_quote_rounded,
      color: Color(0xFFC9A227),
    ),
    // 11
    PowerCardDefinition(
      id: 'laska_krola',
      name: 'Łaska Króla',
      shortDescription: 'Przekazujesz część swoich Wpływów wskazanej osobie.',
      effectDescription:
          'Przekazujesz część swoich Wpływów wskazanej osobie.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFC9A227),
    ),
    // 12
    PowerCardDefinition(
      id: 'skup_dlugow',
      name: 'Skup Długów',
      shortDescription: 'Część przyszłych zysków celu trafia do ciebie.',
      effectDescription:
          'Przejmujesz dług celu — część jego przyszłych zysków z zadań trafia odtąd do ciebie.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFC9A227),
    ),
    // 13
    PowerCardDefinition(
      id: 'bankructwo',
      name: 'Bankructwo',
      shortDescription: 'Zerujesz Wpływy celu na tę fazę.',
      effectDescription:
          'Zerujesz Wpływy celu na tę fazę — nie może nimi licytować ani płacić.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.money_off_rounded,
      color: Color(0xFFC9A227),
    ),
    // 14
    PowerCardDefinition(
      id: 'renta_dworska',
      name: 'Renta Dworska',
      shortDescription: 'Co fazę otrzymujesz +5 Wpływów ze skarbca.',
      effectDescription:
          'Dopóki trzymasz tę kartę, co fazę otrzymujesz +5 Wpływów prosto ze skarbca.',
      timing: PowerCardTiming.automatic,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.savings_rounded,
      color: Color(0xFFC9A227),
      automatic: true,
      requiresHostApproval: false,
    ),
    // 15
    PowerCardDefinition(
      id: 'plotka_dworska',
      name: 'Plotka Dworska',
      shortDescription: 'Anonimowa plotka: cel trafia pod głosowanie.',
      effectDescription:
          'Podajesz gospodarzowi treść plotki o celu; gospodarz ogłasza ją anonimowo. Cel automatycznie trafia na listę kandydatów najbliższego głosowania i musi jako pierwszy zabrać głos w debacie.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.campaign_rounded,
      color: Color(0xFF7C6A9C),
    ),
    // 16
    PowerCardDefinition(
      id: 'zawstydzenie',
      name: 'Zawstydzenie Publiczne',
      shortDescription: 'Cel jawnie traci prawo głosu w debacie.',
      effectDescription:
          'Cel jawnie (nieanonimowo) traci prawo głosu w najbliższej debacie.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.front_hand_rounded,
      color: Color(0xFF7C6A9C),
    ),
    // 17
    PowerCardDefinition(
      id: 'glos_ludu',
      name: 'Głos Ludu',
      shortDescription: 'Gospodarz ujawnia, kto prowadzi w sondażu głosów.',
      effectDescription:
          'Gospodarz jawnie ujawnia, kto aktualnie prowadzi w niejawnym sondażu głosów, zanim padnie oficjalny wynik.',
      timing: PowerCardTiming.voting,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.groups_rounded,
      color: Color(0xFF7C6A9C),
    ),
    // 18
    PowerCardDefinition(
      id: 'kontrplotka',
      name: 'Kontrplotka',
      shortDescription: 'Chroni wskazaną osobę przed Plotką Dworską.',
      effectDescription:
          'Chronisz z góry wskazaną osobę. Gdy ktoś zagra Plotkę Dworską na chronioną osobę, automatycznie kasuje jej mechaniczny skutek.',
      timing: PowerCardTiming.automatic,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.block_rounded,
      color: Color(0xFF7C6A9C),
      automatic: true,
      requiresHostApproval: false,
    ),
    // 19
    PowerCardDefinition(
      id: 'przysiega_krwi',
      name: 'Przysięga Krwi',
      shortDescription: 'Za zgodą: nie możecie głosować przeciwko sobie.',
      effectDescription:
          'Za zgodą. Dopóki oboje żyjecie, żadne z was nie może zagłosować przeciwko drugiemu.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.favorite_rounded,
      color: Color(0xFF2F6B4F),
      requiresConsent: true,
    ),
    // 20
    PowerCardDefinition(
      id: 'zerwany_sojusz',
      name: 'Zerwany Sojusz',
      shortDescription: 'Kończy widoczny aktywny sojusz lub przysięgę.',
      effectDescription:
          'Natychmiast kończy dowolny widoczny dla ciebie aktywny sojusz/przysięgę.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.link_off_rounded,
      color: Color(0xFF2F6B4F),
    ),
    // 21
    PowerCardDefinition(
      id: 'slubowanie_wiernosci',
      name: 'Ślubowanie Wierności',
      shortDescription: 'Cel musi zagłosować tak samo jak ty.',
      effectDescription:
          'Cel musi zagłosować tak samo jak ty (albo wstrzymać się, jeśli ty się wstrzymasz).',
      timing: PowerCardTiming.voting,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.how_to_vote_rounded,
      color: Color(0xFF2F6B4F),
    ),
    // 22
    PowerCardDefinition(
      id: 'tajny_pakt',
      name: 'Tajny Pakt',
      shortDescription: 'Za zgodą: wymieniacie podgląd po jednej karcie.',
      effectDescription:
          'Za zgodą. Ty i cel pokazujecie sobie nawzajem po jednej karcie, bez ujawniania nikomu innemu.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.handshake_rounded,
      color: Color(0xFF2F6B4F),
      requiresConsent: true,
    ),
    // 23
    PowerCardDefinition(
      id: 'odroczona_audiencja',
      name: 'Odroczona Audiencja',
      shortDescription: 'Opóźnia nadchodzące głosowanie o jedną turę.',
      effectDescription: 'Opóźnia nadchodzące głosowanie o jedną turę.',
      timing: PowerCardTiming.voting,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.schedule_rounded,
      color: Color(0xFF5B3A8C),
    ),
    // 24
    PowerCardDefinition(
      id: 'prawo_pierwszenstwa',
      name: 'Prawo Pierwszeństwa',
      shortDescription: 'Ustalasz kolejność głosów w najbliższej debacie.',
      effectDescription:
          'Decydujesz o kolejności zabierania głosu w najbliższej debacie.',
      timing: PowerCardTiming.day,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.format_list_numbered_rounded,
      color: Color(0xFF5B3A8C),
    ),
    // 25
    PowerCardDefinition(
      id: 'dzien_zaloby',
      name: 'Dzień Żałoby',
      shortDescription: 'Najbliższa faza nocna zostaje pominięta.',
      effectDescription:
          'Najbliższa faza nocna zostaje pominięta — nikt nie może użyć kart nocnych.',
      timing: PowerCardTiming.night,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.dark_mode_rounded,
      color: Color(0xFF5B3A8C),
    ),
    // 26
    PowerCardDefinition(
      id: 'nadzwyczajny_zjazd',
      name: 'Nadzwyczajny Zjazd',
      shortDescription: 'Wymusza dodatkowe, nieplanowane głosowanie.',
      effectDescription:
          'Wymusza dodatkowe, nieplanowane głosowanie poza normalnym rytmem gry.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.event_repeat_rounded,
      color: Color(0xFF5B3A8C),
    ),
    // 27
    PowerCardDefinition(
      id: 'czara_cykuty',
      name: 'Czara Cykuty',
      shortDescription: 'Trucizna zabija skompromitowany cel po dobie.',
      effectDescription:
          'Zatruwasz cel. Zabija po pełnej dobie, jeśli nikt nie uleczy — ale tylko, jeśli cel ma już ≥1 poziom kompromitacji. Bez kompromitacji: cel zamiast umrzeć traci jedną losową kartę z ręki.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.local_bar_rounded,
      color: Color(0xFF4A0E14),
    ),
    // 28
    PowerCardDefinition(
      id: 'antidotum_medyka',
      name: 'Antidotum Nadwornego Medyka',
      shortDescription: 'Leczy zatrucie i zdejmuje 1 poziom kompromitacji.',
      effectDescription:
          'Leczy zatrucie i jednocześnie zdejmuje z tej osoby 1 poziom kompromitacji.',
      timing: PowerCardTiming.any,
      targetMode: PowerCardTargetMode.selfOrPlayer,
      icon: Icons.healing_rounded,
      color: Color(0xFF4A0E14),
    ),
    // 29
    PowerCardDefinition(
      id: 'skrytobojca',
      name: 'Skrytobójca na Żołdzie',
      shortDescription: 'Zamach działa, jeśli cel nie ma ochrony ani przysięgi.',
      effectDescription:
          'Jednorazowe zlecenie zamachu — działa tylko, jeśli cel nie ma żadnej aktywnej ochrony ani przysięgi.',
      timing: PowerCardTiming.night,
      targetMode: PowerCardTargetMode.onePlayer,
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFF4A0E14),
    ),
    // 30
    PowerCardDefinition(
      id: 'ostatnia_wola',
      name: 'Ostatnia Wola Umierającego',
      shortDescription: 'W chwili śmierci kasuje wszystkie dowody przeciw tobie.',
      effectDescription:
          'Trzymana w ręce. W chwili śmierci automatycznie unieważnia wszystkie niespalone dowody zebrane przeciwko tobie.',
      timing: PowerCardTiming.death,
      targetMode: PowerCardTargetMode.none,
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFF4A0E14),
    ),
  ];

  static PowerCardDefinition byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);
}
