import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../data/group_games.dart';
import '../models/game_room.dart';
import '../services/online_room_service.dart';
import '../ui_system/mafia_ios_system.dart';

const _kGold = Color(0xFFFFD166);
const _kRed = Color(0xFFE5404F);
const _kBlue = Color(0xFF60A5FA);
const _kPink = Color(0xFFF472B6);
const _kGreen = Color(0xFF34D399);

/// Host-driven, synced party mini-games (Familiada / Kalambury / Znajomi).
/// The host controls everything; players see the same board read-only. State
/// lives in rooms/{code}/state/groupgame. Teams are assigned by the host.
class GroupGamesApp extends StatelessWidget {
  const GroupGamesApp({
    super.key,
    required this.service,
    required this.roomCode,
    required this.isHost,
    required this.room,
    required this.myPlayerId,
  });

  final OnlineRoomService service;
  final String roomCode;
  final bool isHost;
  final GameRoom room;
  final String myPlayerId;

  Map<String, dynamic> get _defaults => {
        'game': 'familiada',
        'survey': 0,
        'revealed': <int>[],
        'claims': <String, dynamic>{},
        'prompt': 0,
        'promptShown': false,
        'znajomi': 0,
        'agreed': 0,
        'total': room.players.isEmpty ? 4 : room.players.length,
        'scoreA': 0,
        'scoreB': 0,
        'groups': <String, dynamic>{},
      };

