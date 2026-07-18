import 'dart:math';

class QuizQuestion {
  const QuizQuestion(this.question, this.options, this.correctIndex, {this.category = 'Ogólne'});
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;
}

/// Pool the host draws from when starting a Quiz round. Draws are non-repeating
/// within a session via [drawQuizQuestion]; the pool resets once exhausted.
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

  // --- Polska ---
  QuizQuestion('Najdłuższa rzeka w Polsce?', ['Odra', 'Warta', 'Wisła', 'Bug'], 2, category: 'Polska'),
  QuizQuestion('Które miasto było pierwszą stolicą Polski?', ['Kraków', 'Warszawa', 'Gniezno', 'Poznań'], 2, category: 'Polska'),
  QuizQuestion('Najwyższy szczyt Polski?', ['Śnieżka', 'Rysy', 'Babia Góra', 'Giewont'], 1, category: 'Polska'),
  QuizQuestion('Ile województw ma Polska?', ['14', '16', '18', '12'], 1, category: 'Polska'),
  QuizQuestion('Nad jakim morzem leży Polska?', ['Czarnym', 'Bałtyckim', 'Śródziemnym', 'Północnym'], 1, category: 'Polska'),
  QuizQuestion('Waluta obowiązująca w Polsce?', ['Euro', 'Korona', 'Złoty', 'Forint'], 2, category: 'Polska'),

  // --- Historia ---
  QuizQuestion('W którym roku zatonął Titanic?', ['1905', '1912', '1920', '1898'], 1, category: 'Historia'),
  QuizQuestion('W którym roku wybuchła II wojna światowa?', ['1914', '1939', '1945', '1918'], 1, category: 'Historia'),
  QuizQuestion('Kto był pierwszym człowiekiem na Księżycu?', ['Gagarin', 'Armstrong', 'Aldrin', 'Glenn'], 1, category: 'Historia'),
  QuizQuestion('W którym roku Polska weszła do Unii Europejskiej?', ['2000', '2004', '2007', '1999'], 1, category: 'Historia'),
  QuizQuestion('Który mur runął w 1989 roku?', ['Chiński', 'Berliński', 'Adriana', 'Płaczu'], 1, category: 'Historia'),
  QuizQuestion('Kto namalował „Mona Lisę"?', ['Michał Anioł', 'Leonardo da Vinci', 'Rafael', 'Rembrandt'], 1, category: 'Historia'),

  // --- Nauka i przyroda ---
  QuizQuestion('Ile nóg ma pająk?', ['6', '8', '10', '12'], 1, category: 'Przyroda'),
  QuizQuestion('Symbol chemiczny tlenu?', ['Zł', 'O', 'Tl', 'Wo'], 1, category: 'Nauka'),
  QuizQuestion('Symbol chemiczny złota?', ['Zł', 'Go', 'Au', 'Ag'], 2, category: 'Nauka'),
  QuizQuestion('Najbliższa Słońcu planeta?', ['Wenus', 'Mars', 'Merkury', 'Ziemia'], 2, category: 'Nauka'),
  QuizQuestion('Największa planeta Układu Słonecznego?', ['Saturn', 'Jowisz', 'Neptun', 'Ziemia'], 1, category: 'Nauka'),
  QuizQuestion('Ile serc ma ośmiornica?', ['1', '2', '3', '5'], 2, category: 'Przyroda'),
  QuizQuestion('Jaki gaz rośliny pobierają do fotosyntezy?', ['Tlen', 'Azot', 'Dwutlenek węgla', 'Wodór'], 2, category: 'Nauka'),
  QuizQuestion('Największy ssak na Ziemi?', ['Słoń', 'Płetwal błękitny', 'Żyrafa', 'Kaszalot'], 1, category: 'Przyroda'),
  QuizQuestion('Ile kości ma dorosły człowiek?', ['186', '206', '226', '246'], 1, category: 'Nauka'),
  QuizQuestion('Prędkość światła to około?', ['300 tys. km/s', '30 tys. km/s', '3 mln km/s', '300 km/s'], 0, category: 'Nauka'),

  // --- Matematyka i logika ---
  QuizQuestion('Ile to 7 × 8?', ['54', '56', '64', '48'], 1, category: 'Matematyka'),
  QuizQuestion('Ile to 12 × 12?', ['124', '144', '154', '132'], 1, category: 'Matematyka'),
  QuizQuestion('Ile stopni ma kąt pełny?', ['180', '270', '360', '90'], 2, category: 'Matematyka'),
  QuizQuestion('Ile to 15% ze 200?', ['20', '30', '15', '25'], 1, category: 'Matematyka'),
  QuizQuestion('Liczba Pi to w przybliżeniu?', ['2,14', '3,14', '4,13', '3,41'], 1, category: 'Matematyka'),

  // --- Kultura, film, muzyka ---
  QuizQuestion('Autor „Pana Tadeusza"?', ['Słowacki', 'Mickiewicz', 'Sienkiewicz', 'Norwid'], 1, category: 'Kultura'),
  QuizQuestion('Ile strun ma standardowa gitara?', ['4', '5', '6', '7'], 2, category: 'Muzyka'),
  QuizQuestion('W jakim mieście stoi wieża Eiffla?', ['Londyn', 'Rzym', 'Paryż', 'Berlin'], 2, category: 'Kultura'),
  QuizQuestion('Który zespół nagrał „Bohemian Rhapsody"?', ['The Beatles', 'Queen', 'ABBA', 'U2'], 1, category: 'Muzyka'),
  QuizQuestion('Ile aktów ma klasyczna tragedia?', ['3', '5', '7', '2'], 1, category: 'Kultura'),
  QuizQuestion('Reżyser filmu „Titanic" (1997)?', ['Spielberg', 'Cameron', 'Nolan', 'Scorsese'], 1, category: 'Film'),

  // --- Sport ---
  QuizQuestion('Ilu zawodników jednej drużyny jest na boisku w piłce nożnej?', ['9', '10', '11', '12'], 2, category: 'Sport'),
  QuizQuestion('Co ile lat odbywają się letnie igrzyska olimpijskie?', ['2', '3', '4', '5'], 2, category: 'Sport'),
  QuizQuestion('W jakim sporcie zdobywa się „strike"?', ['Tenis', 'Bowling', 'Golf', 'Hokej'], 1, category: 'Sport'),
  QuizQuestion('Ile punktów jest za rzut za trzy w koszykówce?', ['1', '2', '3', '4'], 2, category: 'Sport'),
  QuizQuestion('Z jakiego kraju pochodzi sport sumo?', ['Chiny', 'Korea', 'Japonia', 'Tajlandia'], 2, category: 'Sport'),

  // --- Jedzenie i codzienność ---
  QuizQuestion('Z czego robi się tradycyjny hummus?', ['Fasola', 'Ciecierzyca', 'Soczewica', 'Groch'], 1, category: 'Jedzenie'),
  QuizQuestion('Które to owoc cytrusowy?', ['Truskawka', 'Grejpfrut', 'Malina', 'Jagoda'], 1, category: 'Jedzenie'),
  QuizQuestion('Z jakiego kraju pochodzi pizza?', ['Grecja', 'Włochy', 'Hiszpania', 'Francja'], 1, category: 'Jedzenie'),
  QuizQuestion('Główny składnik guacamole?', ['Awokado', 'Ogórek', 'Cukinia', 'Papryka'], 0, category: 'Jedzenie'),

  // --- Ogólne / świat ---
  QuizQuestion('Ile kolorów ma tęcza?', ['5', '6', '7', '8'], 2, category: 'Ogólne'),
  QuizQuestion('Ile minut ma pełna godzina?', ['30', '45', '60', '100'], 2, category: 'Ogólne'),
  QuizQuestion('Stolica Japonii?', ['Pekin', 'Seul', 'Tokio', 'Bangkok'], 2, category: 'Geografia'),
  QuizQuestion('Ile dni ma rok przestępny?', ['364', '365', '366', '367'], 2, category: 'Ogólne'),
  QuizQuestion('Ile sekund ma minuta?', ['30', '60', '90', '100'], 1, category: 'Ogólne'),
  QuizQuestion('W którym kierunku wschodzi Słońce?', ['Zachód', 'Wschód', 'Północ', 'Południe'], 1, category: 'Ogólne'),
  QuizQuestion('Ile liter ma polski alfabet?', ['26', '30', '32', '35'], 2, category: 'Polska'),
];

final Random _quizRng = Random();
final Set<int> _usedQuiz = <int>{};

/// Returns a random quiz question not used yet this session. Resets the pool
/// once every question has been drawn, so rounds stay fresh and non-repeating.
QuizQuestion drawQuizQuestion() {
  if (_usedQuiz.length >= kQuizQuestions.length) _usedQuiz.clear();
  final available = [
    for (var i = 0; i < kQuizQuestions.length; i++)
      if (!_usedQuiz.contains(i)) i,
  ];
  final pick = available[_quizRng.nextInt(available.length)];
  _usedQuiz.add(pick);
  return kQuizQuestions[pick];
}
