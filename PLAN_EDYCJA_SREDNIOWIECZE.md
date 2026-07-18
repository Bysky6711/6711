# PLAN — Edycja Średniowiecze (prompt implementacyjny)

> **Jak używać tego dokumentu:** to samodzielny prompt/brief do wdrożenia nowej kolekcji "Edycja Średniowiecze" w projekcie Mafia (`C:\VScode\projekty\mafia`). Można go wkleić jako zadanie dla programisty albo agenta AI (np. nową sesję Claude Code) bez odwoływania się do wcześniejszej rozmowy — zawiera pełny kontekst, zasady, zawartość (10 klas, 30 kart), kierunek graficzny i wskazówki integracji z istniejącym silnikiem gry. Trzyma się nazewnictwa i konwencji już obecnych w repo (patrz `PLAN.md`, `PLAN2.md`).

---

## 0. Cel

Dodać do gry **drugą, w pełni odrębną kolekcję treści** ("Edycja Średniowiecze", klimat: intrygi dworskie) obok istniejącej bazowej gry — z własnymi klasami, kartami, mechanikami, terminologią i identyfikacją wizualną. To NIE jest reskin bazowych 5 ról / 17 kart — każda mechanika w tej edycji jest celowo inna (patrz sekcja 5).

Rekomendacja: host przy tworzeniu pokoju wybiera **Edycję: Podstawowa / Średniowiecze** (nowe pole `edition` na `GameRoom`, analogiczne do `roleCounts`). To pozwala trzymać obie kolekcje w kodzie równolegle, bez usuwania bazowej gry.

---

## 1. Kontekst techniczny — do czego się podłączyć

Istniejąca architektura (zweryfikowana w kodzie, stan na dziś):

- `lib/data/roles.dart` — `MafiaRoleCardType` enum + `GameRoleDefinition` (min/max/default/isConfigurable) + `GameRoles.buildDeck()`. Nowa edycja potrzebuje **swojego** enuma klas i osobnej funkcji budowania talii ról (nie da się zmieścić 10 nowych klas w istniejącym enumie bez konfliktu z bazową grą).
- `lib/data/power_cards.dart` — `PowerCardDefinition` (id/name/short/effect/timing/targetMode/icon/color/flagi) + `PowerCards.all`. Analogicznie potrzeba osobnej listy `MedievalCards.all` z tą samą strukturą pól (żeby dało się reużyć cały istniejący UI do wyświetlania/grania kart).
- `lib/models/game_player.dart` — `GamePlayer.statuses` to zwykła `List<String>`, w tym już istniejące wzorce "tag z zakodowaną nazwą celu" (`marked:<name>`, `bequeath:<name>`, `bound:<name>`). **Ten sam wzorzec da się wprost wykorzystać** dla nowych mechanik tej edycji (patrz sekcja 9) — nie trzeba nowego typu danych dla większości z nich.
- `lib/models/game_room.dart` — `wallets: Map<String,int>` (waluta $). Wpływy (sekcja 8) to analogiczna, ale **osobna** mapa.
- `lib/services/online_room_service.dart` — `_applyCardEffect` (switch po `card.id`), `_tickStatuses`, `_expireTransient` (`_transient` set), `changePhase`, `closeVote`. Nowe karty/klasy podłączają się tu jako nowe gałęzie switcha + nowe wpisy/wyjątki w tych zbiorach.
- `lib/screens/started_game_screen.dart` — `_computeWinner`/`_WinSide` (parytet mafia/reszta). Golden-target Dziedziczki i równoległe zwycięstwo Rycerza Bez Herbu wymagają dodatkowych warunków PRZED standardową matematyką parytetu.

---

## 2. Kierunek artystyczny

Motyw: nocny dwór królewski, świece, pieczęcie z wosku, pergamin, ciężka heraldyka — mroczniejszy i bardziej "polityczny" niż czerwony One UI z bazowej gry, ale wciąż ciemny/kontrastowy (spójny z istniejącym `mafia_ios_system.dart`).

**Paleta (zamiast bazowego akcentu `0xFFE5404F`, tylko dla tej edycji):**

| Rola koloru | Hex | Użycie |
|---|---|---|
| Akcent główny (burgund) | `#7A1F2B` | przyciski, pasek statusu, kompromitacja |
| Złoto dworskie | `#C9A227` | Wpływy, elementy premium/nagrody |
| Tło/atrament | `#1C1410` | tło paneli (odpowiednik dzisiejszego czarnego One UI) |
| Pergamin | `#EDE0C8` | tekst na jasnych kartach, akcenty pisma |
| Fiolet królewski | `#5B3A8C` | ceremonia, klasy "znane publicznie" |
| Stal | `#6B7280` | neutralne/pojedynek |

