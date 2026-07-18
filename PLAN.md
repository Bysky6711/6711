# Plan rozbudowy Mafii — UI (One UI) + waluta, zadania, licytacja, rozdawanie kart

Status: **do akceptacji**. Nic z tego nie jest jeszcze wdrożone. Robimy etapami —
każdy etap jest osobno testowalny, żeby łatwiej łapać błędy (nie mam tu jak
uruchomić apki, więc testujesz po każdym etapie na dobrej sieci / telefonie).

---

## Cel
1. Całe UI w stylu **Samsung One UI** (bardziej „jak smartfon").
2. Dopieszczone tło + ładniejsze przyciski i przejścia między ekranami.
3. Lepszy system rzucania kart.
4. Gospodarz może **przydzielać karty mocy** konkretnym graczom (wybór karty + gracza).
5. **Waluta** w grze + 2 mini-gry rywalizacyjne: **Refleks** i **Quiz**.
6. **Licytacja** kart za walutę — osobna mechanika (nie zadanie).

---

## Etap 1 — Warstwa wizualna (One UI)
Nowy, lekki system UI w stylu One UI, zastępujący obecny „iOS glass":
- `lib/ui_system/one_ui.dart` — `OneUiScaffold` (duży, zwijany nagłówek jak w One UI —
  wielki tytuł u góry, chowa się przy scrollu), `OneUiCard`, `OneUiButton`,
  `OneUiListTile`, `OneUiChip`, `OneUiBottomSheet`, pasek statusu telefonu
  (zegar, bateria, zasięg, WiFi) + pasek nawigacji/„home".
- Przejścia między ekranami: **Material shared-axis / fade-through** (płynne,
  „androidowe") zamiast obecnego fade+scale.
- Tło: dopieszczony `AnimatedNewBackground` — subtelniejszy dryf gradientu,
  lekki parallax, spokojniejszy deszcz, respekt dla „ogranicz animacje".
- Przyciski: One UI (wyraźny ripple, duże cele dotykowe, stany wciśnięcia).
- Rzucanie kart: nowa animacja (karta „wychodzi" z ręki, One UI bottom sheet
  do wyboru celu, potwierdzenie + haptyka).

Reskin ekranów: menu, host, dołączanie, lobby, gra (home + apki), losowanie roli, czat.
**Testowalne lokalnie nawet bez Firestore** (to sam wygląd).

## Etap 2 — Model danych + rozdawanie kart przez gospodarza
- Ręce graczy przenosimy do Firestore (teraz są lokalne):
  `rooms/{KOD}/hands/{playerId}` → `{ cards: [idKarty, ...] }`.
  Gracz widzi swoją rękę na żywo; gospodarz może pisać do każdej.
- Panel gospodarza: **„Rozdaj kartę"** → wybór karty mocy z listy + wybór gracza →
  karta ląduje w jego ręce (na żywo). Opcjonalnie odbieranie kart.
- `OnlineRoomService`: `assignCard`, `removeCard`, `watchHand`.

## Etap 3 — Waluta + mini-gry (Refleks, Quiz)
- **Portfel** gracza: `wallets: { playerId: kwota }` w dokumencie pokoju,
  widoczny jako chip w UI.
- **Refleks**: gospodarz odpala rundę → po losowym czasie sygnał „TAP!" →
  liczy się kto pierwszy; ranking wg czasu reakcji.
- **Quiz**: pytanie + odpowiedzi (pula w `lib/data/quiz_questions.dart` albo
  własne gospodarza) → wygrywa najszybsza poprawna.
- Dane: `rooms/{KOD}/tasks/{taskId}` (typ, stan: oczekuje/trwa/koniec, treść,
  `prizeCardId`) + zgłoszenia graczy; ranking liczony po zamknięciu.
- **Nagrody**: 1. miejsce → wygrywa **kartę** (nagroda). Pozostali dostają walutę
  malejąco, domyślnie: **2. → 30$, 3. → 15$, 4. → 8$, 5.+ → 5$** (konfigurowalne
  przez gospodarza). *(Do potwierdzenia — patrz pytanie niżej.)*
- `OnlineRoomService`: `createTask`, `submitTaskEntry`, `resolveTask` (przyznaje
  kartę zwycięzcy + wypłaca walutę), `watchTasks`.

## Etap 4 — Licytacja (osobna mechanika)
- Gospodarz wystawia kartę na licytację: `rooms/{KOD}/auction` →
  `{ cardId, stan: otwarta/zamknięta, bids: {playerId: kwota}, lider }`.
- Gracze licytują walutą z portfela; wygrywa najwyższa oferta → karta trafia do
  ręki zwycięzcy, kwota schodzi z portfela.
- UI: ekran licytacji (aktualna oferta, lider, twój portfel, przyciski +kwota / „przebij").

---

## Pliki (orientacyjnie)
**Nowe:** `ui_system/one_ui.dart`, `models/game_task.dart`, `models/auction.dart`,
`data/quiz_questions.dart`, ekrany zadań i licytacji.
**Zmieniane:** wszystkie ekrany (reskin One UI), `online_room_service.dart` (nowe metody),
`game_room`/model (portfele), `started_game_screen.dart` (rozdawanie kart, zadania,
licytacja, portfel), obsługa ręki z Firestore zamiast lokalnej.

## Ryzyka / uwagi
- Duży zakres — dlatego etapami; po każdym robisz `flutter run` i dajesz feedback.
- Mechaniki online (etapy 2–4) przetestujesz tylko na sieci, która nie blokuje
  Firestore (telefon/LTE/deploy) — pamiętaj o otwartej sprawie z siecią InPost.
- Reguły Firestore rozszerzę o nowe podkolekcje (hands/tasks/auction).

## Do potwierdzenia zanim ruszę (Etap 1)
1. **Waluta za miejsca** — zostajemy przy „lepsze miejsce = więcej" (2.→30, 3.→15…),
   czy wolisz odwrotnie „gorsze miejsce = więcej" (mocniejszy catch-up dla przegranych)?
2. **Nazwa/symbol waluty** — „$", monety, coś tematycznego (np. „banknoty mafii")?
3. Startujemy od **Etapu 1 (wygląd One UI)** — ok?
