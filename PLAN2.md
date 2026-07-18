# Plan v2 — kolejna partia zmian (do akceptacji)

Pogrupowane etapy. Robimy po kolei, każdy testujesz. Nic z tego jeszcze nie wdrożone.

## Etap 5 — szybkie poprawki (bugi + drobne)
- **Rola gospodarza** = „GOSPODARZ", nie „MAFIA" (na karcie i w losowaniu).
- **Zegar**: usunąć wielki zegar z ekranu gry (nie synchronizował się), zostawić tylko ten na pasku statusu; nagłówek wypełnić **dużym wskaźnikiem aktualnej FAZY** gry (ikona + nazwa + kolor).
- **Suwak „Prywatność kart"** — naprawa (teraz wraca po przesunięciu, bo ekran ustawień jest bezstanowym „snapshotem"). Zrobię ekran ustawień stanowym.
- **„Karty mocy" i „Moja karta"** = zwykłe ikony aplikacji (jak reszta), zawartość dopiero po wejściu.
- **„Menu"** (ikona) → wychodzi do menu głównego **i opuszcza pokój** (usuwa gracza z lobby).
- **Host „Byski"** → może wystartować grę solo (pomija wymóg kompletu graczy) — tryb testowy.
- **Fullscreen**: web (immersive/na cały ekran) + iOS (ukryty status bar / edge-to-edge).

## Etap 6 — zadania: dopracowanie
- W stanie „oczekuje" gracz widzi **tylko rodzaj** (Refleks/Quiz), bez szczegółów (pytanie ukryte do startu).
- Po **starcie** zadania wszyscy gracze **auto-przechodzą** na okno „Zadania".
- Host widzi licznik **„X / N graczy wykonało"**.

## Etap 7 — widoczność zagranych kart — ✅ ZROBIONE 2026-07-16
Cel: „widać kto rzucił kartę na kogo", ładnie graficznie.
- **Baner/toast u wszystkich**, gdy ktoś zagra kartę (np. „Ala → Zatrute whiskey → Bartek"), znika po chwili.
- **Przesunięcie w LEWO** = graficzny **feed zagranych kart**: awatar rzucającego → ikona/kolor karty → awatar celu, na żywo (z kolekcji `actions`, którą już mamy).
- Decyzja potrzebna: **pełna jawność** czy **respektować tajność** kart (część kart ma `secret: true` — np. mafijne). Patrz pytanie.

## Etap 8 — przejście w prawo = GŁOSOWANIA — ✅ ZROBIONE 2026-07-16
- Przesunięcie w **prawo** = ekran **głosowania** (każdy głosuje na kogo; podliczanie na żywo; host widzi wynik), zamiast obecnych ustawień. Ustawienia zostają jako ikona aplikacji.

## Etap 9 — czat: prywatne rozmowy + naklejki — czat ✅ ZROBIONE 2026-07-16 (prywatne 1:1 + powiadomienia Discord); naklejki = 9c TODO (wymaga image_picker + pub get)
- **Prywatne 1:1** z każdym graczem (kanały „private" per gracz) — wróci do szyny kanałów.
- **Host** widzi #ogólny + #mafia (jest; utrzymam z DM-ami).
- **Naklejki z galerii** (własne) → wymaga **Firebase Storage**, a to na Twoim projekcie oznacza plan **Blaze (płatny** po darmowym limicie — mały ruch = grosze, ale karta wymagana). Patrz pytanie (alternatywa: gotowy zestaw naklejek, za darmo).

## Etap 10 — nowa animacja losowania roli — ✅ ZROBIONE 2026-07-16 (pionowe bębny + dźwignia)
- Nowy „jednoręki bandyta": bębny z **ikonami ról**, losowe kręcenie i zatrzymanie na wylosowanej roli, potem karta.

---

## Do decyzji (zanim ruszę)
1. **Naklejki**: Blaze + wgrywanie z galerii, czy gotowy zestaw (za darmo), czy pomijamy na razie?
2. **Tajność kart**: pełna jawność wszystkich zagrań, czy karty `secret` widzi tylko gospodarz?
3. **Tempo**: lecimy etapami od Etapu 5 (polecane), czy inna kolejność?

---

## Etap 11 — kolejna partia (z czatu 2026-07-16) — ✅ ZROBIONE 2026-07-16 (żywi/martwi, kolory ikon, usunięto Premium)
- [x] Karta gospodarza ≠ mafia (neutralny rewers `card_back_blue`, zamiast obrazka mafii). ZROBIONE.
- [x] Zegar na pasku statusu odświeża się na żywo (Timer co 10 s). ZROBIONE.
- [ ] Usunąć stare pozostałości: zbędne opisy/placeholdery (np. „Premium", filler w „Zadania"/„Zasady") i martwe komentarze.
- [ ] Powiadomienia czatu jak na Discordzie: badge na ikonie „wiadomości" tylko gdy **nowa** wiadomość (licznik nieprzeczytanych) + toast, gdy ktoś napisze (ogólny/mafia/DM). Zamiast stałego `badge: 1`.
- [ ] Lista **żywych i martwych** graczy (nowe pole `alive` na GamePlayer; host oznacza; ekran/panel z podziałem). Powiązane z głosowaniem (Etap 8).
- [ ] Poprawić ikony wyboru na pulpicie głównym (czytelniejsze, rozróżnialne kolory per apka).
- [x] Karty mają **efekty** — overlay/animacja u celu ✅ ZROBIONE w Etapie 7; realne rozliczanie efektów → Etap 12.

## Etap 12 — z czatu 2026-07-16 — ✅ ZROBIONE 2026-07-16 (kopiowanie kodu + efekty kart → statusy)
- [ ] **Kopiowanie kodu pokoju** dla graczy (przycisk „Kopiuj kod" w lobby / na pulpicie — łatwe udostępnienie).
- [ ] **Karty realnie rozliczają swoje efekty** — nie tylko pokazują opis, ale mechanicznie zmieniają stan gry przy rozliczeniu fazy (np. Zatrute whiskey → oznacza/zabija cel; Kajdanki → blokuje karty celu; Antidotum → zdejmuje zatrucie; Kukła / Nie tym razem → neguje atak). Wymaga pól statusów na graczu + logiki rozliczania w `changePhase` (spina się z Etapem 7 + 11 alive/dead).