**Kolory kategorii kart:** kompromitacja/szantaż `#7A1F2B`, dowody/fałszerstwa `#3B3540`, wpływy/skarbiec `#C9A227`, plotki `#7C6A9C`, przysięgi/sojusze `#2F6B4F`, dwór/ceremonia `#5B3A8C`, ostateczne środki `#4A0E14`.

Ikony: reużyć istniejący wzorzec `Icons.xxx_rounded` z `package:flutter/material.dart` (dokładnie jak w `power_cards.dart`) — konkretne przypisania w sekcjach 6 i 7, gotowe do wklejenia.

Card-back / tło paneli: motyw pieczęci woskowej na pergaminie zamiast dzisiejszego gładkiego szkła — można to zrobić jako wariant `LockGlassPanel` z inną teksturą/kolorem, bez zmiany layoutu.

Gotowe tło aplikacji dla tej edycji jest już wygenerowane i zapisane w repo — patrz sekcja 12.

---

## 3. Terminologia (pełne mapowanie nazw)

| Bazowa gra | Edycja Średniowiecze |
|---|---|
| Mafia (frakcja) | Ród Węża (Antagoniści) |
| Detektyw / Lekarz / Szeryf / Obywatel | brak wprost — 10 nowych klas, patrz sekcja 6 |
| $ (złoto z zadań/licytacji) | zostaje bez zmian, osobno od nowego zasobu |
| — (nowy zasób) | **Wpływy** |
| Karty mocy | Karty dworskie |
| Katalog kart | Katalog dworski |
| Wygnanie (nowe określenie "śmierci") | mechanicznie to samo co `alive=false`, tylko narracyjnie inaczej nazwane |

---

## 4. Frakcje i warunki zwycięstwa

- **Antagoniści (Ród Węża):** wygrywają, gdy liczba żywych Antagonistów ≥ liczba żywej reszty dworu (dokładnie ten sam parytet co bazowa gra, liczony po wygnaniach zamiast zabójstw).
- **Korona:** wygrywa, gdy Antagonistów zostanie 0.
- **Wyjątek 1 — Dziedziczka (golden target):** jeśli przeżyje do końca gry, Korona wygrywa natychmiast niezależnie od parytetu; jeśli Antagoniści zidentyfikują i wyeliminują **konkretnie ją**, oni wygrywają natychmiast, też niezależnie od parytetu.
- **Wyjątek 2 — Rycerz Bez Herbu:** ma całkowicie równoległe, osobiste zwycięstwo (przetrwać do końca) — nie zmienia, kto wygrywa oficjalnie Koronę-vs-Antagonistów.
- **Podrzutek:** liczy się do parytetu jako pełnoprawny członek frakcji, którą aktualnie zadeklarował (patrz sekcja 6.9).

---

## 5. Dwa ujednolicone systemy zasobów

Cała edycja stoi na **dwóch, i tylko dwóch**, systemach śledzenia stanu gracza (żadna karta/klasa nie tworzy trzeciego, równoległego licznika):

**A. Kompromitacja** (poziomy, nie znika sama z fazą):
- Poziom 1 → traci najbliższy głos.
- Poziom 2 → nie może grać kart do końca dnia.
- Poziom 3 → trwałe wygnanie.
- Źródła: Emisariusz Węża (co noc, cała frakcja wskazuje jeden cel), karta Cień Przeszłości (od razu poziom 1).
- Leczenie: Antidotum Nadwornego Medyka (zdejmuje 1 poziom przy okazji leczenia trucizny), Zniszczone Dowody (patrz niżej — UWAGA, ta karta anuluje dowód, NIE poziom kompromitacji).

**B. Dowód / sekret** (dźwignia, nie debuff):
- Powstaje z mocy Strażniczki Tajemnic (co noc) albo karty Zebrane Grzechy (jednorazowo).
- Trzymający może w dowolnym momencie spalić dowód: wymusza jawną, szczerą odpowiedź tak/nie na jedno pytanie (albo ujawnienie frakcji, wersja Strażniczki).
- Niespalony dowód przepada bezpowrotnie, jeśli osoba, na którą go zebrano, umrze (Ostatnia Wola Umierającego).
- Zniszczone Dowody anuluje jeden dowód trzymany przeciwko tobie (dokładnie to, na co wskazuje nazwa karty).

