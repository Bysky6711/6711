import 'dart:math';

import 'familiada_questions.dart';
import 'kalambury_prompts.dart';
import 'zgodnosc_prompts.dart';

// Treść gier grupowych mieszka teraz w trzech osobnych, edytowalnych plikach —
// dopisuj pytania/hasła TAM:
//   • familiada_questions.dart  — ankiety Familiady        (kFamiliadaSurveys)
//   • kalambury_prompts.dart    — hasła do Kalambur         (kCharadesPrompts)
//   • zgodnosc_prompts.dart     — pytania „Znasz znajomych" (kFriendsPrompts)
//
// Re-eksport sprawia, że reszta aplikacji dalej importuje tylko ten plik.
export 'familiada_questions.dart';
export 'kalambury_prompts.dart';
export 'zgodnosc_prompts.dart';

// =============================== draw helpers ================================

// Pełna losowość — każde losowanie jest niezależne (jak w quizie), bez
// pilnowania „bez powtórek". Przy dużych pulach powtórki są rzadkie.
final Random _ggRng = Random();

FamiliadaSurvey drawFamiliadaSurvey() => kFamiliadaSurveys[_ggRng.nextInt(kFamiliadaSurveys.length)];
CharadesPrompt drawCharadesPrompt() => kCharadesPrompts[_ggRng.nextInt(kCharadesPrompts.length)];
String drawFriendsPrompt() => kFriendsPrompts[_ggRng.nextInt(kFriendsPrompts.length)];

// Index-returning draws (used when the choice must be synced across devices).
int drawFamiliadaIndex() => _ggRng.nextInt(kFamiliadaSurveys.length);
int drawCharadesIndex() => _ggRng.nextInt(kCharadesPrompts.length);
int drawFriendsIndex() => _ggRng.nextInt(kFriendsPrompts.length);
