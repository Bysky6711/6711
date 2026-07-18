import 'dart:math';

import 'quiz_image_questions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  PYTANIA TEKSTOWE DO QUIZU  (edytuj śmiało — dopisuj własne!)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// JAK DOPISAĆ WŁASNE PYTANIE — dodaj wpis do listy [kQuizQuestions]:
///   QuizQuestion('Treść pytania?', ['Odp A', 'Odp B', 'Odp C', 'Odp D'], 1,
///       category: 'Ogólne'),
/// gdzie liczba (tu 1) to indeks POPRAWNEJ odpowiedzi liczony od 0
/// (0 = pierwsza, 1 = druga, 2 = trzecia, 3 = czwarta).
///
/// Pytania OBRAZKOWE są w osobnym pliku: quiz_image_questions.dart.
/// Losowanie i tak łączy obie pule, więc wystarczy dopisywać w odpowiednim pliku.
class QuizQuestion {
  const QuizQuestion(
    this.question,
    this.options,
    this.correctIndex, {
    this.category = 'Ogólne',
    this.imageUrl,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;

  /// Opcjonalny obrazek (adres https) pokazywany nad pytaniem. Null = pytanie
  /// czysto tekstowe.
  final String? imageUrl;

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Pula pytań tekstowych. Dopisuj do woli — losowanie widzi zmiany od razu.
const List<QuizQuestion> kQuizQuestions = [
  // --- Geografia ---
  QuizQuestion('Stolica Australii?', ['Sydney', 'Canberra', 'Melbourne', 'Perth'], 1, category: 'Geografia'),
  QuizQuestion('Stolica Kanady?', ['Toronto', 'Vancouver', 'Ottawa', 'Montreal'], 2, category: 'Geografia'),
  QuizQuestion('Najdłuższa rzeka świata?', ['Amazonka', 'Nil', 'Jangcy', 'Missisipi'], 1, category: 'Geografia'),
  QuizQuestion('Największy ocean na Ziemi?', ['Atlantycki', 'Indyjski', 'Spokojny', 'Arktyczny'], 2, category: 'Geografia'),
  QuizQuestion('Na którym kontynencie leży Egipt?', ['Azja', 'Afryka', 'Europa', 'Ameryka Płd.'], 1, category: 'Geografia'),
  QuizQuestion('Które państwo ma najwięcej ludności?', ['Chiny', 'USA', 'Indie', 'Indonezja'], 2, category: 'Geografia'),
  QuizQuestion('Najwyższy szczyt świata?', ['K2', 'Mont Blanc', 'Mount Everest', 'Kilimandżaro'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Hiszpanii?', ['Barcelona', 'Madryt', 'Sewilla', 'Walencja'], 1, category: 'Geografia'),
  QuizQuestion('Stolica Włoch?', ['Mediolan', 'Rzym', 'Neapol', 'Turyn'], 1, category: 'Geografia'),
  QuizQuestion('Stolica Niemiec?', ['Monachium', 'Hamburg', 'Berlin', 'Kolonia'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Rosji?', ['Moskwa', 'Petersburg', 'Kijów', 'Mińsk'], 0, category: 'Geografia'),
  QuizQuestion('Stolica Francji?', ['Lyon', 'Marsylia', 'Paryż', 'Nicea'], 2, category: 'Geografia'),
  QuizQuestion('Stolica USA?', ['Nowy Jork', 'Waszyngton', 'Los Angeles', 'Chicago'], 1, category: 'Geografia'),
  QuizQuestion('Stolica Wielkiej Brytanii?', ['Manchester', 'Liverpool', 'Londyn', 'Birmingham'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Grecji?', ['Ateny', 'Saloniki', 'Sparta', 'Korynt'], 0, category: 'Geografia'),
  QuizQuestion('Stolica Portugalii?', ['Porto', 'Lizbona', 'Faro', 'Braga'], 1, category: 'Geografia'),
  QuizQuestion('Stolica Szwecji?', ['Göteborg', 'Malmö', 'Sztokholm', 'Uppsala'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Czech?', ['Brno', 'Ostrawa', 'Praga', 'Pilzno'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Austrii?', ['Salzburg', 'Graz', 'Wiedeń', 'Linz'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Szwajcarii?', ['Zurych', 'Genewa', 'Berno', 'Bazylea'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Turcji?', ['Stambuł', 'Ankara', 'Izmir', 'Bursa'], 1, category: 'Geografia'),
  QuizQuestion('Stolica Egiptu?', ['Aleksandria', 'Giza', 'Kair', 'Luksor'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Brazylii?', ['Rio de Janeiro', 'São Paulo', 'Brasília', 'Salvador'], 2, category: 'Geografia'),
  QuizQuestion('Stolica Japonii?', ['Pekin', 'Seul', 'Tokio', 'Bangkok'], 2, category: 'Geografia'),
  QuizQuestion('Największe państwo świata (powierzchnia)?', ['Kanada', 'Chiny', 'Rosja', 'USA'], 2, category: 'Geografia'),
  QuizQuestion('Najmniejsze państwo świata?', ['Monako', 'Watykan', 'San Marino', 'Nauru'], 1, category: 'Geografia'),
  QuizQuestion('Ile jest kontynentów na Ziemi?', ['5', '6', '7', '8'], 2, category: 'Geografia'),
  QuizQuestion('Największa gorąca pustynia świata?', ['Gobi', 'Sahara', 'Kalahari', 'Atakama'], 1, category: 'Geografia'),
  QuizQuestion('Przez które miasto przepływa Sekwana?', ['Londyn', 'Paryż', 'Rzym', 'Wiedeń'], 1, category: 'Geografia'),
  QuizQuestion('Góry na granicy Europy i Azji?', ['Alpy', 'Karpaty', 'Ural', 'Kaukaz'], 2, category: 'Geografia'),

  // --- Polska ---
  QuizQuestion('Najdłuższa rzeka w Polsce?', ['Odra', 'Warta', 'Wisła', 'Bug'], 2, category: 'Polska'),
  QuizQuestion('Które miasto było pierwszą stolicą Polski?', ['Kraków', 'Warszawa', 'Gniezno', 'Poznań'], 2, category: 'Polska'),
  QuizQuestion('Najwyższy szczyt Polski?', ['Śnieżka', 'Rysy', 'Babia Góra', 'Giewont'], 1, category: 'Polska'),
  QuizQuestion('Ile województw ma Polska?', ['14', '16', '18', '12'], 1, category: 'Polska'),
  QuizQuestion('Nad jakim morzem leży Polska?', ['Czarnym', 'Bałtyckim', 'Śródziemnym', 'Północnym'], 1, category: 'Polska'),
  QuizQuestion('Waluta obowiązująca w Polsce?', ['Euro', 'Korona', 'Złoty', 'Forint'], 2, category: 'Polska'),
  QuizQuestion('Ile liter ma polski alfabet?', ['26', '30', '32', '35'], 2, category: 'Polska'),
  QuizQuestion('Kto był pierwszym królem Polski?', ['Mieszko I', 'Bolesław Chrobry', 'Kazimierz Wielki', 'Władysław Łokietek'], 1, category: 'Polska'),
  QuizQuestion('W którym roku miał miejsce chrzest Polski?', ['966', '1000', '1025', '896'], 0, category: 'Polska'),
  QuizQuestion('Największe jezioro w Polsce?', ['Hańcza', 'Śniardwy', 'Mamry', 'Gopło'], 1, category: 'Polska'),
  QuizQuestion('Ilu sąsiadów ma Polska?', ['5', '6', '7', '9'], 2, category: 'Polska'),
  QuizQuestion('Najstarszy uniwersytet w Polsce?', ['Warszawski', 'Jagielloński', 'Wrocławski', 'Poznański'], 1, category: 'Polska'),
  QuizQuestion('Kto napisał słowa hymnu Polski?', ['Mickiewicz', 'Wybicki', 'Konopnicka', 'Słowacki'], 1, category: 'Polska'),
  QuizQuestion('Nad jaką rzeką leży Kraków?', ['Odra', 'Wisła', 'Warta', 'San'], 1, category: 'Polska'),

  // --- Historia ---
  QuizQuestion('W którym roku zatonął Titanic?', ['1905', '1912', '1920', '1898'], 1, category: 'Historia'),
  QuizQuestion('W którym roku wybuchła II wojna światowa?', ['1914', '1939', '1945', '1918'], 1, category: 'Historia'),
  QuizQuestion('Kto był pierwszym człowiekiem na Księżycu?', ['Gagarin', 'Armstrong', 'Aldrin', 'Glenn'], 1, category: 'Historia'),
  QuizQuestion('W którym roku Polska weszła do Unii Europejskiej?', ['2000', '2004', '2007', '1999'], 1, category: 'Historia'),
  QuizQuestion('Który mur runął w 1989 roku?', ['Chiński', 'Berliński', 'Adriana', 'Płaczu'], 1, category: 'Historia'),
  QuizQuestion('Kto namalował „Mona Lisę"?', ['Michał Anioł', 'Leonardo da Vinci', 'Rafael', 'Rembrandt'], 1, category: 'Historia'),
  QuizQuestion('Kto w 1492 r. dotarł do Ameryki?', ['Magellan', 'Kolumb', 'Vasco da Gama', 'Cook'], 1, category: 'Historia'),
  QuizQuestion('Kto był pierwszym człowiekiem w kosmosie?', ['Armstrong', 'Gagarin', 'Aldrin', 'Glenn'], 1, category: 'Historia'),
  QuizQuestion('Który lud zbudował piramidy w Gizie?', ['Rzymianie', 'Egipcjanie', 'Grecy', 'Majowie'], 1, category: 'Historia'),
  QuizQuestion('Kto był pierwszym prezydentem USA?', ['Lincoln', 'Waszyngton', 'Jefferson', 'Franklin'], 1, category: 'Historia'),
  QuizQuestion('W którym roku zakończyła się I wojna światowa?', ['1916', '1918', '1920', '1914'], 1, category: 'Historia'),
  QuizQuestion('Autor teorii względności?', ['Newton', 'Einstein', 'Bohr', 'Tesla'], 1, category: 'Historia'),

  // --- Nauka i przyroda ---
  QuizQuestion('Ile nóg ma pająk?', ['6', '8', '10', '12'], 1, category: 'Przyroda'),
  QuizQuestion('Symbol chemiczny tlenu?', ['Zł', 'O', 'Tl', 'Wo'], 1, category: 'Nauka'),
  QuizQuestion('Symbol chemiczny złota?', ['Zł', 'Go', 'Au', 'Ag'], 2, category: 'Nauka'),
  QuizQuestion('Symbol chemiczny żelaza?', ['Fl', 'Fe', 'Fs', 'Że'], 1, category: 'Nauka'),
  QuizQuestion('Wzór chemiczny wody?', ['CO2', 'H2O', 'O2', 'NaCl'], 1, category: 'Nauka'),
  QuizQuestion('Najbliższa Słońcu planeta?', ['Wenus', 'Mars', 'Merkury', 'Ziemia'], 2, category: 'Nauka'),
  QuizQuestion('Największa planeta Układu Słonecznego?', ['Saturn', 'Jowisz', 'Neptun', 'Ziemia'], 1, category: 'Nauka'),
  QuizQuestion('Najmniejsza planeta Układu Słonecznego?', ['Mars', 'Merkury', 'Wenus', 'Ziemia'], 1, category: 'Nauka'),
  QuizQuestion('Ile planet ma Układ Słoneczny?', ['7', '8', '9', '10'], 1, category: 'Nauka'),
  QuizQuestion('Którą planetę nazywamy Czerwoną Planetą?', ['Wenus', 'Mars', 'Jowisz', 'Merkury'], 1, category: 'Nauka'),
  QuizQuestion('Naturalny satelita Ziemi?', ['Słońce', 'Księżyc', 'Fobos', 'Tytan'], 1, category: 'Nauka'),
  QuizQuestion('Ile serc ma ośmiornica?', ['1', '2', '3', '5'], 2, category: 'Przyroda'),
  QuizQuestion('Jaki gaz rośliny pobierają do fotosyntezy?', ['Tlen', 'Azot', 'Dwutlenek węgla', 'Wodór'], 2, category: 'Nauka'),
  QuizQuestion('Największy ssak na Ziemi?', ['Słoń', 'Płetwal błękitny', 'Żyrafa', 'Kaszalot'], 1, category: 'Przyroda'),
  QuizQuestion('Ile kości ma dorosły człowiek?', ['186', '206', '226', '246'], 1, category: 'Nauka'),
  QuizQuestion('Ile chromosomów ma człowiek?', ['23', '44', '46', '48'], 2, category: 'Nauka'),
  QuizQuestion('Który organ pompuje krew?', ['Płuca', 'Serce', 'Wątroba', 'Nerki'], 1, category: 'Nauka'),
  QuizQuestion('Największy narząd ciała człowieka?', ['Wątroba', 'Skóra', 'Płuca', 'Serce'], 1, category: 'Nauka'),
  QuizQuestion('Najtwardszy naturalny minerał?', ['Kwarc', 'Diament', 'Grafit', 'Topaz'], 1, category: 'Nauka'),
  QuizQuestion('Ile nóg ma owad?', ['4', '6', '8', '10'], 1, category: 'Przyroda'),
  QuizQuestion('Temperatura wrzenia wody (na poziomie morza)?', ['90°C', '100°C', '120°C', '80°C'], 1, category: 'Nauka'),
  QuizQuestion('Temperatura zamarzania wody?', ['0°C', '-10°C', '4°C', '10°C'], 0, category: 'Nauka'),
  QuizQuestion('Prędkość światła to około?', ['300 tys. km/s', '30 tys. km/s', '3 mln km/s', '300 km/s'], 0, category: 'Nauka'),

  // --- Matematyka i logika ---
  QuizQuestion('Ile to 7 × 8?', ['54', '56', '64', '48'], 1, category: 'Matematyka'),
  QuizQuestion('Ile to 12 × 12?', ['124', '144', '154', '132'], 1, category: 'Matematyka'),
  QuizQuestion('Ile to 9 × 9?', ['72', '81', '91', '99'], 1, category: 'Matematyka'),
  QuizQuestion('Ile to 100 : 4?', ['20', '25', '30', '40'], 1, category: 'Matematyka'),
  QuizQuestion('Ile stopni ma kąt pełny?', ['180', '270', '360', '90'], 2, category: 'Matematyka'),
  QuizQuestion('Ile stopni ma kąt prosty?', ['45', '90', '180', '60'], 1, category: 'Matematyka'),
  QuizQuestion('Ile to 15% z 200?', ['20', '30', '15', '25'], 1, category: 'Matematyka'),
  QuizQuestion('Liczba Pi to w przybliżeniu?', ['2,14', '3,14', '4,13', '3,41'], 1, category: 'Matematyka'),
  QuizQuestion('Ile boków ma sześciokąt?', ['5', '6', '7', '8'], 1, category: 'Matematyka'),
  QuizQuestion('Ile to 2 do potęgi 5?', ['16', '32', '25', '64'], 1, category: 'Matematyka'),
  QuizQuestion('Która z liczb jest pierwsza?', ['9', '15', '17', '21'], 2, category: 'Matematyka'),
  QuizQuestion('Ile to 7 + 8 × 2?', ['30', '23', '25', '46'], 1, category: 'Matematyka'),
  QuizQuestion('Ile minut ma pół godziny?', ['15', '30', '45', '60'], 1, category: 'Matematyka'),

  // --- Kultura, film, muzyka ---
  QuizQuestion('Autor „Pana Tadeusza"?', ['Słowacki', 'Mickiewicz', 'Sienkiewicz', 'Norwid'], 1, category: 'Kultura'),
  QuizQuestion('Ile strun ma standardowa gitara?', ['4', '5', '6', '7'], 2, category: 'Muzyka'),
  QuizQuestion('W jakim mieście stoi wieża Eiffla?', ['Londyn', 'Rzym', 'Paryż', 'Berlin'], 2, category: 'Kultura'),
  QuizQuestion('Który zespół nagrał „Bohemian Rhapsody"?', ['The Beatles', 'Queen', 'ABBA', 'U2'], 1, category: 'Muzyka'),
  QuizQuestion('Ile aktów ma klasyczna tragedia?', ['3', '5', '7', '2'], 1, category: 'Kultura'),
  QuizQuestion('Reżyser filmu „Titanic" (1997)?', ['Spielberg', 'Cameron', 'Nolan', 'Scorsese'], 1, category: 'Film'),
  QuizQuestion('Autor komedii „Zemsta"?', ['Mickiewicz', 'Fredro', 'Sienkiewicz', 'Prus'], 1, category: 'Kultura'),
  QuizQuestion('Autor powieści „Quo Vadis"?', ['Prus', 'Sienkiewicz', 'Reymont', 'Żeromski'], 1, category: 'Kultura'),
  QuizQuestion('Za którą powieść Reymont dostał Nobla?', ['Lalka', 'Chłopi', 'Faraon', 'Potop'], 1, category: 'Kultura'),
  QuizQuestion('Ile klawiszy ma standardowe pianino?', ['76', '88', '96', '61'], 1, category: 'Muzyka'),
  QuizQuestion('Kto namalował „Słoneczniki"?', ['Picasso', 'Van Gogh', 'Monet', 'Dali'], 1, category: 'Kultura'),
  QuizQuestion('Z jakiego kraju pochodzi zespół ABBA?', ['Norwegia', 'Szwecja', 'Dania', 'Finlandia'], 1, category: 'Muzyka'),

  // --- Sport ---
  QuizQuestion('Ilu zawodników jednej drużyny jest na boisku w piłce nożnej?', ['9', '10', '11', '12'], 2, category: 'Sport'),
  QuizQuestion('Co ile lat odbywają się letnie igrzyska olimpijskie?', ['2', '3', '4', '5'], 2, category: 'Sport'),
  QuizQuestion('W jakim sporcie zdobywa się „strike"?', ['Tenis', 'Bowling', 'Golf', 'Hokej'], 1, category: 'Sport'),
  QuizQuestion('Ile punktów jest za rzut za trzy w koszykówce?', ['1', '2', '3', '4'], 2, category: 'Sport'),
  QuizQuestion('Z jakiego kraju pochodzi sport sumo?', ['Chiny', 'Korea', 'Japonia', 'Tajlandia'], 2, category: 'Sport'),
  QuizQuestion('Ile minut trwa mecz piłki nożnej (bez doliczonego)?', ['60', '80', '90', '120'], 2, category: 'Sport'),
  QuizQuestion('Ilu zawodników jednej drużyny gra w siatkówce?', ['5', '6', '7', '11'], 1, category: 'Sport'),
  QuizQuestion('W którym kraju wynaleziono judo?', ['Chiny', 'Japonia', 'Korea', 'Tajlandia'], 1, category: 'Sport'),
  QuizQuestion('Co ile lat odbywają się mistrzostwa świata w piłce nożnej?', ['2', '3', '4', '5'], 2, category: 'Sport'),
  QuizQuestion('Ile pierścieni jest na fladze olimpijskiej?', ['4', '5', '6', '7'], 1, category: 'Sport'),

  // --- Jedzenie i codzienność ---
  QuizQuestion('Z czego robi się tradycyjny hummus?', ['Fasola', 'Ciecierzyca', 'Soczewica', 'Groch'], 1, category: 'Jedzenie'),
  QuizQuestion('Które to owoc cytrusowy?', ['Truskawka', 'Grejpfrut', 'Malina', 'Jagoda'], 1, category: 'Jedzenie'),
  QuizQuestion('Z jakiego kraju pochodzi pizza?', ['Grecja', 'Włochy', 'Hiszpania', 'Francja'], 1, category: 'Jedzenie'),
  QuizQuestion('Główny składnik guacamole?', ['Awokado', 'Ogórek', 'Cukinia', 'Papryka'], 0, category: 'Jedzenie'),
  QuizQuestion('Z czego produkuje się wino?', ['Jabłka', 'Winogrona', 'Śliwki', 'Wiśnie'], 1, category: 'Jedzenie'),
  QuizQuestion('Główny składnik pieczywa?', ['Mąka', 'Cukier', 'Ryż', 'Kasza'], 0, category: 'Jedzenie'),
  QuizQuestion('Z jakiego kraju pochodzi sushi?', ['Chiny', 'Japonia', 'Korea', 'Wietnam'], 1, category: 'Jedzenie'),
  QuizQuestion('Z czego robi się ser?', ['Mleko', 'Jajka', 'Soja', 'Woda'], 0, category: 'Jedzenie'),

  // --- Ogólne / świat ---
  QuizQuestion('Ile kolorów ma tęcza?', ['5', '6', '7', '8'], 2, category: 'Ogólne'),
  QuizQuestion('Ile minut ma pełna godzina?', ['30', '45', '60', '100'], 2, category: 'Ogólne'),
  QuizQuestion('Ile dni ma rok przestępny?', ['364', '365', '366', '367'], 2, category: 'Ogólne'),
  QuizQuestion('Ile sekund ma minuta?', ['30', '60', '90', '100'], 1, category: 'Ogólne'),
  QuizQuestion('W którym kierunku wschodzi Słońce?', ['Zachód', 'Wschód', 'Północ', 'Południe'], 1, category: 'Ogólne'),
  QuizQuestion('Ile dni ma tydzień?', ['5', '6', '7', '8'], 2, category: 'Ogólne'),
  QuizQuestion('Ile miesięcy ma rok?', ['10', '11', '12', '13'], 2, category: 'Ogólne'),
  QuizQuestion('Ile godzin ma doba?', ['12', '24', '36', '48'], 1, category: 'Ogólne'),
  QuizQuestion('Jaki kolor powstaje z żółtego i niebieskiego?', ['Zielony', 'Pomarańczowy', 'Fioletowy', 'Brązowy'], 0, category: 'Ogólne'),
  QuizQuestion('Która pora roku następuje po zimie?', ['Lato', 'Wiosna', 'Jesień', 'Zima'], 1, category: 'Ogólne'),
];

/// Wszystkie pytania razem: tekstowe + obrazkowe, losowane z jednej puli.
List<QuizQuestion> get allQuizQuestions => [...kQuizQuestions, ...kQuizImageQuestions];

final Random _quizRng = Random();

/// Zwraca w PEŁNI losowe pytanie z całej puli (tekstowe lub obrazkowe).
/// Każde losowanie jest niezależne — bez sztywnej kolejności i bez pilnowania
/// „bez powtórek". Przy dużej bazie powtórki i tak zdarzają się rzadko.
QuizQuestion drawQuizQuestion() {
  final pool = allQuizQuestions;
  return pool[_quizRng.nextInt(pool.length)];
}