---

## 6. 10 klas — pełna specyfikacja

### 6.1 Emisariusz Węża
Frakcja: **Antagoniści**. Ikona: `Icons.visibility_off_rounded`. Kolor: `#7A1F2B`.
Cel: parytet (sekcja 4).
Moc: co noc cała frakcja wspólnie wskazuje jeden cel — nakłada kolejny poziom kompromitacji (sekcja 5A). Presja narasta z każdą nocą, nie tylko przy finalnym wygnaniu.

### 6.2 Strażniczka Tajemnic
Frakcja: **Korona**. Ikona: `Icons.key_rounded`. Kolor: `#3B3540`.
Cel: standardowe zwycięstwo Korony.
Moc: co noc zbiera dowód (sekcja 5B) na jednej osobie. Ograniczenie: nowy dowód na tej samej osobie zajmuje całą kolejną noc — nie da się dublować efektu na jednym celu z marszu.

### 6.3 Kanonik Pokutny
Frakcja: **Korona**. Ikona: `Icons.menu_book_rounded`. Kolor: `#4B3621`.
Cel: standardowe zwycięstwo Korony.
Moc: co noc wysłuchuje spowiedzi — wymusza szczerą odpowiedź tak/nie na jedno pytanie zadane w tajemnicy. Koszt: jeśli kiedykolwiek publicznie zdradzi treść spowiedzi, trwale traci moc na resztę gry.

### 6.4 Skarbnik Korony
Frakcja: **Korona** + cel poboczny (prestiż): zakończyć grę z największą ilością Wpływów na własnym koncie. Ikona: `Icons.account_balance_rounded`. Kolor: `#C9A227`.
Moc: raz na turę opodatkowuje (zabiera Wpływy) albo dotuje (przekazuje Wpływy) jedną osobę — środki płyną przez wspólny skarbiec, który rozdziela wyłącznie on, w tym samemu sobie.

### 6.5 Rycerz Bez Herbu
Frakcja: **Neutralny**, nie służy żadnej stronie. Ikona: `Icons.military_tech_rounded`. Kolor: `#6B7280`.
Cel: przetrwać do samego końca gry, niezależnie kto oficjalnie wygra (sekcja 4, wyjątek 2).
Moc: raz na całą grę wyzywa kogoś na pojedynek — przegrany natychmiast odpada (w tym może odpaść sam Rycerz). Decyzja nieodwracalna.

### 6.6 Dziedziczka
Frakcja: **Korona**, nosicielka Pieczęci Następcy. Ikona: `Icons.diamond_rounded`. Kolor: `#D4AF37`.
Cel: golden target (sekcja 4, wyjątek 1) — symetryczny dla obu stron.
Moc: brak aktywnej mocy — jej "moc" to bycie celem obu frakcji; cała gra toczy się częściowo wokół tego, kto ją namierzy/ochroni.

### 6.7 Trubadur
Frakcja: **Korona**. Ikona: `Icons.campaign_rounded`. Kolor: `#7C6A9C`.
Cel: standardowe zwycięstwo Korony + osobisty zysk: +15 Wpływów, jeśli osoba, na którą naplotkował, faktycznie zostanie wygnana w najbliższym głosowaniu.
Moc: raz dziennie za darmo (bez zużywania karty) wywołuje dokładnie efekt karty Plotka Dworska (7.15) — cel automatycznie trafia na listę głosowania i mówi pierwszy w debacie. Twardy limit: nie może użyć tego drugi raz na tę samą osobę w całej grze (prosty flag `true/false` per para graczy, bez żadnego liczenia wiarygodności).

### 6.8 Kat Miejski
Frakcja: **Korona**. Ikona: `Icons.gavel_rounded`. Kolor: `#1C1410`.
Cel: standardowe zwycięstwo Korony.
Moc: raz na dwie tury (cooldown) dopisuje jedną osobę do listy wyroków — wykonywanych automatycznie, chyba że zwykła większość (nie kwalifikowana) zagłosuje za ułaskawieniem. Ryzyko: jeśli wyrok trafi w lojalistę, trwale traci tę moc.