  void _patch(Map<String, dynamic> p) => service.updateGroupGame(roomCode, p);

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.watchGroupGame(roomCode),
      builder: (context, snap) {
        final raw = snap.data;
        if (raw == null && !isHost) {
          return ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
            children: [
              _header(),
              const SizedBox(height: 24),
              const _EmptyHintGG('Gospodarz jeszcze nie rozpoczął gry grupowej. Poczekaj chwilę.'),
            ],
          );
        }
        final s = {..._defaults, ...?raw};
        final game = (s['game'] as String?) ?? 'familiada';
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
          physics: const BouncingScrollPhysics(),
          children: [
            _header(),
            const SizedBox(height: 14),
            if (isHost) _modeSelector(game),
            if (isHost) const SizedBox(height: 16),
            if (game == 'familiada') ..._familiada(s),
            if (game == 'kalambury') ..._kalambury(s),
            if (game == 'znajomi') ..._znajomi(s),
            const SizedBox(height: 18),
            _groupsPanel(s),
            if (isHost) ...[
              const SizedBox(height: 14),
              _ggButton('Wyzeruj planszę i punkty', Icons.restart_alt_rounded, () => service.resetGroupGame(roomCode, _defaults), color: _kRed),
            ],
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------- shared chrome

  Widget _header() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.groups_2_rounded, color: _kGold, size: 24),
          SizedBox(width: 8),
          Text('Gry grupowe', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 6),
        Text(isHost ? 'Prowadzisz grę — gracze widzą tę samą planszę.' : 'Planszę prowadzi gospodarz. Ty tylko obserwujesz.',
            style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
      ]);

  Widget _modeSelector(String game) {
    Widget chip(String m, String label, IconData icon) {
      final active = game == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => _patch({'game': m}),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? _kGold.withValues(alpha: .2) : Colors.white.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: active ? _kGold : Colors.white.withValues(alpha: .12), width: active ? 1.6 : 1),
            ),
            child: Column(children: [
              Icon(icon, color: active ? _kGold : AppColors.white.withValues(alpha: .7), size: 22),
              const SizedBox(height: 6),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? AppColors.white : AppColors.white.withValues(alpha: .7), fontSize: 11.5, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      );
    }

    return Row(children: [
      chip('familiada', 'Familiada', Icons.leaderboard_rounded),
      chip('kalambury', 'Kalambury', Icons.gesture_rounded),
      chip('znajomi', 'Znajomi', Icons.diversity_3_rounded),
    ]);
  }

  Widget _rewardNote(String text) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _kGold.withValues(alpha: .12), borderRadius: BorderRadius.circular(14), border: Border.all(color: _kGold.withValues(alpha: .4))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.card_giftcard_rounded, color: _kGold, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: _kGold, fontSize: 12, fontWeight: FontWeight.w700, height: 1.35))),
        ]),
      );

  Widget _ggButton(String text, IconData icon, VoidCallback onTap, {Color color = _kGold}) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(text),
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: color == _kGold ? const Color(0xFF20120E) : Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      );

  /// Read-only score/value display; host gets +/- buttons.
  Widget _score(String label, int value, Color color, {VoidCallback? onMinus, VoidCallback? onPlus}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .35))),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w800))),
        if (isHost && onMinus != null) _rb(Icons.remove_rounded, onMinus),
        SizedBox(width: 42, child: Text('$value', textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900))),
        if (isHost && onPlus != null) _rb(Icons.add_rounded, onPlus),
      ]),
    );
  }

  Widget _rb(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .18))), child: Icon(icon, color: AppColors.white, size: 18)),
      );

  // ----------------------------------------------------------------- Familiada

  List<Widget> _familiada(Map<String, dynamic> s) {
    final idx = ((s['survey'] as num?)?.toInt() ?? 0).clamp(0, kFamiliadaSurveys.length - 1);
    final survey = kFamiliadaSurveys[idx];
    final revealed = ((s['revealed'] as List?) ?? const []).map((e) => (e as num).toInt()).toSet();
    final claims = <String, String>{
      for (final e in ((s['claims'] as Map?) ?? const {}).entries)
        if (e.value != null) e.key.toString(): e.value.toString(),
    };
    final scoreA = (s['scoreA'] as num?)?.toInt() ?? 0;
    final scoreB = (s['scoreB'] as num?)?.toInt() ?? 0;
    return [
      _rewardNote('Drużyny (min. 4 os.) zgadują najczęstsze odpowiedzi. Zwycięska drużyna: 3 karty. Jeśli przegra drużyna z mafią — mafia bierze 2 karty.'),
      IOSGlass(
        opacity: .1,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PYTANIE ANKIETOWE', style: TextStyle(color: _kGold, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(survey.question, style: const TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w900, height: 1.25)),
          if (isHost) ...[
            const SizedBox(height: 6),
            Text('Widzisz odpowiedzi. 👁 odkrywa graczom, a A/B przyznaje punkty drużynie.', style: TextStyle(color: AppColors.white.withValues(alpha: .55), fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.3)),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < survey.answers.length; i++) _familiadaTile(survey, revealed, claims, i, scoreA, scoreB),
      const SizedBox(height: 16),
      _score('Drużyna A', scoreA, _kBlue, onMinus: () => _patch({'scoreA': (scoreA - 1).clamp(0, 999)}), onPlus: () => _patch({'scoreA': scoreA + 1})),
      const SizedBox(height: 8),
      _score('Drużyna B', scoreB, _kPink, onMinus: () => _patch({'scoreB': (scoreB - 1).clamp(0, 999)}), onPlus: () => _patch({'scoreB': scoreB + 1})),
      if (isHost) ...[
        const SizedBox(height: 16),
        _ggButton('Następne pytanie', Icons.skip_next_rounded, () => _patch({'survey': drawFamiliadaIndex(), 'revealed': <int>[], 'claims': <String, dynamic>{}})),
      ],
    ];
  }

  Widget _familiadaTile(FamiliadaSurvey survey, Set<int> revealed, Map<String, String> claims, int i, int scoreA, int scoreB) {
    final a = survey.answers[i];
    final shown = revealed.contains(i); // visible to players
    final claim = claims[i.toString()]; // 'A' | 'B' | null
    final hostSees = isHost || shown; // the host always sees the answer text
    final claimColor = claim == 'A' ? _kBlue : (claim == 'B' ? _kPink : null);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: shown ? _kGold.withValues(alpha: .14) : const Color(0xFF201014),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: claimColor?.withValues(alpha: .7) ?? (shown ? _kGold.withValues(alpha: .5) : Colors.white.withValues(alpha: .1))),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), shape: BoxShape.circle), child: Text('${i + 1}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 13))),
          const SizedBox(width: 12),
          Expanded(child: Text(hostSees ? a.text : '• • • • •', style: TextStyle(color: hostSees ? AppColors.white : AppColors.white.withValues(alpha: .35), fontSize: 15, fontWeight: FontWeight.w800))),
          if (claim != null)
            Container(margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: claimColor!.withValues(alpha: .25), borderRadius: BorderRadius.circular(8), border: Border.all(color: claimColor)), child: Text(claim, style: TextStyle(color: claimColor, fontWeight: FontWeight.w900, fontSize: 12))),
          if (hostSees)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(10)), child: Text('${a.points}', style: const TextStyle(color: Color(0xFF20120E), fontWeight: FontWeight.w900, fontSize: 14)))
          else
            Icon(Icons.lock_rounded, color: AppColors.white.withValues(alpha: .25), size: 16),
        ]),
        if (isHost) ...[
          const SizedBox(height: 8),
          Row(children: [
            _tileBtn(shown ? Icons.visibility_rounded : Icons.visibility_off_rounded, shown ? 'Widoczne' : 'Odkryj', shown ? _kGold : Colors.white54, () {
              final n = {...revealed};
              shown ? n.remove(i) : n.add(i);
              _patch({'revealed': n.toList()});
            }),
            const Spacer(),
            _claimBtn('A', _kBlue, claim, () => _claim(i, 'A', a, claims, scoreA, scoreB, revealed)),
            const SizedBox(width: 6),
            _claimBtn('B', _kPink, claim, () => _claim(i, 'B', a, claims, scoreA, scoreB, revealed)),
          ]),
        ],
      ]),
    );
  }

  Widget _tileBtn(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(9), border: Border.all(color: color.withValues(alpha: .4))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 15), const SizedBox(width: 5), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11))]),
        ),
      );

  Widget _claimBtn(String team, Color color, String? current, VoidCallback onTap) {
    final sel = current == team;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: sel ? color.withValues(alpha: .3) : Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(9), border: Border.all(color: sel ? color : Colors.white.withValues(alpha: .16))),
        child: Text(team, style: TextStyle(color: sel ? color : AppColors.white.withValues(alpha: .75), fontWeight: FontWeight.w900)),
      ),
    );
  }

  /// Toggle-award a Familiada answer's points to a team (tapping again / the
  /// other team moves or removes the award). Auto-reveals the tile to players.
  void _claim(int i, String team, FamiliadaAnswer a, Map<String, String> claims, int scoreA, int scoreB, Set<int> revealed) {
    final key = i.toString();
    final current = claims[key];
    var na = scoreA;
    var nb = scoreB;
    if (current == 'A') na -= a.points;
    if (current == 'B') nb -= a.points;
    final off = current == team;
    if (!off) {
      if (team == 'A') na += a.points;
      if (team == 'B') nb += a.points;
    }
    final n = {...revealed}..add(i);
    _patch({
      'claims': {key: off ? null : team},
      'scoreA': na.clamp(0, 9999),
      'scoreB': nb.clamp(0, 9999),
      'revealed': n.toList(),
    });
  }

  // ----------------------------------------------------------------- Kalambury

  List<Widget> _kalambury(Map<String, dynamic> s) {
    final idx = ((s['prompt'] as num?)?.toInt() ?? 0).clamp(0, kCharadesPrompts.length - 1);
    final prompt = kCharadesPrompts[idx];
    final shown = s['promptShown'] as bool? ?? false;
    final scoreA = (s['scoreA'] as num?)?.toInt() ?? 0;
    final scoreB = (s['scoreB'] as num?)?.toInt() ?? 0;
    // The word is visible to the host always (to whisper to the actor); players
    // only see it once the host reveals it (after it's guessed).
    final wordVisible = isHost || shown;
    return [
      _rewardNote('Jedna osoba pokazuje hasło, jej drużyna zgaduje. Najszybsza drużyna zdobywa punkt i kartę.'),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A1010), Color(0xFF15080A)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _kGold.withValues(alpha: .5), width: 1.6),
        ),
        child: Column(children: [
          Text(prompt.category.toUpperCase(), style: const TextStyle(color: _kGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(
            wordVisible ? prompt.text : 'Hasło zna gospodarz',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.white, fontSize: wordVisible ? 30 : 16, fontWeight: FontWeight.w900, height: 1.2),
          ),
          if (isHost) ...[
            const SizedBox(height: 8),
            Text('pokaż telefon osobie pokazującej', style: TextStyle(color: AppColors.white.withValues(alpha: .5), fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
      if (isHost) ...[
        const SizedBox(height: 12),
        _ggButton('Nowe hasło', Icons.casino_rounded, () => _patch({'prompt': drawCharadesIndex(), 'promptShown': false})),
        const SizedBox(height: 8),
        _ggButton(shown ? 'Ukryj hasło graczom' : 'Pokaż hasło wszystkim', shown ? Icons.visibility_off_rounded : Icons.visibility_rounded, () => _patch({'promptShown': !shown}), color: Colors.white24),
      ],
      const SizedBox(height: 16),
      _score('Drużyna A', scoreA, _kBlue, onMinus: () => _patch({'scoreA': (scoreA - 1).clamp(0, 999)}), onPlus: () => _patch({'scoreA': scoreA + 1})),
      const SizedBox(height: 8),
      _score('Drużyna B', scoreB, _kPink, onMinus: () => _patch({'scoreB': (scoreB - 1).clamp(0, 999)}), onPlus: () => _patch({'scoreB': scoreB + 1})),
    ];
  }

  // ------------------------------------------------------------------- Znajomi

  List<Widget> _znajomi(Map<String, dynamic> s) {
    final idx = ((s['znajomi'] as num?)?.toInt() ?? 0).clamp(0, kFriendsPrompts.length - 1);
    final q = kFriendsPrompts[idx];
    final agreed = (s['agreed'] as num?)?.toInt() ?? 0;
    final total = (s['total'] as num?)?.toInt() ?? 0;
    final scoreA = (s['scoreA'] as num?)?.toInt() ?? 0;
    final pct = total == 0 ? 0 : (agreed * 100 / total).round();
    final scored = pct >= 75;
    return [
      _rewardNote('Wszyscy naraz wskazują jedną osobę. Grupa zdobywa punkt tylko przy min. 75% zgodności.'),
      IOSGlass(
        opacity: .1,
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('KTO Z WAS…', style: TextStyle(color: _kGold, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(q, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.25)),
        ]),
      ),
      const SizedBox(height: 16),
      _score('Zgodnych osób', agreed, _kGreen, onMinus: () => _patch({'agreed': (agreed - 1).clamp(0, total)}), onPlus: () => _patch({'agreed': (agreed + 1).clamp(0, total)})),
      const SizedBox(height: 8),
      _score('Wszystkich w grupie', total, Colors.white, onMinus: () => _patch({'total': (total - 1).clamp(1, 999), if (agreed > total - 1) 'agreed': (total - 1).clamp(0, 999)}), onPlus: () => _patch({'total': total + 1})),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: (scored ? _kGreen : _kRed).withValues(alpha: .16), borderRadius: BorderRadius.circular(16), border: Border.all(color: (scored ? _kGreen : _kRed).withValues(alpha: .55))),
        child: Column(children: [
          Text('$pct% zgodności', style: TextStyle(color: scored ? _kGreen : _kRed, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(scored ? 'PUNKT DLA GRUPY! 🎉' : 'Za mało (potrzeba 75%)', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800)),
        ]),
      ),
      const SizedBox(height: 10),
      _score('Punkty grupy', scoreA, _kGold, onMinus: () => _patch({'scoreA': (scoreA - 1).clamp(0, 999)}), onPlus: () => _patch({'scoreA': scoreA + 1})),
      if (isHost) ...[
        const SizedBox(height: 16),
        _ggButton('Następne pytanie', Icons.skip_next_rounded, () => _patch({'znajomi': drawFriendsIndex(), 'agreed': 0, 'total': room.players.isEmpty ? 4 : room.players.length})),
      ],
    ];
  }

  // -------------------------------------------------------------------- groups

  Widget _groupsPanel(Map<String, dynamic> s) {
    final groups = <String, String>{
      for (final e in ((s['groups'] as Map?) ?? const {}).entries)
        if (e.value != null) e.key.toString(): e.value.toString(),
    };
    final players = room.players;
    List<String> team(String k) => [for (final p in players) if (groups[p.id] == k) p.name];
    final teamA = team('A');
    final teamB = team('B');
    final myTeam = groups[myPlayerId];

    return IOSGlass(
      opacity: .09,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.diversity_3_rounded, color: _kGold, size: 18),
          const SizedBox(width: 8),
          const Text('Grupy', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        ]),
        if (!isHost) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: (myTeam == 'A' ? _kBlue : myTeam == 'B' ? _kPink : Colors.white).withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: myTeam == 'A' ? _kBlue : myTeam == 'B' ? _kPink : Colors.white24),
            ),
            child: Row(children: [
              Icon(myTeam != null ? Icons.verified_rounded : Icons.hourglass_empty_rounded, color: myTeam == 'A' ? _kBlue : myTeam == 'B' ? _kPink : Colors.white54, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(myTeam != null ? 'Jesteś w Drużynie $myTeam' : 'Gospodarz jeszcze nie przydzielił Cię do drużyny', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900))),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _teamCard('Drużyna A', teamA, _kBlue)),
          const SizedBox(width: 10),
          Expanded(child: _teamCard('Drużyna B', teamB, _kPink)),
        ]),
        if (isHost) ...[
          const SizedBox(height: 12),
          Text('Przydziel graczy do drużyn:', style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final p in players) _assignRow(p.id, p.name, groups[p.id]),
        ],
      ]),
    );
  }

  Widget _teamCard(String title, List<String> members, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 6),
        if (members.isEmpty) Text('—', style: TextStyle(color: AppColors.white.withValues(alpha: .4), fontWeight: FontWeight.w700))
        else for (final m in members) Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(m, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
    );
  }

  Widget _assignRow(String playerId, String name, String? current) {
    Widget btn(String team, Color color) {
      final sel = current == team;
      return GestureDetector(
        onTap: () => service.assignGroup(roomCode, playerId, sel ? null : team),
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          width: 34,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: sel ? color.withValues(alpha: .3) : Colors.white.withValues(alpha: .06), borderRadius: BorderRadius.circular(9), border: Border.all(color: sel ? color : Colors.white.withValues(alpha: .14))),
          child: Text(team, style: TextStyle(color: sel ? color : AppColors.white.withValues(alpha: .7), fontWeight: FontWeight.w900)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(children: [
        Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800))),
        btn('A', _kBlue),
        btn('B', _kPink),
      ]),
    );
  }
}

class _EmptyHintGG extends StatelessWidget {
  const _EmptyHintGG(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.hourglass_empty_rounded, color: AppColors.white.withValues(alpha: .5)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: AppColors.white.withValues(alpha: .7), fontWeight: FontWeight.w700, height: 1.3))),
        ]),
      );
}
