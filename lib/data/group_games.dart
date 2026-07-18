import 'dart:math';

// ======================= FAMILIADA (survey / Family Feud) ====================

class FamiliadaAnswer {
  const FamiliadaAnswer(this.text, this.points);
  final String text;
  final int points;
}

class FamiliadaSurvey {
  const FamiliadaSurvey(this.question, this.answers);
  final String question;
  final List<FamiliadaAnswer> answers; // ordered by points, highest first
}

/// Big survey pool. Each question has the "most popular answers" with points,
/// Family-Feud style. Answers are guessable everyday responses.
const List<FamiliadaSurvey> kFamiliadaSurveys = [
  FamiliadaSurvey('Podaj coś, co robisz zaraz po przebudzeniu.', [
    FamiliadaAnswer('Sięgasz po telefon', 34),
    FamiliadaAnswer('Idziesz do toalety', 26),
    FamiliadaAnswer('Pijesz kawę / wodę', 18),
    FamiliadaAnswer('Wyłączasz budzik', 12),
    FamiliadaAnswer('Przeciągasz się', 6),
    FamiliadaAnswer('Myjesz zęby', 4),
  ]),
  FamiliadaSurvey('Wymień rzecz, którą zawsze zabierasz na wakacje.', [
    FamiliadaAnswer('Telefon / ładowarka', 33),
    FamiliadaAnswer('Krem z filtrem', 22),
    FamiliadaAnswer('Okulary słoneczne', 17),
    FamiliadaAnswer('Strój kąpielowy', 14),
    FamiliadaAnswer('Dokumenty / paszport', 9),
    FamiliadaAnswer('Książkę', 5),
  ]),
  FamiliadaSurvey('Podaj popularne danie na imprezę.', [
    FamiliadaAnswer('Pizza', 30),
    FamiliadaAnswer('Chipsy / przekąski', 24),
    FamiliadaAnswer('Kanapki', 16),
    FamiliadaAnswer('Grill / kiełbaski', 14),
    FamiliadaAnswer('Sałatka', 10),
    FamiliadaAnswer('Pierogi', 6),
  ]),
  FamiliadaSurvey('Wymień coś, co często gubisz.', [
    FamiliadaAnswer('Klucze', 31),
    FamiliadaAnswer('Telefon', 23),
    FamiliadaAnswer('Portfel', 15),
    FamiliadaAnswer('Okulary', 13),
    FamiliadaAnswer('Pilot do TV', 10),
    FamiliadaAnswer('Długopis', 8),
  ]),
  FamiliadaSurvey('Podaj zwierzę, które trzyma się w domu.', [
    FamiliadaAnswer('Pies', 38),
    FamiliadaAnswer('Kot', 30),
    FamiliadaAnswer('Rybki', 12),
    FamiliadaAnswer('Chomik', 9),
    FamiliadaAnswer('Papuga', 7),
    FamiliadaAnswer('Królik', 4),
  ]),
  FamiliadaSurvey('Wymień powód spóźnienia do pracy.', [
    FamiliadaAnswer('Korki', 32),
    FamiliadaAnswer('Zaspałem', 28),
    FamiliadaAnswer('Komunikacja się spóźniła', 16),
    FamiliadaAnswer('Nie mogłem czegoś znaleźć', 12),
    FamiliadaAnswer('Kolejka / kawa', 7),
    FamiliadaAnswer('Dziecko / rodzina', 5),
  ]),
  FamiliadaSurvey('Podaj coś, co robisz w deszczowy dzień.', [
    FamiliadaAnswer('Oglądasz film/serial', 30),
    FamiliadaAnswer('Śpisz / leżysz', 20),
    FamiliadaAnswer('Czytasz książkę', 16),
    FamiliadaAnswer('Gotujesz', 13),
    FamiliadaAnswer('Grasz w gry', 12),
    FamiliadaAnswer('Sprzątasz', 9),
  ]),
  FamiliadaSurvey('Wymień napój zamawiany w kawiarni.', [
    FamiliadaAnswer('Latte', 26),
    FamiliadaAnswer('Cappuccino', 22),
    FamiliadaAnswer('Espresso', 18),
    FamiliadaAnswer('Herbata', 15),
    FamiliadaAnswer('Czekolada na gorąco', 11),
    FamiliadaAnswer('Frappe', 8),
  ]),
  FamiliadaSurvey('Podaj coś, czego boją się ludzie.', [
    FamiliadaAnswer('Pająki', 28),
    FamiliadaAnswer('Wysokość', 24),
    FamiliadaAnswer('Ciemność', 16),
    FamiliadaAnswer('Węże', 14),
    FamiliadaAnswer('Dentysta', 10),
    FamiliadaAnswer('Latanie', 8),
  ]),
  FamiliadaSurvey('Wymień coś, co znajdziesz w kuchni.', [
    FamiliadaAnswer('Lodówka', 26),
    FamiliadaAnswer('Garnki / patelnia', 22),
    FamiliadaAnswer('Kuchenka', 18),
    FamiliadaAnswer('Sztućce', 15),
    FamiliadaAnswer('Czajnik', 11),
    FamiliadaAnswer('Mikrofalówka', 8),
  ]),
  FamiliadaSurvey('Podaj pierwszą rzecz, którą kupujesz w sklepie.', [
    FamiliadaAnswer('Chleb / pieczywo', 30),
    FamiliadaAnswer('Mleko', 24),
    FamiliadaAnswer('Woda / napoje', 16),
    FamiliadaAnswer('Owoce / warzywa', 14),
    FamiliadaAnswer('Słodycze', 10),
    FamiliadaAnswer('Nabiał', 6),
  ]),
  FamiliadaSurvey('Wymień sport, który uprawiają Polacy.', [
    FamiliadaAnswer('Piłka nożna', 30),
    FamiliadaAnswer('Bieganie', 20),
    FamiliadaAnswer('Rower', 17),
    FamiliadaAnswer('Siatkówka', 15),
    FamiliadaAnswer('Siłownia', 11),
    FamiliadaAnswer('Pływanie', 7),
  ]),
  FamiliadaSurvey('Podaj coś, co robisz na telefonie w toalecie.', [
    FamiliadaAnswer('Scrollujesz social media', 34),
    FamiliadaAnswer('Oglądasz filmiki', 22),
    FamiliadaAnswer('Piszesz wiadomości', 18),
    FamiliadaAnswer('Czytasz newsy', 12),
    FamiliadaAnswer('Grasz w grę', 9),
    FamiliadaAnswer('Robisz zakupy', 5),
  ]),
  FamiliadaSurvey('Wymień wymówkę, by nie iść na imprezę.', [
    FamiliadaAnswer('Jestem zmęczony', 30),
    FamiliadaAnswer('Jestem chory', 24),
    FamiliadaAnswer('Nie mam czasu', 16),
    FamiliadaAnswer('Muszę pracować', 14),
    FamiliadaAnswer('Nie mam z kim zostawić dzieci', 9),
    FamiliadaAnswer('Za daleko', 7),
  ]),
  FamiliadaSurvey('Podaj rzecz, którą masz zawsze przy sobie.', [
    FamiliadaAnswer('Telefon', 38),
    FamiliadaAnswer('Klucze', 24),
    FamiliadaAnswer('Portfel', 20),
    FamiliadaAnswer('Słuchawki', 10),
    FamiliadaAnswer('Chusteczki', 5),
    FamiliadaAnswer('Guma do żucia', 3),
  ]),
  FamiliadaSurvey('Wymień coś, co kojarzy się ze świętami.', [
    FamiliadaAnswer('Choinka', 30),
    FamiliadaAnswer('Prezenty', 26),
    FamiliadaAnswer('Rodzina', 16),
    FamiliadaAnswer('Karp / potrawy', 13),
    FamiliadaAnswer('Śnieg', 9),
    FamiliadaAnswer('Kolędy', 6),
  ]),
  FamiliadaSurvey('Podaj coś, co robisz gdy się nudzisz.', [
    FamiliadaAnswer('Telefon / social media', 32),
    FamiliadaAnswer('Oglądasz coś', 22),
    FamiliadaAnswer('Śpisz', 15),
    FamiliadaAnswer('Jesz', 13),
    FamiliadaAnswer('Dzwonisz do kogoś', 10),
    FamiliadaAnswer('Wychodzisz na spacer', 8),
  ]),
  FamiliadaSurvey('Wymień markę samochodu.', [
    FamiliadaAnswer('Toyota', 24),
    FamiliadaAnswer('BMW', 22),
    FamiliadaAnswer('Audi', 18),
    FamiliadaAnswer('Mercedes', 16),
    FamiliadaAnswer('Volkswagen', 12),
    FamiliadaAnswer('Ford', 8),
  ]),
  FamiliadaSurvey('Podaj coś, co widać na plaży.', [
    FamiliadaAnswer('Piasek', 26),
    FamiliadaAnswer('Parasole / leżaki', 22),
    FamiliadaAnswer('Morze / fale', 18),
    FamiliadaAnswer('Muszelki', 14),
    FamiliadaAnswer('Mewy', 11),
    FamiliadaAnswer('Zamki z piasku', 9),
  ]),
  FamiliadaSurvey('Wymień zawód, o którym marzą dzieci.', [
    FamiliadaAnswer('Strażak', 24),
    FamiliadaAnswer('Policjant', 20),
    FamiliadaAnswer('Lekarz', 18),
    FamiliadaAnswer('Piłkarz', 16),
    FamiliadaAnswer('Youtuber', 12),
    FamiliadaAnswer('Astronauta', 10),
  ]),
  FamiliadaSurvey('Podaj coś, co robisz przed snem.', [
    FamiliadaAnswer('Telefon', 30),
    FamiliadaAnswer('Myjesz zęby', 24),
    FamiliadaAnswer('Oglądasz serial', 16),
    FamiliadaAnswer('Czytasz', 13),
    FamiliadaAnswer('Ustawiasz budzik', 10),
    FamiliadaAnswer('Bierzesz prysznic', 7),
  ]),
  FamiliadaSurvey('Wymień owoc.', [
    FamiliadaAnswer('Jabłko', 28),
    FamiliadaAnswer('Banan', 22),
    FamiliadaAnswer('Truskawka', 16),
    FamiliadaAnswer('Pomarańcza', 14),
    FamiliadaAnswer('Winogrono', 12),
    FamiliadaAnswer('Arbuz', 8),
  ]),
  FamiliadaSurvey('Podaj coś, co psuje humor rano.', [
    FamiliadaAnswer('Budzik / za mało snu', 30),
    FamiliadaAnswer('Korki', 20),
    FamiliadaAnswer('Zła pogoda', 17),
    FamiliadaAnswer('Brak kawy', 14),
    FamiliadaAnswer('Poniedziałek / praca', 12),
    FamiliadaAnswer('Kłótnia', 7),
  ]),
  FamiliadaSurvey('Wymień coś, co robisz na wakacjach nad morzem.', [
    FamiliadaAnswer('Opalasz się', 26),
    FamiliadaAnswer('Pływasz / kąpiesz się', 24),
    FamiliadaAnswer('Jesz lody / gofry', 16),
    FamiliadaAnswer('Spacerujesz po plaży', 14),
    FamiliadaAnswer('Grasz w piłkę', 11),
    FamiliadaAnswer('Zbierasz muszelki', 9),
  ]),
];