### 6.9 Podrzutek
Frakcja: **jawna dla wszystkich od pierwszej rundy jako "Podrzutek"** (on sam też o tym wie), ale bez przypisanej strony na starcie. Ikona: `Icons.help_center_rounded`. Kolor: `#8C7853`.
Cel: dołączyć, raz i na stałe, do Korony albo Antagonistów.
Moc: w dowolnym momencie w ciągu **pierwszych 3 tur** (tura = pełny cykl dzień+noc+głosowanie od startu gry) może jawnie zadeklarować przynależność — decyzja jest natychmiast widoczna dla wszystkich i **nieodwołalna**. Jeśli nie zadeklaruje się do końca 3. tury, host losuje mu stronę 50/50. Od chwili deklaracji (własnej albo losowej) liczy się do parytetu jako pełnoprawny członek tej frakcji.

### 6.10 Wróg Publiczny
Frakcja: **Korona**, zdemaskowany lojalista — jego klasa jest jawna dla wszystkich od momentu przydziału ról (nie tylko dla hosta/martwych, jak reszta). Ikona: `Icons.report_rounded`. Kolor: `#5B3A8C`.
Cel: standardowe zwycięstwo Korony.
Moc pasywna "Sympatia ludu": +5 Wpływów przy każdej zmianie fazy, bez warunków, do końca gry.
Moc reaktywna "Ostatnie słowo" (jednorazowa): gdy zamyka się głosowanie i on jest liderem — jeśli jeszcze nie użyta, przekierowuje wygnanie na osobę wylosowaną **wyłącznie spośród tych, którzy zagłosowali konkretnie na niego** (nie wszystkich głosujących, nie wstrzymanych). On przeżywa, moc zużywa się trwale. Poza tym jednym przypadkiem: zero odporności — trucizna, kompromitacja i inne karty działają na niego zawsze normalnie.

---

## 7. 30 kart — pełna specyfikacja

### Kompromitacja i szantaż

**7.1 Zebrane Grzechy** *(Dowolna faza / Jeden gracz)* — `Icons.description_rounded`, `#7A1F2B`. Grasz kartę na wskazaną osobę: gospodarz po cichu zapisuje ci na nią dowód (sekcja 5B). Karta zużywa się przy tym kroku. Spalenie dowodu to osobna, darmowa akcja możliwa w dowolnym późniejszym momencie.

**7.2 Cień Przeszłości** *(Dowolna faza / Jeden gracz)* — `Icons.history_rounded`, `#7A1F2B`. Natychmiast nakłada na cel 1 poziom kompromitacji (sekcja 5A).

**7.3 List Miłosny** *(Dowolna faza / Jeden gracz)* — `Icons.mail_rounded`, `#7A1F2B`. Grozisz ujawnieniem kompromitującej korespondencji — cel oddaje ci jedną kartę ze swojej ręki albo zostaje jawnie oskarżony przed całym dworem.

**7.4 Fałszywy Świadek** *(Głosowanie / Dwóch graczy)* — `Icons.record_voice_over_rounded`, `#7A1F2B`. Zmuszasz pierwszą wskazaną osobę, by następnego dnia publicznie oskarżyła drugą, wskazaną przez ciebie.

**7.5 Pieczęć Milczenia** *(Dzień / Jeden gracz)* — `Icons.speaker_notes_off_rounded`, `#7A1F2B`. Cel nie może zabierać głosu w debacie tej fazy (ale wciąż może głosować).

### Dowody i fałszerstwa

**7.6 Podrobiona Pieczęć Króla** *(Głosowanie / Bez celu)* — `Icons.approval_rounded`, `#3B3540`. Twój najbliższy głos liczy się podwójnie.

**7.7 Sfałszowany List** *(Automatyczna / Efekt-karta)* — `Icons.edit_note_rounded`, `#3B3540`. Przekierowuje najbliższy efekt karty wymierzony w ciebie na inną, wskazaną przez ciebie osobę.

**7.8 Zniszczone Dowody** *(Automatyczna / Bez celu)* — `Icons.delete_forever_rounded`, `#3B3540`. Anuluje jeden dowód (sekcja 5B) trzymany przeciwko tobie. Nie dotyczy poziomów kompromitacji.

**7.9 Skradziona Tożsamość** *(Dzień / Jeden gracz)* — `Icons.masks_rounded`, `#3B3540`. Na jeden dzień przejmujesz jawną tożsamość celu — głosy oddane na niego trafiają na ciebie i odwrotnie.

### Wpływy i skarbiec

**7.10 Podatek Nadzwyczajny** *(Dowolna faza / Jeden gracz)* — `Icons.request_quote_rounded`, `#C9A227`. Zabierasz część Wpływów celu do skarbca korony.

