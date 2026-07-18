// ═══════════════════════════════════════════════════════════════════════════
//  KALAMBURY — hasła do pokazywania  (edytuj śmiało — dopisuj własne!)
// ═══════════════════════════════════════════════════════════════════════════
//
// Każdy wpis to hasło + kategoria (dowolny tekst, np. Zwierzę, Czynność, Film).
//
// JAK DOPISAĆ WŁASNE HASŁO — dodaj do listy [kCharadesPrompts]:
//   CharadesPrompt('Twoje hasło', 'Kategoria'),

class CharadesPrompt {
  const CharadesPrompt(this.text, this.category);
  final String text;
  final String category;
}

/// Pula haseł do kalambur. Dopisuj do woli — losowanie widzi zmiany od razu.
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