// =============================== KALAMBURY (charades) ========================

class CharadesPrompt {
  const CharadesPrompt(this.text, this.category);
  final String text;
  final String category;
}

/// Prompts to act out. Mix of easy → medium so most are guessable.
const List<CharadesPrompt> kCharadesPrompts = [
  // Zwierzęta
  CharadesPrompt('Słoń', 'Zwierzę'),
  CharadesPrompt('Kangur', 'Zwierzę'),
  CharadesPrompt('Pingwin', 'Zwierzę'),
  CharadesPrompt('Małpa', 'Zwierzę'),
  CharadesPrompt('Wąż', 'Zwierzę'),
  CharadesPrompt('Kogut', 'Zwierzę'),
  CharadesPrompt('Żaba', 'Zwierzę'),
  CharadesPrompt('Krokodyl', 'Zwierzę'),
  CharadesPrompt('Pająk', 'Zwierzę'),
  CharadesPrompt('Kot', 'Zwierzę'),
  // Czynności
  CharadesPrompt('Mycie zębów', 'Czynność'),
  CharadesPrompt('Gra na gitarze', 'Czynność'),
  CharadesPrompt('Pływanie', 'Czynność'),
  CharadesPrompt('Robienie selfie', 'Czynność'),
  CharadesPrompt('Prowadzenie samochodu', 'Czynność'),
  CharadesPrompt('Odkurzanie', 'Czynność'),
  CharadesPrompt('Boks', 'Czynność'),
  CharadesPrompt('Malowanie ściany', 'Czynność'),
  CharadesPrompt('Taniec', 'Czynność'),
  CharadesPrompt('Robienie zdjęć', 'Czynność'),
  CharadesPrompt('Gotowanie zupy', 'Czynność'),
  CharadesPrompt('Wędkowanie', 'Czynność'),
  // Zawody
  CharadesPrompt('Policjant', 'Zawód'),
  CharadesPrompt('Lekarz', 'Zawód'),
  CharadesPrompt('Kucharz', 'Zawód'),
  CharadesPrompt('Fryzjer', 'Zawód'),
  CharadesPrompt('Nauczyciel', 'Zawód'),
  CharadesPrompt('Strażak', 'Zawód'),
  CharadesPrompt('Dyrygent', 'Zawód'),
  CharadesPrompt('Kelner', 'Zawód'),
  CharadesPrompt('Pilot samolotu', 'Zawód'),
  CharadesPrompt('Dentysta', 'Zawód'),
  // Filmy / postacie
  CharadesPrompt('Spider-Man', 'Postać'),
  CharadesPrompt('Batman', 'Postać'),
  CharadesPrompt('Harry Potter', 'Postać'),
  CharadesPrompt('Shrek', 'Postać'),
  CharadesPrompt('Elsa (Kraina Lodu)', 'Postać'),
  CharadesPrompt('James Bond', 'Postać'),
  CharadesPrompt('Kubuś Puchatek', 'Postać'),
  CharadesPrompt('Terminator', 'Postać'),
  CharadesPrompt('Mikołaj', 'Postać'),
  CharadesPrompt('Zombie', 'Postać'),
  // Przedmioty
  CharadesPrompt('Parasol', 'Przedmiot'),
  CharadesPrompt('Telefon', 'Przedmiot'),
  CharadesPrompt('Gitara', 'Przedmiot'),
  CharadesPrompt('Nożyczki', 'Przedmiot'),
  CharadesPrompt('Aparat fotograficzny', 'Przedmiot'),
  CharadesPrompt('Odkurzacz', 'Przedmiot'),
  CharadesPrompt('Latawiec', 'Przedmiot'),
  CharadesPrompt('Budzik', 'Przedmiot'),
  CharadesPrompt('Miotła', 'Przedmiot'),
  CharadesPrompt('Prysznic', 'Przedmiot'),
  // Sporty
  CharadesPrompt('Piłka nożna', 'Sport'),
  CharadesPrompt('Koszykówka', 'Sport'),
  CharadesPrompt('Tenis', 'Sport'),
  CharadesPrompt('Narciarstwo', 'Sport'),
  CharadesPrompt('Golf', 'Sport'),
  CharadesPrompt('Podnoszenie ciężarów', 'Sport'),
  CharadesPrompt('Łucznictwo', 'Sport'),
  CharadesPrompt('Skoki narciarskie', 'Sport'),
  CharadesPrompt('Jazda konna', 'Sport'),
  CharadesPrompt('Surfing', 'Sport'),
  // Emocje / stany
  CharadesPrompt('Złość', 'Emocja'),
  CharadesPrompt('Radość', 'Emocja'),
  CharadesPrompt('Strach', 'Emocja'),
  CharadesPrompt('Zmęczenie', 'Emocja'),
  CharadesPrompt('Zakochanie', 'Emocja'),
  CharadesPrompt('Zdziwienie', 'Emocja'),
  // Miejsca / sytuacje
  CharadesPrompt('Lot samolotem', 'Sytuacja'),
  CharadesPrompt('Wizyta u dentysty', 'Sytuacja'),
  CharadesPrompt('Zakupy w markecie', 'Sytuacja'),
  CharadesPrompt('Poranny korek', 'Sytuacja'),
  CharadesPrompt('Egzamin', 'Sytuacja'),
  CharadesPrompt('Randka', 'Sytuacja'),
  CharadesPrompt('Trzęsienie ziemi', 'Sytuacja'),
  CharadesPrompt('Mecz na stadionie', 'Sytuacja'),
];