**7.11 Łaska Króla** *(Dowolna faza / Jeden gracz)* — `Icons.card_giftcard_rounded`, `#C9A227`. Przekazujesz część swoich Wpływów wskazanej osobie.

**7.12 Skup Długów** *(Dowolna faza / Jeden gracz)* — `Icons.receipt_long_rounded`, `#C9A227`. Przejmujesz dług celu — część jego przyszłych zysków z zadań trafia odtąd do ciebie.

**7.13 Bankructwo** *(Dowolna faza / Jeden gracz)* — `Icons.money_off_rounded`, `#C9A227`. Zerujesz Wpływy celu na tę fazę — nie może nimi licytować ani płacić.

**7.14 Renta Dworska** *(Automatyczna / Bez celu)* — `Icons.savings_rounded`, `#C9A227`. Dopóki trzymasz tę kartę, co fazę otrzymujesz +5 Wpływów prosto ze skarbca.

### Plotki i opinia publiczna

**7.15 Plotka Dworska** *(Dzień / Jeden gracz)* — `Icons.campaign_rounded`, `#7C6A9C`. Podajesz gospodarzowi treść plotki (prawdziwej albo zmyślonej) o celu; gospodarz ogłasza ją anonimowo całemu dworowi. Skutek: cel automatycznie trafia na listę kandydatów najbliższego głosowania i musi jako pierwszy zabrać głos w debacie.

**7.16 Zawstydzenie Publiczne** *(Dzień / Jeden gracz)* — `Icons.front_hand_rounded`, `#7C6A9C`. Cel jawnie (nieanonimowo) traci prawo głosu w najbliższej debacie.

**7.17 Głos Ludu** *(Głosowanie / Bez celu)* — `Icons.groups_rounded`, `#7C6A9C`. Gospodarz jawnie ujawnia, kto aktualnie prowadzi w niejawnym sondażu głosów, zanim padnie oficjalny wynik.

**7.18 Kontrplotka** *(Automatyczna / Bez celu, chronisz z góry wskazaną osobę)* — `Icons.block_rounded`, `#7C6A9C`. Gdy ktoś zagra Plotkę Dworską na chronioną osobę, automatycznie kasuje jej mechaniczny skutek (bez auto-listy głosowania, bez wymuszonego pierwszeństwa).

### Przysięgi i sojusze

**7.19 Przysięga Krwi** *(Dowolna faza / Jeden gracz, za zgodą)* — `Icons.favorite_rounded`, `#2F6B4F`. Dopóki oboje żyjecie, żadne z was nie może zagłosować przeciwko drugiemu.

**7.20 Zerwany Sojusz** *(Dowolna faza / Jeden gracz)* — `Icons.link_off_rounded`, `#2F6B4F`. Natychmiast kończy dowolny widoczny dla ciebie aktywny sojusz/przysięgę.

**7.21 Ślubowanie Wierności** *(Głosowanie / Jeden gracz)* — `Icons.how_to_vote_rounded`, `#2F6B4F`. Cel musi zagłosować tak samo jak ty (albo wstrzymać się, jeśli ty się wstrzymasz).

**7.22 Tajny Pakt** *(Dowolna faza / Jeden gracz, za zgodą)* — `Icons.handshake_rounded`, `#2F6B4F`. Ty i cel pokazujecie sobie nawzajem po jednej karcie, bez ujawniania nikomu innemu.

### Dwór i ceremonia

**7.23 Odroczona Audiencja** *(Głosowanie / Bez celu)* — `Icons.schedule_rounded`, `#5B3A8C`. Opóźnia nadchodzące głosowanie o jedną turę.

**7.24 Prawo Pierwszeństwa** *(Dzień / Bez celu)* — `Icons.format_list_numbered_rounded`, `#5B3A8C`. Decydujesz o kolejności zabierania głosu w najbliższej debacie.

**7.25 Dzień Żałoby** *(Noc / Bez celu)* — `Icons.dark_mode_rounded`, `#5B3A8C`. Najbliższa faza nocna zostaje pominięta — nikt nie może użyć kart nocnych.

**7.26 Nadzwyczajny Zjazd** *(Dowolna faza / Bez celu)* — `Icons.event_repeat_rounded`, `#5B3A8C`. Wymusza dodatkowe, nieplanowane głosowanie poza normalnym rytmem gry.

