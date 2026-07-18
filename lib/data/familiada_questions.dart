// ═══════════════════════════════════════════════════════════════════════════
//  FAMILIADA — pytania ankietowe  (edytuj śmiało — dopisuj własne!)
// ═══════════════════════════════════════════════════════════════════════════
//
// Każdy wpis to pytanie + lista odpowiedzi z punktami (styl Familiady),
// UPORZĄDKOWANA od najwyższej do najniższej liczby punktów.
//
// JAK DOPISAĆ WŁASNE PYTANIE — dodaj do listy [kFamiliadaSurveys]:
//   FamiliadaSurvey('Treść pytania?', [
//     FamiliadaAnswer('Najpopularniejsza odpowiedź', 30),
//     FamiliadaAnswer('Kolejna odpowiedź', 22),
//     // zwykle 4-6 odpowiedzi, punkty malejąco
//   ]),

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

/// Pula pytań Familiady. Dopisuj do woli — losowanie widzi zmiany od razu.
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
    FamiliadaAnswer('Piłka ręczna', 20),
    FamiliadaAnswer('Koszykówka', 17),
    FamiliadaAnswer('Siatkówka', 15),
    FamiliadaAnswer('Tenis', 11),
    FamiliadaAnswer('Pływanie', 7),
  ]),
  FamiliadaSurvey('Podaj coś, co robisz na telefonie w toalecie.', [
    FamiliadaAnswer('Scrolluje tik-toka', 34),
    FamiliadaAnswer('Wale konia', 22),
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
    FamiliadaAnswer('Grasz w grę', 15),
    FamiliadaAnswer('Jesz', 13),
    FamiliadaAnswer('Dzwonisz do kogoś', 10),
    FamiliadaAnswer('Wychodzisz na spacer', 8),
  ]),
  FamiliadaSurvey('Wymień markę samochodu.', [
    FamiliadaAnswer('Honda', 24),
    FamiliadaAnswer('Lexus', 22),
    FamiliadaAnswer('Toyota', 18),
    FamiliadaAnswer('Mitsubishi', 16),
    FamiliadaAnswer('Mazda', 12),
    FamiliadaAnswer('Nissan', 8),
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
    FamiliadaAnswer('Kożystasz z telefonu', 30),
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
  FamiliadaSurvey('Co wypije z chęcią Rafał? ', [
    FamiliadaAnswer('Whisky', 30),
    FamiliadaAnswer('Piwo', 24),
    FamiliadaAnswer('Kawe', 16),
    FamiliadaAnswer('Wino', 14),
    FamiliadaAnswer('Drink', 10),
    FamiliadaAnswer('Sok', 6),
  ]),
];