// ====================== JAK DOBRZE ZNASZ ZNAJOMYCH (poll) ===================

/// "Kto z waszej grupy najprawdopodobniej…" — everyone points at one player;
/// the group scores only if at least 75% agree on the same person.
const List<String> kFriendsPrompts = [
  'Kto najczęściej się spóźnia?',
  'Kto jest najgorszym kierowcą?',
  'Kto pierwszy zaśnie na imprezie?',
  'Kto najbardziej lubi robić selfie?',
  'Kto wyda najwięcej na zakupy w jeden dzień?',
  'Kto najczęściej zapomina o urodzinach?',
  'Kto najgłośniej się śmieje?',
  'Kto najprędzej zgubi telefon?',
  'Kto zje najwięcej na wspólnej kolacji?',
  'Kto najczęściej mówi „już jestem w drodze", nie wychodząc z domu?',
  'Kto najlepiej tańczy?',
  'Kto najczęściej ogląda seriale do rana?',
  'Kto pierwszy zadzwoni, gdy ma problem?',
  'Kto najbardziej boi się pająków?',
  'Kto najczęściej robi zdjęcia jedzeniu?',
  'Kto najgorzej znosi porażkę w grach?',
  'Kto najczęściej mówi „tylko jeden odcinek"?',
  'Kto ma najwięcej aplikacji na telefonie?',
  'Kto najprędzej rozpłacze się na filmie?',
  'Kto najczęściej gubi klucze?',
  'Kto pierwszy sięgnie po ostatni kawałek pizzy?',
  'Kto najczęściej odpisuje po tygodniu na wiadomość?',
  'Kto najbardziej lubi być w centrum uwagi?',
  'Kto najprędzej wyda fortunę na coś niepotrzebnego?',
  'Kto najczęściej zmienia zdanie?',
  'Kto najlepiej gotuje?',
  'Kto najgorzej śpiewa?',
  'Kto najczęściej mówi „nie jestem głodny", po czym podjada?',
  'Kto pierwszy zorganizuje wspólny wyjazd?',
  'Kto najbardziej panikuje przed egzaminem/prezentacją?',
  'Kto najczęściej zasypia przed telewizorem?',
  'Kto ma najbardziej zabałaganiony pokój?',
  'Kto najprędzej da się namówić na szaleństwo?',
  'Kto najczęściej narzeka na pogodę?',
  'Kto zrobi najlepsze imprezowe zdjęcia?',
  'Kto najczęściej mówi „obiecuję, że tym razem zdążę"?',
  'Kto najprędzej wygadałby cudzy sekret?',
  'Kto najbardziej lubi planować wszystko z góry?',
  'Kto najczęściej mówi „ostatni raz" i wraca po dokładkę?',
  'Kto pierwszy wstałby, by pomóc znajomemu w nocy?',
];