### Ostateczne środki (celowo rzadkie — jedyne 2 śmiercionośne w całej edycji)

**7.27 Czara Cykuty** *(Dowolna faza / Jeden gracz)* — `Icons.local_bar_rounded`, `#4A0E14`. Zatruwasz cel. Zabija po pełnej dobie, jeśli nikt nie uleczy — **ale tylko, jeśli cel ma już ≥1 poziom kompromitacji** (czysta reputacja chroni przed cichym morderstwem). Bez kompromitacji: cel zamiast umrzeć traci jedną losową kartę z ręki.

**7.28 Antidotum Nadwornego Medyka** *(Dowolna faza / Ty lub gracz)* — `Icons.healing_rounded`, `#4A0E14`. Leczy zatrucie i jednocześnie zdejmuje z tej osoby 1 poziom kompromitacji.

**7.29 Skrytobójca na Żołdzie** *(Noc / Jeden gracz)* — `Icons.gps_fixed_rounded`, `#4A0E14`. Jednorazowe zlecenie zamachu — działa tylko, jeśli cel nie ma żadnej aktywnej ochrony ani przysięgi.

**7.30 Ostatnia Wola Umierającego** *(Przy śmierci / Bez celu)* — `Icons.volunteer_activism_rounded`, `#4A0E14`. Trzymana w ręce (nie zagrywana wcześniej). W chwili śmierci, w dowolny sposób, automatycznie unieważnia wszystkie niespalone dowody (sekcja 5B) zebrane przeciwko tobie.

---

## 8. Ekonomia Wpływów

Osobny licznik od $ — istniejąca ekonomia zadań/licytacji ($ z `wallets`) działa bez zmian.

**Źródła (tworzą Wpływy "z niczego"):** udana plotka Trubadura (+15), pasywna "sympatia ludu" Wroga Publicznego (+5/fazę), Renta Dworska (+5/fazę dopóki trzymana).
**Redystrybucja (zabiera jednemu graczowi, nie tworzy nowych):** Skarbnik Korony (tax/subsidy przez wspólny skarbiec), Podatek Nadzwyczajny, Łaska Króla, Skup Długów, Bankructwo.

Sugerowane wartości domyślne (do strojenia przez hosta): tax/subsidy Skarbnika ~10, Podatek Nadzwyczajny ~10, Łaska Króla — dowolna kwota do wysokości salda gracza.

---

## 9. Integracja z silnikiem gry — konkretne wskazówki

- **Nowy enum klas:** `MedievalClassType` w nowym pliku `lib/data/medieval_classes.dart`, wzorowany 1:1 na strukturze `GameRoleDefinition`/`GameRoles` z `roles.dart`.
- **Nowa lista kart:** `MedievalCards.all` w `lib/data/medieval_cards.dart`, ta sama struktura co `PowerCardDefinition`.
- **Kompromitacja:** da się zaimplementować BEZ nowego typu danych — reużyć `GamePlayer.statuses` (`List<String>`) z tagami `'kompromitacja1'` / `'kompromitacja2'`, analogicznie do istniejącego wzorca `'poisoned'`/`'poisoned2'` w `_tickStatuses`. Warunek "nie znika samo z fazą" = po prostu NIE dodawać tych tagów do `_transient` seta w `_expireTransient`. Alternatywa "czystsza" (więcej pracy): dedykowane pole `int compromiseLevel` na `GamePlayer`.
- **Dowód/sekret:** reużyć dokładnie wzorzec `'marked:<name>'`/`'bequeath:<name>'`/`'bound:<name>'` już obecny w `_applyCardEffect` — np. tag `'dowod:<holderName>'` na graczu, przeciwko któremu zebrano dowód. Spalenie dowodu to nowa metoda serwisu, analogiczna do istniejących `assignCard`/`awardMoney`.
- **Wpływy:** nowe pole `Map<String,int> wplywy` na `GameRoom` (dokładnie równoległe do `wallets`), nowa metoda `awardInfluence` analogiczna do `awardMoney`.
- **Podrzutek:** nowe pole `String? podrzutekFaction` na `GamePlayer` (albo tag statusu `'frakcja:Korona'`/`'frakcja:Antagonisci'`); limit "3 tury" wymaga nowego licznika rund — obecnie `GameRoom` go nie ma, trzeba dodać `int roundNumber`, inkrementowany np. przy każdym powrocie fazy do `day`.
- **Dziedziczka / golden target:** rozszerzyć `_computeWinner` w `started_game_screen.dart` o dodatkowe sprawdzenia PRZED standardową matematyką parytetu.
- **Rycerz Bez Herbu:** jego zwycięstwo to osobna flaga wyświetlana graczowi na koniec gry, nie wpływa na `_WinSide`.

