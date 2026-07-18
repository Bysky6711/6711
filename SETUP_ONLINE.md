# Tryb online (Firebase Firestore) — konfiguracja

Gra działa teraz w trybie **online, realtime** przez Cloud Firestore. Gospodarz
tworzy pokój, gracze dołączają kodem ze swoich telefonów, a lista graczy, role,
faza gry, karty mocy i czat synchronizują się na żywo.

Kod aplikacji jest gotowy, ale **musisz raz podłączyć swój projekt Firebase**
(nie da się tego zrobić beze mnie — wymaga Twojego konta). To ~10 minut.

## 1. Utwórz projekt Firebase
1. Wejdź na https://console.firebase.google.com → **Add project**.
2. W projekcie: **Build → Firestore Database → Create database**.
   Wybierz lokalizację (np. `eur3`) i tryb **Production**.

## 2. Podłącz projekt do aplikacji (generuje `lib/firebase_options.dart`)
W katalogu `C:\VScode\projekty\mafia`:

```powershell
dart pub global activate flutterfire_cli
flutter pub add firebase_core cloud_firestore   # ustawia zgodne wersje
flutterfire configure
```

`flutterfire configure` poprosi o wybór projektu i platform (Web, Android, iOS)
i **nadpisze** plik-zaślepkę `lib/firebase_options.dart` prawdziwymi kluczami.
Dla Weba doda też automatycznie potrzebne skrypty Firebase.

## 3. Wgraj reguły bezpieczeństwa
W repo jest plik `firestore.rules`. Skopiuj jego treść do:
**Firebase Console → Firestore → Rules → Publish**.

> Uwaga: to reguły deweloperskie (otwarty odczyt/zapis do pokoi). Wystarczą do
> grania ze znajomymi. Aby zabezpieczyć produkcyjnie — dodaj logowanie
> anonimowe (Firebase Auth) i zaostrz reguły (komentarz w pliku).

## 4. Uruchom
```powershell
flutter pub get
flutter run -d edge      # albo -d chrome / urządzenie
```
- **Gospodarz**: „Zostań gospodarzem" → ustaw role → „Utwórz pokój" → podaj kod.
- **Gracze**: „Dołącz do gry" → nick → wpisz 5-znakowy kod → „Dołącz".
- Gdy komplet graczy dołączy, gospodarz klika **Start** — każdy dostaje swoją
  rolę na własnym urządzeniu.

## Model danych w Firestore
```
rooms/{KOD}                    -> pokój (gracze, role, faza, status)
rooms/{KOD}/messages/{id}      -> wiadomości czatu
rooms/{KOD}/actions/{id}       -> zagrane karty mocy (widzi gospodarz)
```
Kod pokoju jest identyfikatorem dokumentu, więc dołączanie kodem to jedno
bezpośrednie zapytanie — bez opóźnień.

## Co działa online
- Tworzenie / dołączanie do pokoju kodem, realtime lista graczy.
- Losowy przydział ról przy starcie (transakcja) — każdy widzi swoją kartę.
- Synchronizacja fazy gry (zmienia gospodarz, widzą wszyscy).
- Karty mocy trafiają na żywo do panelu gospodarza; czat #ogólny i #mafia.

## Znane ograniczenia / do dopracowania
- **Brak testów u mnie** — nie mam tu SDK Fluttera ani Twojego projektu Firebase,
  więc po `flutter analyze` mogą wyjść drobne poprawki. Odpal go przed grą.
- Prywatność kanału #mafia jest egzekwowana po stronie klienta (OK na imprezę,
  do zaostrzenia regułami + Auth).
- Czat: kanały #ogólny i #mafia (prywatne 1:1 możemy dodać później).
- „Ręka" kart mocy gracza jest lokalna na urządzeniu (zagranie zapisuje akcję w
  Firestore dla gospodarza).