// =============================== draw helpers ================================

final Random _ggRng = Random();

int _drawUnique(int poolSize, Set<int> used) {
  if (used.length >= poolSize) used.clear();
  final available = [
    for (var i = 0; i < poolSize; i++)
      if (!used.contains(i)) i,
  ];
  final pick = available[_ggRng.nextInt(available.length)];
  used.add(pick);
  return pick;
}

final Set<int> _usedFamiliada = <int>{};
final Set<int> _usedCharades = <int>{};
final Set<int> _usedFriends = <int>{};

FamiliadaSurvey drawFamiliadaSurvey() => kFamiliadaSurveys[_drawUnique(kFamiliadaSurveys.length, _usedFamiliada)];
CharadesPrompt drawCharadesPrompt() => kCharadesPrompts[_drawUnique(kCharadesPrompts.length, _usedCharades)];
String drawFriendsPrompt() => kFriendsPrompts[_drawUnique(kFriendsPrompts.length, _usedFriends)];

// Index-returning draws (used when the choice must be synced across devices).
int drawFamiliadaIndex() => _drawUnique(kFamiliadaSurveys.length, _usedFamiliada);
int drawCharadesIndex() => _drawUnique(kCharadesPrompts.length, _usedCharades);
int drawFriendsIndex() => _drawUnique(kFriendsPrompts.length, _usedFriends);