---

## 10. Sugerowana kolejność wdrożenia

1. Model danych: `MedievalClassType`, `MedievalCards`, pola `wplywy`/`podrzutekFaction`/`roundNumber`.
2. Rozdanie klas (odpowiednik `RoleRevealScreen` dla tej edycji) + wybór edycji przy tworzeniu pokoju.
3. Kompromitacja + Emisariusz Węża (rdzeń rozgrywki dla Antagonistów).
4. Dowód/sekret + Strażniczka Tajemnic + karty z sekcji 7 (Zebrane Grzechy, Cień Przeszłości, Zniszczone Dowody, Ostatnia Wola Umierającego).
5. Wpływy + Skarbnik Korony + karty ekonomiczne.
6. Pozostałe klasy (Kanonik, Rycerz, Dziedziczka, Trubadur, Kat Miejski, Podrzutek, Wróg Publiczny) i pozostałe karty.
7. Warunki zwycięstwa (golden target, zwycięstwo Rycerza).
8. Identyfikacja wizualna (kolory/ikony z sekcji 2, 6, 7).

---

## 11. Otwarte pytania do ustalenia z hostem/deweloperem

- Czy Edycja Średniowiecze ma być przełącznikiem przy tworzeniu pokoju, czy docelowo osobnym trybem/aplikacją?
- Czy dokładne wartości liczbowe (Wpływy, cooldowny) z sekcji 8/6 są ostateczne, czy do playtestów?
- Czy zadania/licytacje (mechaniki bazowej gry) mają działać też w tej edycji, czy Wpływy je całkowicie zastępują?

---

## 12. Tło graficzne — gotowy asset i integracja

**Plik:** `assets/images/backgrounds/medieval_background.jpg` (1080×1664, JPEG, ~135 KB) — już dodany do repo. Folder `assets/images/backgrounds/` jest w całości zadeklarowany w `pubspec.yaml` (`flutter: assets:`), więc **nie trzeba nic zmieniać w pubspec.yaml** — plik jest automatycznie dostępny jako asset.

**Opis:** sylwetka zamku o zmierzchu/w nocy — mury z blankami, dwie baszty narożne, brama-gatehouse z dwiema wieżami flankującymi, wysoka wieża główna (keep) na środku, flagi na szczytach, świecące (ciepłe złote `#C9A227`/`#F7CA64`) okna rozsiane po fasadzie i jasno podświetlona łukowa brama na dole. Niebo w gradiencie atrament (`#14090C`) → fiolet zmierzchu (`#241A26`) → burgund (`#5F1A22`/`#7A1F2B`) z księżycem w poświacie i gwiazdami; mgła u podnóża wzgórza, unoszące się iskry, ciemniejsze wzgórze w tle i najciemniejsza sylwetka wzgórza na samym dole kadru dla głębi. Styl płaskiej ilustracji/sylwetki (nie fotorealizm — wygenerowane proceduralnie, bez dostępu do generatora obrazów AI w tej sesji), bez ludzkich postaci/twarzy — bezpiecznie jako tło pod każdym ekranem.

**Jak to jest dziś podłączone (bazowa gra):** `lib/widgets/animated_new_background.dart` → `AnimatedNewBackground` renderuje: (1) statyczny obraz z `AnimatedNewBackground.assetPath` (dziś **`static const`**, na sztywno `'assets/images/backgrounds/new_background.jpg'`), (2) ciemny gradient nakładkowy, (3) animowaną, "oddychającą" czerwoną poświatę (kolory `0xFF7A0E14`/`0xFFD62330`, na sztywno w kodzie), (4) opcjonalny deszcz (`_AnimatedRainPainter`, parametr `rain`). Używane globalnie przez `MafiaIOSScaffold` w `lib/ui_system/mafia_ios_system.dart`.

