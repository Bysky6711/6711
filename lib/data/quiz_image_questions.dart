import 'quiz_questions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  PYTANIA OBRAZKOWE DO QUIZU  (edytuj śmiało — dopisuj własne!)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Każde pytanie to zwykły [QuizQuestion] z dodatkowym `imageUrl` — adresem
/// obrazka w internecie (https). Obrazek pokaże się nad pytaniem, a gracze
/// wybierają jedną z 4 odpowiedzi (jak w zwykłym quizie).
///
/// JAK DOPISAĆ WŁASNE PYTANIE:
///   QuizQuestion(
///     'Treść pytania?',               // co widać nad obrazkiem
///     ['Odp A', 'Odp B', 'Odp C', 'Odp D'],
///     1,                               // indeks poprawnej odpowiedzi (0-3)
///     category: 'Flagi',               // dowolna kategoria
///     imageUrl: 'https://.../obrazek.png',
///   ),
///
/// WSKAZÓWKI:
///  • Działa każdy publiczny link do obrazka (PNG/JPG). Wklej adres z internetu.
///  • Flagi państw: https://flagcdn.com/w320/KOD.png  (KOD = kod kraju ISO małymi
///    literami: pl, de, fr, it, jp, es, gb, us, ca, se, gr, br, …). Podmień na inny kraj.
///  • Możesz też dodawać zdjęcia zabytków, herbów, zwierząt, kadrów z filmów itp.
///  • Jeśli link będzie zły albo obrazek się nie wczyta, gra pokaże ikonę zastępczą
///    i sam tekst pytania — nic się nie wysypie.
const List<QuizQuestion> kQuizImageQuestions = [
  // --- Flagi państw (przykłady na start — dopisuj kolejne) ---
  QuizQuestion('Której to kraju flaga?', ['Polska', 'Indonezja', 'Monako', 'Czechy'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/pl.png'),
  QuizQuestion('Której to kraju flaga?', ['Belgia', 'Niemcy', 'Austria', 'Hiszpania'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/de.png'),
  QuizQuestion('Której to kraju flaga?', ['Holandia', 'Francja', 'Rosja', 'Czechy'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/fr.png'),
  QuizQuestion('Której to kraju flaga?', ['Irlandia', 'Włochy', 'Węgry', 'Meksyk'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/it.png'),
  QuizQuestion('Której to kraju flaga?', ['Bangladesz', 'Japonia', 'Korea Płd.', 'Palau'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/jp.png'),
  QuizQuestion('Której to kraju flaga?', ['Portugalia', 'Hiszpania', 'Kolumbia', 'Wenezuela'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/es.png'),
  QuizQuestion('Której to kraju flaga?', ['Australia', 'Wielka Brytania', 'Nowa Zelandia', 'USA'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/gb.png'),
  QuizQuestion('Której to kraju flaga?', ['Liberia', 'USA', 'Malezja', 'Chile'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/us.png'),
  QuizQuestion('Której to kraju flaga?', ['Peru', 'Kanada', 'Dania', 'Austria'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/ca.png'),
  QuizQuestion('Której to kraju flaga?', ['Szwecja', 'Norwegia', 'Finlandia', 'Dania'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/se.png'),
  QuizQuestion('Której to kraju flaga?', ['Urugwaj', 'Grecja', 'Izrael', 'Finlandia'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/gr.png'),
  QuizQuestion('Której to kraju flaga?', ['Kolumbia', 'Brazylia', 'Argentyna', 'Portugalia'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/br.png'),
  QuizQuestion('Której to kraju flaga?', ['Norwegia', 'Islandia', 'Dania', 'Finlandia'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/no.png'),
  QuizQuestion('Której to kraju flaga?', ['Dania', 'Norwegia', 'Szwajcaria', 'Anglia'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/dk.png'),
  QuizQuestion('Której to kraju flaga?', ['Holandia', 'Rosja', 'Francja', 'Luksemburg'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/nl.png'),
  QuizQuestion('Której to kraju flaga?', ['Czechy', 'Filipiny', 'Polska', 'Rosja'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/cz.png'),
  QuizQuestion('Której to kraju flaga?', ['Hiszpania', 'Portugalia', 'Włochy', 'Meksyk'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/pt.png'),
  QuizQuestion('Której to kraju flaga?', ['Włochy', 'Irlandia', 'Meksyk', 'Węgry'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/ie.png'),
  QuizQuestion('Której to kraju flaga?', ['Ukraina', 'Szwecja', 'Argentyna', 'Kazachstan'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/ua.png'),
  QuizQuestion('Której to kraju flaga?', ['Wietnam', 'Chiny', 'Korea Płn.', 'Turcja'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/cn.png'),
  QuizQuestion('Której to kraju flaga?', ['Japonia', 'Korea Południowa', 'Mongolia', 'Tajwan'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/kr.png'),
  QuizQuestion('Której to kraju flaga?', ['Włochy', 'Meksyk', 'Irlandia', 'Węgry'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/mx.png'),
  QuizQuestion('Której to kraju flaga?', ['Dania', 'Szwajcaria', 'Anglia', 'Tonga'], 1,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/ch.png'),
  QuizQuestion('Której to kraju flaga?', ['Austria', 'Łotwa', 'Liban', 'Polska'], 0,
      category: 'Flagi', imageUrl: 'https://flagcdn.com/w320/at.png'),

  // --- Tutaj dopisuj własne pytania obrazkowe ---
  //
  // Nie tylko flagi! Zadziała każdy publiczny obrazek. Wygodne, przewidywalne
  // źródło dla zabytków / herbów / obrazów to Wikimedia:
  //   https://commons.wikimedia.org/wiki/Special:FilePath/NAZWA_PLIKU.jpg
  // (podmień NAZWA_PLIKU na dokładną nazwę pliku z Wikimedia Commons). Przykład:
  //   QuizQuestion('Co to za budowla?', ['Koloseum', 'Panteon', 'Akropol', 'Forum'], 0,
  //       category: 'Zabytki',
  //       imageUrl: 'https://commons.wikimedia.org/wiki/Special:FilePath/Colosseo_2020.jpg'),
];
