# Mafia — impreza w telefonie

Towarzyska gra w stylu Mafia/Werewolf dla większej grupy, działająca **online w czasie
rzeczywistym** (Cloud Firestore). Gospodarz tworzy pokój, gracze dołączają 5‑znakowym
kodem ze swoich telefonów, a role, fazy, karty, głosowania i czat synchronizują się na żywo.

Interfejs w stylu smartfona (One UI): pulpit z „aplikacjami", pełnoekranowe tło,
animacje. Aplikacja jest wieloplatformowa (Android / iOS / Web) i wdrażana na GitHub Pages.

## Dwie edycje

- **Edycja standardowa** — klasyczna Mafia: role (Mafia, Detektyw, Lekarz, Szeryf,
  Obywatel), 17 kart mocy, zadania (quiz), licytacja, waluta.
- **Edycja Średniowiecze** — intrygi dworskie: 10 klas dworu (Emisariusz Węża,
  Strażniczka Tajemnic, Kanonik, Skarbnik, Rycerz, Dziedziczka, Trubadur, Kat,
  Podrzutek, Wróg Publiczny), 30 kart dworskich, drugi zasób **Wpływy** oraz
  **kompromitacja** i **dowody**. Host wybiera edycję przy tworzeniu pokoju.

## Tryby dodatkowe

- **Zadania — Quiz** (tekstowy i obrazkowy): najszybsza poprawna odpowiedź wygrywa
  kartę, reszta walutę.
- **Gry grupowe**: Familiada, Kalambury, „Jak dobrze znasz znajomych".
- **Licytacja** kart za walutę, z odliczającym się licznikiem (jak na aukcji).

## Struktura projektu

```
lib/
  main.dart                     — start aplikacji (Firebase + anon-auth)
  core/                         — kolory, responsywność, stan edycji, sesja
  models/                       — GameRoom, GamePlayer, Auction, VoteSession, GameTask…
  data/                         — treść i definicje:
    roles.dart                  — role bazowe + ich zdolności
    power_cards.dart            — 17 kart bazowych
    medieval_classes.dart       — 10 klas dworu
    medieval_cards.dart         — 30 kart dworskich
    card_registry.dart          — wspólne rozwiązywanie kart obu edycji
    quiz_questions.dart         — pytania quizowe (tekstowe)  ← edytowalne
    quiz_image_questions.dart   — pytania quizowe (obrazkowe) ← edytowalne
    familiada_questions.dart    — Familiada                    ← edytowalne
    kalambury_prompts.dart      — Kalambury                    ← edytowalne
    zgodnosc_prompts.dart       — „Znasz znajomych"            ← edytowalne
  services/online_room_service.dart — backend Firestore (pokoje, karty, głosy…)
  logic/rules_engine.dart       — czysta logika gry (testowana jednostkowo)
  screens/                      — ekrany (menu, host, lobby, gra)
  ui_system/ + widgets/         — system UI i komponenty
test/                           — testy jednostkowe logiki gry
```

## Uruchomienie

Wymaga Fluttera (SDK ^3.12) i podłączonego projektu Firebase — patrz **SETUP_ONLINE.md**
(m.in. `flutterfire configure`, włączenie logowania anonimowego i wgranie
`firestore.rules`).

```powershell
flutter pub get
flutter run -d chrome        # albo -d edge / urządzenie
flutter analyze              # statyczna analiza
flutter test                 # testy logiki gry
```

## Dodawanie treści (pytania, hasła)

Wszystkie pule są zwykłymi listami Dart w `lib/data/` — dopisujesz kolejne wpisy i gotowe
(losowanie widzi zmiany od razu). Na górze każdego pliku jest krótka instrukcja formatu.
Pytania obrazkowe używają adresu URL (`imageUrl`), więc wystarczy wkleić link do obrazka.

## Uwaga o bezpieczeństwie

Gracze są identyfikowani przez id generowane w aplikacji; reguły Firestore wymagają
zalogowanego (anonimowo) użytkownika. To wystarcza do grania ze znajomymi. Dalsze
zaostrzenie (przypięcie zmian stanu do uid hosta) opisano w `firestore.rules`.