**Co trzeba zmienić, żeby użyć nowego tła (konkretne kroki):**
1. W `animated_new_background.dart` zmienić `assetPath` ze `static const` na pole instancji z wartością domyślną: `final String assetPath; const AnimatedNewBackground({..., this.assetPath = 'assets/images/backgrounds/new_background.jpg', ...})`. Bez tego nie da się podmienić obrazu per edycja bez kopiowania całego widgetu.
2. Dodać parametr `glowColors` (lista 2 kolorów) do `AnimatedNewBackground`, zastępujący dziś zahardkodowane `0xFF7A0E14`/`0xFFD62330` w dwóch `RadialGradient` — dla tej edycji przekazać `[Color(0xFF7A1F2B), Color(0xFFC9A227)]` (burgund→złoto zamiast czerwieni).
3. Dla tej edycji wywołać z `rain: false` (deszcz nie pasuje do klimatu dworskiego) — docelowo można dodać `_AnimatedEmberPainter` (drobne, wolno unoszące się w górę iskry) jako odpowiednik `_AnimatedRainPainter`, spójny z iskrami już obecnymi na statycznym obrazie.
4. `MafiaIOSScaffold` (w `mafia_ios_system.dart`) powinien przyjąć/przekazać te same parametry (`assetPath`, `glowColors`, `rain`) dalej do `AnimatedNewBackground`, sterowane globalnym stanem "aktualna edycja" (np. z `GameRoom.edition` po dołączeniu do pokoju).
5. `_FallbackMafiaGradient` (używany, gdy obrazek się nie wczyta) też warto mieć w wariancie burgund/złoto zamiast czerwono-czarnego, dla spójności awaryjnego widoku.

---

## 13. Ceremonia pasowania i papirus tożsamości (animacja odkrycia klasy)

**Kontekst w kodzie:** dzisiejszy ekran odkrycia roli to `RoleRevealScreen`, zdefiniowany w `lib/data/card.dart` (mimo nazwy pliku — to ekran, nie dane). Zawiera animację "jednorękiego bandyty" (`_Reel`, `_SlotLever`, `_ReelSymbol`) kończącą się pokazaniem "wydrukowanego identyfikatora" (`_displayId` — hash z `playerId`, opisany w kodzie jako "matches the in-game ID app"). Ten sam ekran jest reużywany później z flagą `instantIdOnly: true`, która pomija animację i pokazuje od razu ID (używane dziś z menu Avatar → "Twoje ID", `_AvatarMenuApp` w `started_game_screen.dart`). Osobno, `_IdCardApp` (też w `started_game_screen.dart`) to trwała aplikacja na ekranie głównym (ikona "ID", `Icons.badge_rounded`) pokazująca ten sam identyfikator w dowolnym momencie gry.

**Do zrobienia dla tej edycji:**

1. **Animacja pasowania postaci przez króla** — dla tej edycji zamiast automatu do gier: sylwetka/ilustracja króla (korona, płaszcz, miecz lub berło) wykonuje animowany gest pasowania na rycerza/daną klasę — miecz dotyka najpierw prawego, potem lewego ramienia gracza (dwa kroki animacji, analogicznie do dzisiejszego "kręcenia bębnami" kończącego się zatrzymaniem na wyniku), z błyskiem/iskrami przy każdym dotknięciu, po czym odkrywa się nazwa i ikona wylosowanej klasy (sekcja 6). Wymaga nowego zestawu widgetów równoległego do `_Reel`/`_SlotLever`/`_ReelSymbol` (np. `_KnighthoodCeremony`/`_KingFigure`/`_SwordTouchEffect`), a `RoleRevealScreen` potrzebuje parametru (np. `edition`) wybierającego, którą z dwóch animacji odpalić — ten sam mechanizm przełączania "aktualna edycja", co dla tła w sekcji 12.
2. **Papirus zamiast wydrukowanego identyfikatora** — finałowy widok ID (w `RoleRevealScreen` po zakończeniu animacji/z `instantIdOnly: true`, oraz w `_IdCardApp`) ma w tej edycji wyglądać jak zwój pergaminu, nie nowoczesna karta: tekstura postarzonego papirusu (`#EDE0C8` z przybrudzeniami/plamami), postrzępione krawędzie, czerwona pieczęć lakowa (`#7A1F2B`) z herbem odciśnięta przy identyfikatorze. Tekst czcionką `BernierDistressed` (już w projekcie — `assets/fonts/bernier_distressed.ttf`, zadeklarowana w `pubspec.yaml` — pasuje do postarzonego pisma lepiej niż zwykły `Bernier`). Treść identyczna jak dziś: ten sam hash `_displayId` + nazwa klasy + jej ikona (sekcja 6).
3. Paleta obu elementów zgodna z sekcją 2/12 (burgund/złoto/atrament) — nie z czerwienią bazowej gry.
