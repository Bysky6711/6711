import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../chat/chat_message.dart';
import '../chat/mafia_chat_screen.dart';
import '../core/app_colors.dart';
import '../core/edition_state.dart';
import '../core/responsive.dart';
import '../core/session_store.dart';
import '../data/card.dart';
import '../data/card_registry.dart';
import '../data/medieval_classes.dart';
import '../data/power_cards.dart';
import '../data/quiz_questions.dart';
import '../data/roles.dart';
import '../models/auction.dart';
import '../models/game_edition.dart';
import '../models/game_phase.dart';
import '../models/game_player.dart';
import '../models/game_room.dart';
import '../models/game_task.dart';
import 'group_games_screen.dart';
import '../models/vote_session.dart';
import '../services/online_room_service.dart';
import '../ui_system/mafia_ios_system.dart';
import '../widgets/shared_widgets.dart';
import 'lobby_screen.dart';

enum _WinSide { none, mafia, town }

/// Mafia win at parity (alive mafia >= alive others); town win when no mafia remain.
/// (For the medieval edition, "mafia" = Antagoniści / "town" = Korona.)
_WinSide _computeWinner(GameRoom room) {
  if (room.edition.isMedieval) return _computeMedievalWinner(room);
  final playing = room.players.where((p) => p.role != null).toList();
  if (playing.isEmpty) return _WinSide.none;
  final aliveMafia = playing.where((p) => p.alive && p.role == MafiaRoleCardType.mafia).length;
  final aliveOthers = playing.where((p) => p.alive && p.role != MafiaRoleCardType.mafia).length;
  if (aliveMafia == 0) return _WinSide.town;
  if (aliveMafia >= aliveOthers) return _WinSide.mafia;
  return _WinSide.none;
}

/// Medieval win: Antagoniści (mafia) vs Korona (town) parity, with the
/// Dziedziczka golden-target exception (eliminating her = instant antagonist win).
/// Rycerz + undeclared Podrzutek are neutral (excluded from parity). Podrzutek
/// counts for whichever side it declared.
_WinSide _computeMedievalWinner(GameRoom room) {
  final playing = room.players.where((p) => p.medievalClass != null).toList();
  if (playing.isEmpty) return _WinSide.none;
  final dziedziczki = playing.where((p) => p.medievalClass == MedievalClassType.dziedziczka);
  if (dziedziczki.isNotEmpty && dziedziczki.every((p) => !p.alive)) return _WinSide.mafia;
  bool isAntag(GamePlayer p) =>
      p.medievalClass == MedievalClassType.emisariusz ||
      (p.medievalClass == MedievalClassType.podrzutek && p.podrzutekFaction == MedievalFaction.antagonisci);
  bool isNeutral(GamePlayer p) =>
      p.medievalClass == MedievalClassType.rycerz ||
      (p.medievalClass == MedievalClassType.podrzutek && p.podrzutekFaction == null);
  final aliveAntag = playing.where((p) => p.alive && isAntag(p)).length;
  final aliveCrown = playing.where((p) => p.alive && !isAntag(p) && !isNeutral(p)).length;
  if (aliveAntag == 0) return _WinSide.town;
  if (aliveAntag >= aliveCrown) return _WinSide.mafia;
  return _WinSide.none;
}

class StartedGameScreen extends StatefulWidget {
  const StartedGameScreen({super.key, required this.roomCode, required this.myPlayerId, required this.isHost});
  final String roomCode;
  final String myPlayerId;
  final bool isHost;

  @override
  State<StartedGameScreen> createState() => _StartedGameScreenState();
}

class _StartedGameScreenState extends State<StartedGameScreen> {
  final OnlineRoomService service = OnlineRoomService();
  GameRoom? room;
  List<PlayedPowerCardAction> playedPowerCards = [];
  List<PowerCardDefinition> playerPowerCards = [];

  StreamSubscription<GameRoom?>? _roomSub;
  StreamSubscription<List<PlayedPowerCardAction>>? _actionsSub;
  StreamSubscription<List<PowerCardDefinition>>? _handSub;
  StreamSubscription<GameTask?>? _taskSub;
  String? _autoTaskKey;
  final Set<String> _seenResolved = {};
  bool _firstActionsLoad = true;
  final PageController _pageController = PageController(initialPage: 1);
  StreamSubscription<List<MafiaChatMessage>>? _messagesSub;
  DateTime _chatLastRead = DateTime.now();
  bool _chatOpen = false;
  bool _firstMsgLoad = true;
  int _unread = 0;
  String? _lastSeenNewestId;
  String? _shownWinner;
  bool _panelOpen = false;
  bool _returning = false;
  bool _wasInGame = false;
  bool _firstRoomLoad = true;
  final Set<String> _deadSeen = {};

  String noteText = '';

  @override
  void initState() {
    super.initState();
    _roomSub = service.watchRoom(widget.roomCode).listen((value) {
      if (!mounted) return;
      _handleDeaths(value);
      _maybeBooted(value);
      setState(() => room = value);
      _maybeShowWinner(value);
      _maybeReturnToLobby(value);
    });
    _actionsSub = service.watchActions(widget.roomCode).listen((value) {
      if (!mounted) return;
      _handleResolvedHits(value);
      setState(() {
        playedPowerCards = value;
      });
    });
    _handSub = service.watchHand(widget.roomCode, widget.myPlayerId).listen((value) {
      if (mounted) setState(() => playerPowerCards = value);
    });
    _messagesSub = service.watchMessages(widget.roomCode, myName: myName).listen(_handleMessages);
    if (!widget.isHost) {
      _taskSub = service.watchTask(widget.roomCode).listen((task) {
        if (!mounted) return;
        if (task == null) {
          _autoTaskKey = null;
          return;
        }
        final key = '${task.createdAt}';
        if (_autoTaskKey == key) return;
        _autoTaskKey = key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final current = room;
          if (!mounted || current == null) return;
          openApp('Zadania', Icons.extension_rounded, _TasksApp(service: service, roomCode: widget.roomCode, isHost: widget.isHost, myPlayerId: widget.myPlayerId, room: current));
        });
      });
    }
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _actionsSub?.cancel();
    _handSub?.cancel();
    _taskSub?.cancel();
    _messagesSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  MafiaRoleCardType get myRole {
    final current = room;
    if (widget.isHost || current == null) return MafiaRoleCardType.host;
    for (final player in current.players) {
      if (player.id == widget.myPlayerId) {
        return player.role ?? MafiaRoleCardType.citizen;
      }
    }
    return MafiaRoleCardType.citizen;
  }

  String get myName {
    final current = room;
    if (widget.isHost) return current?.hostName ?? 'Gospodarz';
    if (current != null) {
      for (final player in current.players) {
        if (player.id == widget.myPlayerId) return player.name;
      }
    }
    return 'Gracz';
  }

  bool _isAlive(GameRoom r) {
    if (widget.isHost) return true;
    for (final p in r.players) {
      if (p.id == widget.myPlayerId) return p.alive;
    }
    return true;
  }

  Future<void> changePhase(GamePhase phase) async {
    if (!widget.isHost) return;
    try {
      await service.changePhase(code: widget.roomCode, phase: phase);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faza zmieniona — zagrane karty rozliczone.')));
      }
    } catch (_) {}
  }

  /// Host ends the game — everyone returns to the lobby (status -> waiting makes
  /// every client auto-navigate back via _maybeReturnToLobby). Players are kept;
  /// roles, life and statuses are reset.
  Future<void> _endGameToLobby() async {
    if (!widget.isHost) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A0B),
        title: const Text('Zakończyć grę?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text('Wszyscy gracze wrócą do lobby. Role, życie i statusy zostaną wyczyszczone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj', style: TextStyle(color: Colors.white))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Zakończ grę', style: TextStyle(color: Color(0xFFE5404F), fontWeight: FontWeight.w900))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await service.resetToLobby(widget.roomCode);
    } catch (_) {}
  }

  Future<void> _registerPowerCard(PlayedPowerCardAction action) async {
    final r = room;
    if (!widget.isHost && r != null && !_isAlive(r)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nie żyjesz — obserwujesz grę.')));
      }
      return;
    }
    if (!widget.isHost && r != null) {
      final me = r.players.where((p) => p.id == widget.myPlayerId);
      if (me.isNotEmpty && me.first.statuses.contains('blocked')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masz kajdanki — nie możesz teraz grać kart.')));
        }
        return;
      }
      // Kompromitacja poziom 2/3 (medieval): nie możesz grać kart do końca dnia.
      if (me.isNotEmpty && (me.first.statuses.contains('kompromitacja2') || me.first.statuses.contains('kompromitacja3'))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kompromitacja — nie możesz teraz grać kart.')));
        }
        return;
      }
    }
    try {
      // Consuming the card must be AUTHORITATIVE: only queue/apply the effect if
      // a copy was actually removed from the hand. Otherwise rapid re-taps (before
      // the hand stream refreshes) would each queue the action and fire its
      // immediate effect off a single card — letting a card's effect be stacked
      // without limit before the next phase change.
      if (action.card.consumesOnUse) {
        final consumed = await service.consumeCard(code: widget.roomCode, playerId: widget.myPlayerId, cardId: action.card.id);
        if (!consumed) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nie masz już tej karty.')));
          }
          return;
        }
      }
      final queued = PlayedPowerCardAction(
        card: action.card,
        sourcePlayerName: action.sourcePlayerName,
        targetPlayerName: action.targetPlayerName,
        secondTargetPlayerName: action.secondTargetPlayerName,
        createdAt: action.createdAt,
        note: action.note,
        phasePlayed: room?.phase.name,
        resolved: false,
      );
      await service.playPowerCard(code: widget.roomCode, action: queued);
      var immediate = false;
      if (action.card.id == 'liberum_veto') {
        await service.clearVote(widget.roomCode);
        immediate = true;
      } else if (action.card.id == 'new_deal') {
        await service.redealHand(code: widget.roomCode, playerId: widget.myPlayerId);
        immediate = true;
      } else if (action.card.id == 'handcuffs' && (action.targetPlayerName ?? '').isNotEmpty) {
        await service.blockCards(code: widget.roomCode, targetName: action.targetPlayerName!);
        immediate = true;
      } else if (action.card.id == 'intimidation' &&
          (action.targetPlayerName ?? '').isNotEmpty &&
          (action.secondTargetPlayerName ?? '').isNotEmpty) {
        await service.forceVote(code: widget.roomCode, forcedName: action.targetPlayerName!, voteForName: action.secondTargetPlayerName!);
        immediate = true;
      } else if (action.card.id == 'podatek_nadzwyczajny' && (action.targetPlayerName ?? '').isNotEmpty) {
        final tl = room?.players.where((p) => p.name == action.targetPlayerName).toList() ?? const [];
        if (tl.isNotEmpty) await service.awardInfluence(code: widget.roomCode, playerId: tl.first.id, amount: -10);
        immediate = true;
      } else if (action.card.id == 'laska_krola' && (action.targetPlayerName ?? '').isNotEmpty) {
        final tl = room?.players.where((p) => p.name == action.targetPlayerName).toList() ?? const [];
        if (tl.isNotEmpty) {
          await service.awardInfluence(code: widget.roomCode, playerId: tl.first.id, amount: 10);
          await service.awardInfluence(code: widget.roomCode, playerId: widget.myPlayerId, amount: -10);
        }
        immediate = true;
      } else if (action.card.id == 'slubowanie_wiernosci' && (action.targetPlayerName ?? '').isNotEmpty) {
        await service.copyVote(code: widget.roomCode, forcedName: action.targetPlayerName!, sourceId: widget.myPlayerId);
        immediate = true;
      } else if (action.card.id == 'bankructwo' && (action.targetPlayerName ?? '').isNotEmpty) {
        final tl = room?.players.where((p) => p.name == action.targetPlayerName).toList() ?? const [];
        if (tl.isNotEmpty) await service.zeroInfluence(code: widget.roomCode, playerId: tl.first.id);
        immediate = true;
      } else if (action.card.id == 'podrobiona_pieczec') {
        await service.markStatus(code: widget.roomCode, playerId: widget.myPlayerId, status: 'doublevote');
        immediate = true;
      } else if (action.card.id == 'skradziona_tozsamosc' && (action.targetPlayerName ?? '').isNotEmpty) {
        await service.markStatus(code: widget.roomCode, playerId: widget.myPlayerId, status: 'identity:${action.targetPlayerName}');
        immediate = true;
      } else if (action.card.id == 'deal' && (action.targetPlayerName ?? '').isNotEmpty) {
        final tl = room?.players.where((p) => p.name == action.targetPlayerName).toList() ?? const [];
        if (tl.isNotEmpty) await service.swapHands(code: widget.roomCode, aId: widget.myPlayerId, bId: tl.first.id);
        immediate = true;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(immediate
              ? 'Karta \u201e${action.card.name}\u201d zagrana \u2014 efekt natychmiastowy.'
              : 'Karta \u201e${action.card.name}\u201d zagrana \u2014 zadzia\u0142a w nast\u0119pnej fazie.')),
        );
      }
    } catch (_) {}
  }

  /// Fires an on-screen overlay when a queued card resolves against ME.
  void _handleResolvedHits(List<PlayedPowerCardAction> actions) {
    if (widget.isHost) {
      _firstActionsLoad = false;
      return;
    }
    final me = myName;
    for (final a in actions) {
      if (!a.resolved || a.targetPlayerName == null || a.targetPlayerName != me) continue;
      if (_seenResolved.contains(a.key)) continue;
      _seenResolved.add(a.key);
      if (_firstActionsLoad) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCardHitOverlay(a);
      });
    }
    _firstActionsLoad = false;
  }

  void _showCardHitOverlay(PlayedPowerCardAction action) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: action.card.name,
      barrierColor: Colors.black.withValues(alpha: .64),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, _, _) => Material(
        type: MaterialType.transparency,
        child: Center(child: _CardHitCard(action: action)),
      ),
      transitionBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.82 + 0.18 * curved.value, child: child),
        );
      },
    );
  }

  Future<void> _dealCard(String playerId, String cardId) async {
    try {
      await service.assignCard(code: widget.roomCode, playerId: playerId, cardId: cardId);
    } catch (_) {}
  }

  Future<void> _leaveRoom() async {
    if (!await confirmExitGame(context)) return;
    if (!mounted) return;
    await SessionStore.clear();
    if (!widget.isHost) {
      try {
        await service.removePlayer(code: widget.roomCode, playerId: widget.myPlayerId);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _maybeShowWinner(GameRoom? r) {
    if (r == null || !r.isInProgress) return;
    final side = _computeWinner(r);
    if (side == _WinSide.none) {
      _shownWinner = null;
      return;
    }
    if (_shownWinner == side.name) return;
    _shownWinner = side.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showWinnerOverlay(side, r);
    });
  }

  void _handleDeaths(GameRoom? r) {
    if (r == null) return;
    final dead = r.players.where((p) => !p.alive).map((p) => p.name).toSet();
    if (_firstRoomLoad) {
      _deadSeen.addAll(dead);
      _firstRoomLoad = false;
      return;
    }
    final newly = dead.difference(_deadSeen);
    _deadSeen
      ..clear()
      ..addAll(dead);
    for (final name in newly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('☠️ $name — nie żyje'), duration: const Duration(seconds: 3)));
        }
      });
    }
  }

  void _maybeBooted(GameRoom? r) {
    if (r == null || widget.isHost || _returning) return;
    if (r.players.any((p) => p.id == widget.myPlayerId)) {
      _wasInGame = true;
      return;
    }
    if (!_wasInGame) return;
    _returning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SessionStore.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gospodarz usunął Cię z gry.')));
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  void _maybeReturnToLobby(GameRoom? r) {
    if (r == null || !r.isWaiting || _returning) return;
    _returning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LobbyScreen(roomCode: widget.roomCode, myPlayerId: widget.myPlayerId, isHost: widget.isHost)),
      );
    });
  }

  void _showWinnerOverlay(_WinSide side, GameRoom room) {
    final medieval = room.edition.isMedieval;
    String? prestige;
    if (medieval) {
      final entries = room.wplywy.entries.where((e) => e.value > 0).toList();
      if (entries.isNotEmpty) {
        entries.sort((a, b) => b.value.compareTo(a.value));
        final top = entries.first;
        final matches = room.players.where((p) => p.id == top.key).toList();
        final name = matches.isEmpty ? 'Nieznany dworzanin' : matches.first.name;
        prestige = '$name — ${top.value} Wpływów';
      }
    }
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'winner',
      barrierColor: Colors.black.withValues(alpha: .8),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => Material(
        type: MaterialType.transparency,
        child: Center(
          child: _WinnerCard(
            mafia: side == _WinSide.mafia,
            medieval: medieval,
            prestige: prestige,
            isHost: widget.isHost,
            onNewGame: () {
              Navigator.of(context).maybePop();
              service.resetToLobby(widget.roomCode);
            },
          ),
        ),
      ),
      transitionBuilder: (_, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return Opacity(opacity: anim.value.clamp(0.0, 1.0), child: Transform.scale(scale: 0.8 + 0.2 * curved.value, child: child));
      },
    );
  }

  // ---- chat notifications (Discord-style unread badge + toast) --------------

  bool _canSeeChannel(String channelId) {
    if (channelId == 'general') return true;
    if (channelId == 'mafia') return widget.isHost || myRole == MafiaRoleCardType.mafia;
    if (channelId == 'dead') {
      final r = room;
      return widget.isHost || (r != null && !_isAlive(r));
    }
    if (channelId.startsWith('dm::')) {
      return channelId.substring(4).split('::').contains(myName);
    }
    return false;
  }

  void _handleMessages(List<MafiaChatMessage> msgs) {
    if (!mounted || room == null) return;
    final me = myName;
    final incoming = msgs.where((m) => !m.isSystem && m.senderName != me && _canSeeChannel(m.channelId)).toList();
    final unread = _chatOpen ? 0 : incoming.where((m) => m.createdAt.isAfter(_chatLastRead)).length;
    final newest = incoming.isNotEmpty ? incoming.last : null;
    final shouldToast = !_firstMsgLoad && !_chatOpen && newest != null && newest.id != _lastSeenNewestId && newest.createdAt.isAfter(_chatLastRead);
    setState(() => _unread = unread);
    if (shouldToast) _showChatToast(newest);
    if (newest != null) _lastSeenNewestId = newest.id;
    _firstMsgLoad = false;
  }

  void _showChatToast(MafiaChatMessage m) {
    final initial = m.senderName.isEmpty ? '?' : m.senderName.characters.first.toUpperCase();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 3),
      content: Row(children: [
        CircleAvatar(radius: 14, backgroundColor: kOneAccent.withValues(alpha: .3), child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.senderName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            Text(m.text.isEmpty ? '📷 Naklejka' : m.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ]),
      action: SnackBarAction(
        label: 'Otwórz',
        onPressed: () {
          final r = room;
          if (r != null) _openMessages(r);
        },
      ),
    ));
  }

  Future<void> _openMessages(GameRoom current) async {
    final playerNames = [current.hostName, ...current.players.map((p) => p.name)];
    final amMafia = widget.isHost || myRole == MafiaRoleCardType.mafia;
    setState(() {
      _chatOpen = true;
      _unread = 0;
      _chatLastRead = DateTime.now();
    });
    await openApp('Wiadomości', Icons.send_rounded, MafiaChatScreen(service: service, roomCode: current.roomCode, currentPlayerName: myName, canSeeMafia: amMafia, players: playerNames, amDead: !_isAlive(current), isHost: widget.isHost));
    if (mounted) {
      setState(() {
        _chatOpen = false;
        _chatLastRead = DateTime.now();
      });
    }
  }

  Future<void> openApp(String title, IconData icon, Widget child) {
    return Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => _IOSAppPage(title: title, icon: icon, child: child),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(opacity: curved, child: ScaleTransition(scale: Tween<double>(begin: .92, end: 1).animate(curved), child: child));
      },
    ));
  }

  Widget _settingsApp(GameRoom current) => _SettingsApp(
        room: current,
        isHost: widget.isHost,
        onDealCard: widget.isHost ? _dealCard : null,
      );

  Widget _cardFeed(GameRoom current) => _CardFeedApp(
        actions: playedPowerCards,
        isHost: widget.isHost,
        myName: myName,
      );

  Widget _voting(GameRoom current) => _VotingApp(
        service: service,
        roomCode: current.roomCode,
        isHost: widget.isHost,
        myPlayerId: widget.myPlayerId,
        room: current,
      );

  @override
  Widget build(BuildContext context) {
    final current = room;
    if (current == null) {
      return const MafiaIOSScaffold(
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    activeEdition = current.edition; // theme background/reveal by edition
    final amDead = !_isAlive(current);
    return MafiaIOSScaffold(
      child: Stack(
        children: [
          PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          _voting(current),
          _Home(
            room: current,
            wallet: current.wallets[widget.myPlayerId] ?? 0,
            messagesBadge: _unread,
            onSettings: () => openApp('Ustawienia', Icons.settings_rounded, _settingsApp(current)),
            onRules: () => openApp('Zasady', Icons.description_outlined, const _RulesApp()),
            onNotes: () => openApp('Notatki', Icons.edit_rounded, _SamsungNotesApp(initialText: noteText, onChanged: (value) => noteText = value)),
            onAvatar: () => openApp('Avatar', Icons.person_rounded, _AvatarMenuApp(room: current, myName: myName, myRole: myRole, myPlayerId: widget.myPlayerId, onOpenNotes: () => openApp('Notatki', Icons.edit_rounded, _SamsungNotesApp(initialText: noteText, onChanged: (value) => noteText = value)), onOpenSettings: () => openApp('Ustawienia', Icons.settings_rounded, _settingsApp(current)))),
            onPower: () => openApp('Karty mocy', Icons.auto_awesome_rounded, _PowerCardsApp(room: current, myName: myName, cards: playerPowerCards, onPlay: _registerPowerCard)),
            onMyCard: () => openApp('ID', Icons.badge_rounded, _IdCardApp(role: myRole, playerName: myName, roomCode: current.roomCode, playerId: widget.myPlayerId)),
            onMessages: () => _openMessages(current),
            onTasks: () => openApp('Zadania', Icons.extension_rounded, _TasksApp(service: service, roomCode: current.roomCode, isHost: widget.isHost, myPlayerId: widget.myPlayerId, room: current)),
            onGroupGames: () => openApp('Gry grupowe', Icons.groups_2_rounded, GroupGamesApp(service: service, roomCode: current.roomCode, isHost: widget.isHost, room: current, myPlayerId: widget.myPlayerId)),
            onAbility: () => (current.edition.isMedieval && widget.isHost)
                ? openApp('Intrygi dworu', Icons.castle_rounded, _MedievalHostPanel(service: service, roomCode: current.roomCode))
                : openApp('Zdolność klasy', Icons.bolt_rounded, current.edition.isMedieval
                    ? _MedievalAbilityApp(service: service, roomCode: current.roomCode, myPlayerId: widget.myPlayerId, isHost: widget.isHost)
                    : _ClassAbilityApp(service: service, roomCode: current.roomCode, myPlayerId: widget.myPlayerId, myRole: myRole, isHost: widget.isHost)),
            onAuction: () => openApp('Licytacja', Icons.gavel_rounded, _AuctionApp(service: service, roomCode: current.roomCode, isHost: widget.isHost, myPlayerId: widget.myPlayerId, room: current)),
            onPlayers: () => openApp('Gracze', Icons.groups_rounded, _PlayersApp(service: service, roomCode: current.roomCode, isHost: widget.isHost, myPlayerId: widget.myPlayerId)),
            onCatalog: () => openApp('Katalog kart', Icons.menu_book_rounded, const _CardCatalogApp()),
            onExit: _leaveRoom,
          ),
          _cardFeed(current),
        ],
      ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_panelOpen,
              child: GestureDetector(
                onTap: () => setState(() => _panelOpen = false),
                child: AnimatedContainer(duration: const Duration(milliseconds: 220), color: Colors.black.withValues(alpha: _panelOpen ? .5 : 0)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              offset: _panelOpen ? Offset.zero : const Offset(0, -1),
              child: _QuickPanel(
                room: current,
                isHost: widget.isHost,
                myPlayerId: widget.myPlayerId,
                myRoleLabel: (current.edition.isMedieval && myRole == MafiaRoleCardType.host) ? 'Król' : GameRoles.nameOf(myRole),
                pendingCards: playedPowerCards.where((a) => !a.resolved).length,
                onChangePhase: changePhase,
                onEndGame: _endGameToLobby,
                onClose: () => setState(() => _panelOpen = false),
              ),
            ),
          ),
          if (!_panelOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _PanelGrip(onOpen: () => setState(() => _panelOpen = true)),
            ),
          if (amDead)
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _GhostBanner(),
            ),
        ],
      ),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({required this.room, required this.wallet, required this.messagesBadge, required this.onSettings, required this.onRules, required this.onNotes, required this.onAvatar, required this.onPower, required this.onMyCard, required this.onMessages, required this.onTasks, required this.onGroupGames, required this.onAbility, required this.onAuction, required this.onPlayers, required this.onCatalog, required this.onExit});
  final GameRoom room;
  final int wallet;
  final int messagesBadge;
  final VoidCallback onSettings, onRules, onNotes, onAvatar, onPower, onMyCard, onMessages, onTasks, onGroupGames, onAbility, onAuction, onPlayers, onCatalog, onExit;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late List<_HomeIconData> icons;

  @override
  void initState() {
    super.initState();
    icons = [
      _HomeIconData('ustawienia', Icons.settings_rounded, widget.onSettings, tint: const Color(0xFF7C8AA5)),
      _HomeIconData('zasady', Icons.description_outlined, widget.onRules, tint: const Color(0xFF14B8A6)),
      _HomeIconData('notatki', Icons.edit_rounded, widget.onNotes, tint: const Color(0xFFF59E0B)),
      _HomeIconData('avatar', Icons.person_rounded, widget.onAvatar, tint: const Color(0xFFA855F7)),
      _HomeIconData('wiadomości', Icons.send_rounded, widget.onMessages, tint: const Color(0xFF3B82F6)),
      _HomeIconData('zadania', Icons.extension_rounded, widget.onTasks, tint: const Color(0xFF22C55E)),
      _HomeIconData('gry grupowe', Icons.groups_2_rounded, widget.onGroupGames, tint: const Color(0xFF10B981)),
      _HomeIconData('licytacja', Icons.gavel_rounded, widget.onAuction, tint: const Color(0xFFF97316)),
      _HomeIconData('gracze', Icons.groups_rounded, widget.onPlayers, tint: const Color(0xFFEC4899)),
      _HomeIconData('katalog kart', Icons.menu_book_rounded, widget.onCatalog, tint: const Color(0xFF0EA5E9)),
      _HomeIconData('zdolność', Icons.bolt_rounded, widget.onAbility, tint: const Color(0xFFFACC15)),
      _HomeIconData('karty mocy', Icons.auto_awesome_rounded, widget.onPower, tint: const Color(0xFF8B5CF6)),
      _HomeIconData('id', Icons.badge_rounded, widget.onMyCard, tint: const Color(0xFFE5404F)),
      _HomeIconData('menu', Icons.home_rounded, widget.onExit, tint: const Color(0xFF64748B)),
    ];
  }

  void _moveIcon(int from, int to) {
    if (from == to || icons[to].assetPath != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      final item = icons.removeAt(from);
      icons.insert(to, item);
      final cards = icons.where((e) => e.assetPath != null).toList();
      icons.removeWhere((e) => e.assetPath != null);
      icons.addAll(cards);
    });
  }

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width >= 520 ? 5 : 4;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 18, Responsive.horizontalPadding(context), 24 + bottomSafe),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
          child: Column(children: [
            IOSGlass(
              radius: 32,
              opacity: .15,
              borderOpacity: .13,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FAZA GRY', style: TextStyle(color: AppColors.white.withValues(alpha: .55), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(phaseLabel(widget.room.phase), style: const TextStyle(color: AppColors.white, fontSize: 38, fontWeight: FontWeight.w900, height: 1.0)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: kOneAccent.withValues(alpha: .18), borderRadius: BorderRadius.circular(99), border: Border.all(color: kOneAccent.withValues(alpha: .5))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.payments_rounded, color: kOneAccent, size: 16),
                          const SizedBox(width: 6),
                          Text('\$${widget.wallet}', style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.room.roomCode));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Skopiowano kod: ${widget.room.roomCode}')));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withValues(alpha: .18))),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.copy_rounded, color: AppColors.white.withValues(alpha: .8), size: 15),
                            const SizedBox(width: 6),
                            Text(widget.room.roomCode, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ])),
                AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Icon(phaseIcon(widget.room.phase), key: ValueKey(widget.room.phase), color: kOneAccent, size: 72)),
              ]),
            ),
            const SizedBox(height: 22),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: icons.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 18, crossAxisSpacing: 12, childAspectRatio: .78),
              itemBuilder: (context, index) {
                final item = icons[index];
                final display = item.label == 'wiadomości'
                    ? _HomeIconData(item.label, item.icon, item.onTap, badge: widget.messagesBadge, isPremium: item.isPremium, assetPath: item.assetPath, tint: item.tint)
                    : item;
                return DragTarget<int>(
                  onWillAcceptWithDetails: (details) => details.data != index && item.assetPath == null,
                  onAcceptWithDetails: (details) => _moveIcon(details.data, index),
                  builder: (context, candidate, rejected) => AnimatedScale(
                    scale: candidate.isNotEmpty && item.assetPath == null ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: LongPressDraggable<int>(
                      data: index,
                      delay: const Duration(milliseconds: 180),
                      feedback: Material(color: Colors.transparent, child: Transform.scale(scale: 1.08, child: _HomeIcon(item: display))),
                      childWhenDragging: Opacity(opacity: .28, child: _HomeIcon(item: display)),
                      onDragStarted: () => HapticFeedback.mediumImpact(),
                      child: _HomeIcon(item: display),
                    ),
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _HomeIconData {
  const _HomeIconData(this.label, this.icon, this.onTap, {this.badge = 0, this.isPremium = false, this.assetPath, this.tint});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  final bool isPremium;
  final String? assetPath;
  final Color? tint;
}

class _HomeIcon extends StatelessWidget {
  const _HomeIcon({required this.item});
  final _HomeIconData item;
  @override
  Widget build(BuildContext context) {
    return IOSAppIcon(label: item.label, icon: item.icon, badge: item.badge, isPremium: item.isPremium, tint: item.tint, onTap: item.onTap);
  }
}

class _IOSAppPage extends StatelessWidget {
  const _IOSAppPage({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var dragDx = 0.0;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) => dragDx += details.delta.dx,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (dragDx > 72 || velocity > 560) Navigator.of(context).maybePop();
        dragDx = 0;
      },
      child: Dismissible(
        key: ValueKey(title),
        direction: DismissDirection.down,
        resizeDuration: null,
        onDismissed: (_) => Navigator.of(context).maybePop(),
        child: MafiaIOSScaffold(
          darkOverlay: .10,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 12, Responsive.horizontalPadding(context), 14 + bottomSafe),
            child: Column(children: [
              Row(children: [
                IOSBackButton(onTap: () => Navigator.pop(context)),
                Icon(icon, color: AppColors.white, size: 25),
                const SizedBox(width: 10),
                Expanded(child: Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.white, fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .12))),
                      child: child,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 9 + bottomSafe * .15),
              Container(width: 118, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(99))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SettingsApp extends StatelessWidget {
  const _SettingsApp({required this.room, required this.isHost, this.onDealCard});

  final GameRoom room;
  final bool isHost;
  final void Function(String playerId, String cardId)? onDealCard;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
      physics: const BouncingScrollPhysics(),
      children: [
        SectionHeader(title: 'Ustawienia', icon: Icons.tune_rounded),
        const SizedBox(height: 10),
        if (isHost) ...[
          Text('Fazą gry i skryptem nocy sterujesz panelem u góry (przeciągnij palcem w dół od górnej krawędzi). Tutaj rozdasz karty mocy.', style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 16),
          SectionHeader(title: 'Rozdaj karty mocy', icon: Icons.card_giftcard_rounded),
          const SizedBox(height: 12),
          _DealCardButton(room: room, onDealCard: onDealCard),
        ] else
          Text('Fazę gry i przebieg prowadzi gospodarz. Statusy graczy zobaczysz w „Gracze", a opisy kart w „Katalog kart".', style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontWeight: FontWeight.w700, height: 1.3)),
      ],
    );
  }
}

class _AvatarMenuApp extends StatelessWidget {
  const _AvatarMenuApp({required this.room, required this.myName, required this.myRole, required this.myPlayerId, required this.onOpenNotes, required this.onOpenSettings});
  final GameRoom room;
  final String myName;
  final MafiaRoleCardType myRole;
  final String myPlayerId;
  final VoidCallback onOpenNotes;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 24 + bottomSafe),
      physics: const BouncingScrollPhysics(),
      children: [
        IOSGlass(
          opacity: .14,
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF6F1D1B), Color(0xFFFFD166)]), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 20, offset: const Offset(0, 10))]),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 54),
            ),
            const SizedBox(height: 12),
            Text(myName, style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${room.edition.isMedieval && myRole == MafiaRoleCardType.host ? 'Król' : GameRoles.nameOf(myRole)} • Pokój ${room.roomCode}', style: TextStyle(color: AppColors.white.withValues(alpha: .68), fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 16),
        _AvatarAction(icon: Icons.edit_note_rounded, title: 'Notatnik', subtitle: 'Szybkie notatki jak w Samsung Notes', onTap: onOpenNotes),
        _AvatarAction(icon: Icons.settings_rounded, title: 'Ustawienia', subtitle: 'Ustawienia gry', onTap: onOpenSettings),
        _AvatarAction(icon: Icons.badge_rounded, title: 'Twoje ID', subtitle: 'Podgląd Twojego identyfikatora', onTap: () {
          final mine = room.players.where((p) => p.id == myPlayerId).toList();
          final myMed = mine.isEmpty ? null : mine.first.medievalClass;
          Navigator.push(context, MaterialPageRoute(builder: (_) => RoleRevealScreen(roleType: myRole, playerName: myName, playerId: myPlayerId, roomCode: room.roomCode, instantIdOnly: true, edition: room.edition, medievalClass: myMed)));
        }),
        const SizedBox(height: 4),
        IOSGlass(
          opacity: .09,
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Icon(Icons.palette_rounded, color: AppColors.white.withValues(alpha: .7), size: 40),
            const SizedBox(height: 10),
            const Text('Zmiana avatara', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFFFD166).withValues(alpha: .18), borderRadius: BorderRadius.circular(99), border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: .5))),
              child: const Text('WORK IN PROGRESS', style: TextStyle(color: Color(0xFFFFD166), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),
            Text('Wkrótce: wybór ikony i koloru avatara.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontWeight: FontWeight.w700)),
          ]),
        ),
      ],
    );
  }
}

class _AvatarAction extends StatelessWidget {
  const _AvatarAction({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: IOSGlass(
            opacity: .09,
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.white)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: AppColors.white.withValues(alpha: .62), fontWeight: FontWeight.w700)),
              ])),
              Icon(Icons.chevron_right_rounded, color: AppColors.white.withValues(alpha: .6)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _IdCardApp extends StatelessWidget {
  const _IdCardApp({required this.role, required this.playerName, required this.roomCode, required this.playerId});
  final MafiaRoleCardType role;
  final String playerName;
  final String roomCode;
  final String playerId;

  String get _prettyId {
    final src = playerId.isNotEmpty ? playerId : '$playerName-$roomCode';
    var h = 0;
    for (final c in src.codeUnits) {
      h = (h * 31 + c) & 0xFFFFFF;
    }
    return 'ID-${h.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  String get _roleAsset {
    switch (role) {
      case MafiaRoleCardType.host:
        return 'assets/images/card/card_back_blue.jpg';
      case MafiaRoleCardType.mafia:
        return MafiaAssets.mafiaClassCard;
      case MafiaRoleCardType.detective:
        return 'assets/images/card/card_class_detektyw.jpg';
      case MafiaRoleCardType.sheriff:
        return 'assets/images/card/card_class_szeryf.jpg';
      case MafiaRoleCardType.citizen:
        return 'assets/images/card/card_class_obywatel.jpg';
      case MafiaRoleCardType.doctor:
        return 'assets/images/card/2.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 24 + bottomSafe),
      physics: const BouncingScrollPhysics(),
      children: [
        SectionHeader(title: 'Twoje ID', icon: Icons.badge_rounded),
        const SizedBox(height: 6),
        Text('Twój wydrukowany identyfikator z losowania roli.', style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 20),
        Center(
          child: PrintedMafiaId(
            progress: 1,
            assetPath: _roleAsset,
            playerName: playerName,
            playerId: _prettyId,
            roomCode: roomCode,
            role: GameRoles.nameOf(role).toUpperCase(),
            onFinish: () {},
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text('Stuknij miniaturę karty, aby ją powiększyć.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.white.withValues(alpha: .55), fontSize: 12, fontWeight: FontWeight.w700))),
      ],
    );
  }
}

class _PowerCardsApp extends StatelessWidget {
  const _PowerCardsApp({required this.room, required this.myName, required this.cards, required this.onPlay});
  final GameRoom room;
  final String myName;
  final List<PowerCardDefinition> cards;
  final ValueChanged<PlayedPowerCardAction> onPlay;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
      physics: const BouncingScrollPhysics(),
      children: [
        SectionHeader(title: 'Karty mocy', icon: Icons.auto_awesome_rounded),
        const SizedBox(height: 10),
        Text('Masz ${cards.length} kart. Dotknij „Rzuć kartę", aby zagrać efekt.', style: TextStyle(color: AppColors.white.withValues(alpha: .70), fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (cards.isEmpty)
          const _EmptyHint(text: 'Nie masz kart mocy. Gospodarz może Ci je rozdać.')
        else
          ...cards.map((card) => _PowerCardTile(room: room, myName: myName, card: card, onPlay: onPlay)),
      ],
    );
  }
}

class _PowerCardTile extends StatefulWidget {
  const _PowerCardTile({required this.room, required this.myName, required this.card, required this.onPlay});
  final GameRoom room;
  final String myName;
  final PowerCardDefinition card;
  final ValueChanged<PlayedPowerCardAction> onPlay;

  @override
  State<_PowerCardTile> createState() => _PowerCardTileState();
}

class _PowerCardTileState extends State<_PowerCardTile> {
  Future<void> _play() async {
    final action = await showModalBottomSheet<PlayedPowerCardAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlayPowerCardSheet(room: widget.room, myName: widget.myName, card: widget.card),
    );
    if (action == null) return;
    widget.onPlay(action);
    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rzucono kartę: ${widget.card.name}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.black.withValues(alpha: .30), border: Border.all(color: widget.card.color.withValues(alpha: .55))),
        child: _PowerCardFace(card: widget.card, currentPhase: widget.room.phase, onPlay: _play),
      ),
    );
  }
}

class _PowerCardFace extends StatelessWidget {
  const _PowerCardFace({required this.card, required this.currentPhase, required this.onPlay});
  final PowerCardDefinition card;
  final GamePhase currentPhase;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final canPlay = card.canBePlayedIn(currentPhase);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: card.color.withValues(alpha: .20), border: Border.all(color: card.color.withValues(alpha: .55))), child: Icon(card.icon, color: card.color)),
        const SizedBox(width: 12),
        Expanded(child: Text(card.name, style: const TextStyle(color: AppColors.white, fontSize: 19, fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 10),
      Text(card.effectDescription, style: TextStyle(color: AppColors.white.withValues(alpha: .76), fontWeight: FontWeight.w700, height: 1.28)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _CardBadge(text: 'Faza: ${card.timingLabel}', color: card.color),
        _CardBadge(text: 'Cel: ${card.targetLabel}', color: card.color),
        if (card.requiresConsent) _CardBadge(text: 'Wymaga zgody', color: const Color(0xFFFFD166)),
        if (card.automatic) _CardBadge(text: 'Automatyczna', color: const Color(0xFF06B6D4)),
      ]),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onPlay, icon: const Icon(Icons.bolt_rounded), label: Text(canPlay ? 'Rzuć kartę' : 'Rzuć (poza fazą: ${card.timingLabel})'), style: ElevatedButton.styleFrom(backgroundColor: card.color, foregroundColor: Colors.black, textStyle: const TextStyle(fontWeight: FontWeight.w900)))),
    ]);
  }
}

class _PlayPowerCardSheet extends StatefulWidget {
  const _PlayPowerCardSheet({required this.room, required this.myName, required this.card});
  final GameRoom room;
  final String myName;
  final PowerCardDefinition card;

  @override
  State<_PlayPowerCardSheet> createState() => _PlayPowerCardSheetState();
}

class _PlayPowerCardSheetState extends State<_PlayPowerCardSheet> {
  String? firstTarget;
  String? secondTarget;
  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  List<String> get players => [
        for (final p in widget.room.players)
          if (p.alive) p.name,
      ];

  bool get needsFirstTarget => widget.card.targetMode == PowerCardTargetMode.onePlayer || widget.card.targetMode == PowerCardTargetMode.twoPlayers || widget.card.targetMode == PowerCardTargetMode.selfOrPlayer;
  bool get needsSecondTarget => widget.card.targetMode == PowerCardTargetMode.twoPlayers;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
        decoration: const BoxDecoration(color: Color(0xFF120505), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          Row(children: [Icon(widget.card.icon, color: widget.card.color), const SizedBox(width: 10), Expanded(child: Text('Rzuć kartę: ${widget.card.name}', style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)))]),
          const SizedBox(height: 14),
          if (needsFirstTarget) _PlayerDropdown(label: widget.card.targetMode == PowerCardTargetMode.selfOrPlayer ? 'Cel / osoba leczona' : 'Pierwszy cel', value: firstTarget, players: players, onChanged: (value) => setState(() => firstTarget = value)),
          if (needsSecondTarget) ...[
            const SizedBox(height: 10),
            _PlayerDropdown(label: widget.card.id == 'intimidation' ? 'Na kogo ma zagłosować' : 'Drugi cel', value: secondTarget, players: players, onChanged: (value) => setState(() => secondTarget = value)),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 4,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
            decoration: InputDecoration(labelText: 'Notatka dla gospodarza', labelStyle: TextStyle(color: AppColors.white.withValues(alpha: .68)), filled: true, fillColor: Colors.white.withValues(alpha: .08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .14)))),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if ((needsFirstTarget && firstTarget == null) || (needsSecondTarget && secondTarget == null)) return;
                Navigator.pop(context, PlayedPowerCardAction(card: widget.card, sourcePlayerName: widget.myName, targetPlayerName: firstTarget, secondTargetPlayerName: secondTarget, createdAt: DateTime.now(), note: noteController.text.trim().isEmpty ? null : noteController.text.trim()));
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Zagraj efekt'),
              style: ElevatedButton.styleFrom(backgroundColor: widget.card.color, foregroundColor: Colors.black, textStyle: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _CardCatalogApp extends StatelessWidget {
  const _CardCatalogApp();

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final medieval = activeEdition.isMedieval;
    final cards = cardsFor(activeEdition);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
      physics: const BouncingScrollPhysics(),
      children: [
        SectionHeader(title: medieval ? 'Katalog dworski' : 'Katalog kart mocy', icon: Icons.menu_book_rounded),
        const SizedBox(height: 6),
        Text('Wszystkie ${cards.length} kart w grze i co robią.', style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...cards.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF33221F), borderRadius: BorderRadius.circular(18), border: Border.all(color: c.color.withValues(alpha: .35))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: c.color.withValues(alpha: .2), border: Border.all(color: c.color.withValues(alpha: .7))), child: Icon(c.icon, color: c.color, size: 24)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(c.effectDescription, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 13, height: 1.3)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _catChip('Faza: ${c.timingLabel}', c.color),
                    _catChip('Cel: ${c.targetLabel}', c.color),
                  ]),
                ])),
              ]),
            )),
      ],
    );
  }

  Widget _catChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .45))),
        child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class _PlayerDropdown extends StatelessWidget {
  const _PlayerDropdown({required this.label, required this.value, required this.players, required this.onChanged});
  final String label;
  final String? value;
  final List<String> players;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: players.map((player) => DropdownMenuItem(value: player, child: Text(player))).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF220808),
      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
      decoration: InputDecoration(labelText: label, labelStyle: TextStyle(color: AppColors.white.withValues(alpha: .68)), filled: true, fillColor: Colors.white.withValues(alpha: .08), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .14)))),
    );
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withValues(alpha: .38))), child: Text(text, style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w900)));
  }
}

class _RulesApp extends StatelessWidget {
  const _RulesApp();

  Widget _section(String title, IconData icon, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MafiaPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: const Color(0xFFFFD166), size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 10),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFE5404F), shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(l, style: TextStyle(color: AppColors.white.withValues(alpha: .84), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4))),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medieval = activeEdition.isMedieval;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.viewPaddingOf(context).bottom),
      physics: const BouncingScrollPhysics(),
      children: [
        SectionHeader(title: medieval ? 'Zasady — Edycja Średniowiecze' : 'Zasady gry', icon: Icons.menu_book_rounded),
        const SizedBox(height: 10),
        Text(
          medieval
              ? 'Edycja Średniowiecze to dworskie intrygi zamiast miejskiej Mafii. Dwór dzieli się na Koronę i Antagonistów (Ród Węża). Zamiast zabójstw są wygnania, zamiast śledztwa — kompromitacja i dowody, a obok złota (\$) pojawia się drugi zasób: Wpływy.'
              : 'Mafia to gra towarzyska dla większej grupy. Gospodarz prowadzi rozgrywkę, a gracze walczą w dwóch obozach: Mafia kontra Miasto. Poniżej znajdziesz wszystko, czego potrzebujesz.',
          style: TextStyle(color: AppColors.white.withValues(alpha: .7), fontSize: 14, fontWeight: FontWeight.w700, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (medieval) ..._medievalSections() else ..._standardSections(),
      ],
    );
  }

  List<Widget> _standardSections() => [
        _section('Cel gry', Icons.flag_rounded, [
          'Miasto wygrywa, gdy wszyscy członkowie Mafii zostaną wyeliminowani.',
          'Mafia wygrywa, gdy jej liczebność zrówna się z liczbą pozostałych graczy Miasta.',
        ]),
        _section('Obozy i role', Icons.groups_rounded, [
          'Mafia — nocą wspólnie wybiera ofiarę, za dnia udaje niewinnych.',
          'Detektyw — nocą sprawdza, czy wskazany gracz należy do Mafii.',
          'Szeryf — po stronie Miasta, wspiera śledztwo i porządek.',
          'Lekarz — nocą może ochronić jednego gracza przed śmiercią.',
          'Obywatel — bez zdolności; dyskutuje i głosuje.',
          'Gospodarz — prowadzi grę i nie należy do żadnego obozu.',
        ]),
        _section('Gospodarz (Mistrz Gry)', Icons.admin_panel_settings_rounded, [
          'Steruje fazami z panelu u góry (przeciągnij palcem w dół od górnej krawędzi).',
          'Nie bierze udziału w zadaniach, licytacji ani głosowaniu — tylko prowadzi.',
          'Widzi pełny log zagranych kart, cele i statusy graczy.',
          'Rozdaje karty mocy oraz kończy grę: „Zakończ grę → Lobby".',
        ]),
        _section('Przebieg rundy', Icons.timelapse_rounded, [
          'NOC — budzą się role ze zdolnościami (Mafia, Detektyw, Lekarz…).',
          'DZIEŃ — wszyscy dyskutują i szukają Mafii.',
          'GŁOSOWANIE — gracze wskazują osobę do wyeliminowania.',
          'Cykl powtarza się aż do zwycięstwa jednego z obozów.',
        ]),
        _section('Głosowanie', Icons.how_to_vote_rounded, [
          'Odpada gracz z największą liczbą głosów.',
          'Remis → dogrywka tylko wśród remisujących osób.',
          'Kolejny remis → nikt nie odpada w tej rundzie.',
          'Możesz wstrzymać się od głosu.',
        ]),
        _section('Śmierć i obserwacja', Icons.visibility_rounded, [
          'Martwy gracz nie gra, ale obserwuje rozgrywkę.',
          'Pisze wyłącznie na kanale #zmarli i widzi role graczy.',
          'Nie może głosować ani grać kart mocy.',
        ]),
        _section('Karty mocy', Icons.auto_awesome_rounded, [
          'Zdobywasz je w zadaniach i na licytacji.',
          'Grasz kartę w odpowiedniej fazie (dzień / noc / głosowanie).',
          'Efekty rozliczają się automatycznie: trucizna, ochrona, blokada, wymuszony głos, przekazanie kart po śmierci…',
          'Karta obronna („Nie tym razem" / „Kukła") może zniwelować kartę wymierzoną w ciebie — zobaczysz to na liście zagranych kart jako „ZNIWELOWANE".',
          'Część efektów prowadzi werbalnie gospodarz (np. kolejność budzenia w nocy).',
        ]),
        _section('Zadania — Quiz', Icons.extension_rounded, [
          'Gospodarz uruchamia quiz; kto pierwszy odpowie poprawnie, wygrywa.',
          '1. miejsce: karta mocy. Kolejne miejsca: waluta (2. → 30\$, 3. → 15\$…).',
          'Pytania losują się bez powtórek.',
        ]),
        _section('Gry grupowe', Icons.groups_2_rounded, [
          'Familiada — drużynami (min. 4 osoby). Zwycięska drużyna: 3 karty mocy. Jeśli przegra drużyna z mafią — mafia i tak bierze 2 karty.',
          'Kalambury — jedna osoba pokazuje hasło, reszta zgaduje; najszybszy zdobywa punkt/kartę.',
          'Jak dobrze znasz znajomych — wszyscy wskazują jedną osobę; punkt tylko przy min. 75% zgodności grupy.',
        ]),
        _section('Licytacja i waluta', Icons.gavel_rounded, [
          'Walutę zdobywasz w zadaniach.',
          'Na licytacji przebijasz ofertę — najwyższa oferta wygrywa wystawioną kartę.',
        ]),
        _section('Dobre praktyki', Icons.tips_and_updates_rounded, [
          'Dyskutujcie, blefujcie i obserwujcie zachowania innych.',
          'Gospodarz pilnuje tempa gry i rozstrzyga wątpliwości.',
          'Przede wszystkim — dobra zabawa!',
        ]),
      ];

  List<Widget> _medievalSections() => [
        _section('Cel gry', Icons.flag_rounded, [
          'Korona wygrywa, gdy wygnani zostaną wszyscy Antagoniści (Ród Węża).',
          'Antagoniści wygrywają, gdy jest ich co najmniej tylu, ilu żywych dworzan Korony (parytet).',
          'Dziedziczka to cel obu stron — jej wygnanie oznacza natychmiastową wygraną Antagonistów, więc Korona musi jej bronić.',
          'Rycerz Bez Herbu i niezadeklarowany Podrzutek są neutralni i nie liczą się do parytetu.',
        ]),
        _section('Frakcje', Icons.groups_rounded, [
          'Antagoniści (Ród Węża) — co noc wspólnie naznaczają jedną osobę kompromitacją; wygrywają przez parytet.',
          'Korona — większość dworu; broni Dziedziczki i demaskuje Ród Węża.',
          'Neutralni — Rycerz Bez Herbu (cel: przetrwać do końca) oraz Podrzutek, dopóki się nie zadeklaruje.',
        ]),
        _section('Zasoby: Wpływy i kompromitacja', Icons.account_balance_rounded, [
          'Wpływy — dworskie złoto, osobny licznik od \$. Dają je karty i klasy (np. Wróg Publiczny +5 co fazę, Renta Dworska +5, Trubadur +15 za udaną plotkę).',
          'Kompromitacja I — tracisz prawo głosu.',
          'Kompromitacja II — dodatkowo nie możesz grać kart do końca dnia.',
          'Kompromitacja III — zostajesz trwale wygnany. Poziomy nie znikają same z upływem faz.',
        ]),
        _section('Dowody i sekrety', Icons.folder_shared_rounded, [
          'Dowód zbierają Strażniczka Tajemnic (co noc) oraz karta „Zebrane Grzechy".',
          'Trzymający może go w dowolnej chwili spalić, wymuszając szczerą odpowiedź TAK/NIE na jedno pytanie.',
          'Karta „Ostatnia Wola" kasuje wszystkie dowody przeciw tobie w chwili wygnania.',
          '„Zniszczone Dowody" usuwa jeden dowód trzymany przeciwko tobie (ale nie zdejmuje kompromitacji).',
        ]),
        _section('Klasy dworu', Icons.castle_rounded, [
          for (final c in MedievalClasses.all) '${c.name} (${_factionLabel(c.faction)}) — ${c.description}',
        ]),
        _section('Karty dworskie', Icons.auto_awesome_rounded, [
          '30 kart dworskich zamiast kart mocy — pełne opisy w „Katalog kart".',
          'Kategorie: kompromitacja i szantaż, dowody i fałszerstwa, Wpływy i skarbiec, plotki, przysięgi i sojusze, dwór i ceremonia oraz ostateczne środki.',
          'Śmiercionośne są tylko dwie: „Czara Cykuty" (truje, gdy cel ma już kompromitację — inaczej traci losową kartę) i „Skrytobójca" (nie działa na chronionego ani związanego przysięgą).',
          'Część kart narracyjnych rozstrzyga Król w panelu „Intrygi dworu".',
        ]),
        _section('Król (Gospodarz)', Icons.admin_panel_settings_rounded, [
          'Prowadzi dwór — zmienia fazy, rozdaje karty i nie należy do żadnej frakcji.',
          'W panelu „Intrygi dworu" rozstrzyga karty prowadzone ręcznie: Plotka Dworska, Kontrplotka, Fałszywy Świadek, Głos Ludu, Odroczona Audiencja, Nadzwyczajny Zjazd, Dzień Żałoby, Prawo Pierwszeństwa, List Miłosny, Skup Długów, Sfałszowany List, Tajny Pakt.',
        ]),
        _section('Przebieg rundy', Icons.timelapse_rounded, [
          'NOC — Ród Węża naznacza kompromitacją, działają klasy nocne (Strażniczka, Kanonik).',
          'DZIEŃ — debata, plotki i intrygi dworskie.',
          'GŁOSOWANIE — dwór wygania jedną osobę większością głosów.',
          'Cykl trwa, aż jedna frakcja spełni warunek zwycięstwa.',
        ]),
        _section('Głosowanie i wygnanie', Icons.how_to_vote_rounded, [
          'Odpada osoba z największą liczbą głosów; remis → dogrywka, kolejny remis → nikt.',
          'Kompromitacja odbiera prawo głosu; „Podrobiona Pieczęć" liczy głos podwójnie, a „Ślubowanie" i „Skradziona Tożsamość" zmieniają, na kogo padają głosy.',
          'Plotka Dworska, wyrok Kata i Fałszywy Świadek wystawiają cel „na wokandę".',
        ]),
        _section('Wygnanie i obserwacja', Icons.visibility_rounded, [
          'Wygnany dworzanin nie gra, ale obserwuje rozgrywkę i pisze na kanale #zmarli.',
          'Nie może głosować ani grać kart.',
        ]),
        _section('Dobre praktyki', Icons.tips_and_updates_rounded, [
          'Intryguj, zawiązuj sojusze i pilnuj reputacji — kompromitacja boli.',
          'Król pilnuje tempa gry i rozstrzyga wątpliwości.',
          'Przede wszystkim — dobra zabawa przy dworze!',
        ]),
      ];

  String _factionLabel(MedievalFaction f) => switch (f) {
        MedievalFaction.antagonisci => 'Ród Węża',
        MedievalFaction.korona => 'Korona',
        MedievalFaction.neutralny => 'Neutralny',
        MedievalFaction.niezdeklarowany => 'Podrzutek',
      };
}

/// Player-facing app for a class's unique, fully-automated night ability
/// (Mafia/Szeryf kill, Lekarz heal, Detektyw check). Mirrors how power cards
/// work: pick a target during the night, the effect resolves automatically.
class _ClassAbilityApp extends StatefulWidget {
  const _ClassAbilityApp({required this.service, required this.roomCode, required this.myPlayerId, required this.myRole, required this.isHost});
  final OnlineRoomService service;
  final String roomCode;
  final String myPlayerId;
  final MafiaRoleCardType myRole;
  final bool isHost;

  @override
  State<_ClassAbilityApp> createState() => _ClassAbilityAppState();
}

class _ClassAbilityAppState extends State<_ClassAbilityApp> {
  String? _target;

  String _kindStr(RoleAbilityKind k) => switch (k) {
        RoleAbilityKind.kill => 'kill',
        RoleAbilityKind.heal => 'heal',
        RoleAbilityKind.investigate => 'check',
        RoleAbilityKind.none => '',
      };

  IconData _roleIcon(MafiaRoleCardType r) => switch (r) {
        MafiaRoleCardType.mafia => Icons.local_fire_department_rounded,
        MafiaRoleCardType.detective => Icons.manage_search_rounded,
        MafiaRoleCardType.doctor => Icons.medical_services_rounded,
        MafiaRoleCardType.sheriff => Icons.gpp_good_rounded,
        MafiaRoleCardType.citizen => Icons.person_rounded,
        MafiaRoleCardType.host => Icons.shield_moon_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ability = roleAbilityOf(widget.myRole);
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return StreamBuilder<GameRoom?>(
      stream: widget.service.watchRoom(widget.roomCode),
      builder: (context, snap) {
        final room = snap.data;
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
          physics: const BouncingScrollPhysics(),
          children: [
            SectionHeader(title: 'Zdolność klasy', icon: Icons.bolt_rounded),
            const SizedBox(height: 12),
            MafiaPanel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_roleIcon(widget.myRole), color: const Color(0xFFFFD166), size: 22),
                  const SizedBox(width: 8),
                  Expanded(child: Text(ability.title, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 8),
                Text(ability.description, style: TextStyle(color: AppColors.white.withValues(alpha: .8), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 14),
            if (room != null) ..._body(room, ability),
          ],
        );
      },
    );
  }

  List<Widget> _body(GameRoom room, RoleAbility ability) {
    if (widget.isHost) {
      return [const _EmptyHint(text: 'Jesteś gospodarzem — prowadzisz grę, nie masz własnej zdolności.')];
    }
    if (ability.kind == RoleAbilityKind.none) {
      return [const _EmptyHint(text: 'Ta klasa nie ma nocnej zdolności. Twoja siła to dyskusja i głos za dnia.')];
    }
    final me = room.players.where((p) => p.id == widget.myPlayerId);
    if (me.isEmpty || !me.first.alive) {
      return [const _EmptyHint(text: 'Nie żyjesz — zdolność niedostępna. Obserwujesz grę.')];
    }
    final myStatuses = me.first.statuses;
    final widgets = <Widget>[];

    // Detective's private result from the previous night.
    if (ability.kind == RoleAbilityKind.investigate) {
      final res = myStatuses.firstWhere((s) => s.startsWith('checkresult:'), orElse: () => '');
      if (res.isNotEmpty) {
        final parts = res.split(':');
        final name = parts.length > 1 ? parts[1] : '?';
        final mafia = parts.length > 2 && parts[2] == 'mafia';
        final c = mafia ? const Color(0xFFE5404F) : const Color(0xFF34D399);
        widgets.add(Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: c.withValues(alpha: .16), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: .55))),
          child: Row(children: [
            Icon(mafia ? Icons.gpp_bad_rounded : Icons.verified_user_rounded, color: c),
            const SizedBox(width: 10),
            Expanded(child: Text('Wynik śledztwa: „$name" to ${mafia ? 'MAFIA' : 'nie-mafia (czysty)'}.', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, height: 1.3))),
          ]),
        ));
      }
    }

    if (room.phase != GamePhase.night) {
      widgets.add(const _EmptyHint(text: 'Zdolność działa tylko w nocy. Poczekaj, aż gospodarz włączy fazę nocy.'));
      return widgets;
    }

    final queued = myStatuses.firstWhere((s) => s.startsWith('na:'), orElse: () => '');
    final queuedTarget = queued.isEmpty ? null : queued.split(':').last;
    final includeSelf = ability.kind == RoleAbilityKind.heal;
    final candidates = room.players.where((p) => p.alive && (includeSelf || p.id != widget.myPlayerId)).map((p) => p.name).toList();

    if (queuedTarget != null) {
      widgets.add(Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFD166).withValues(alpha: .14), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: .45))),
        child: Text('Wybrano: $queuedTarget — efekt rozliczy się o świcie. Możesz jeszcze zmienić poniżej.', style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.w800, height: 1.3)),
      ));
    }
    widgets.addAll([
      _PlayerDropdown(label: 'Cel', value: _target, players: candidates, onChanged: (v) => setState(() => _target = v)),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _target == null
              ? null
              : () async {
                  await widget.service.setNightAction(code: widget.roomCode, actorId: widget.myPlayerId, kind: _kindStr(ability.kind), targetName: _target!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${ability.actionLabel}: $_target — rozliczy się o świcie.')));
                  }
                },
          icon: const Icon(Icons.check_rounded),
          label: Text(ability.actionLabel),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5404F), foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ),
    ]);
    return widgets;
  }
}

/// Medieval-edition class ability app: Emisariusz (kompromitacja), Strażniczka
/// (dowód), Skarbnik (Wpływy tax/subsidy), Podrzutek (declare faction). Others
/// are host-run. Shows the player's Wpływy / kompromitacja / dowody.
class _MedievalAbilityApp extends StatefulWidget {
  const _MedievalAbilityApp({required this.service, required this.roomCode, required this.myPlayerId, required this.isHost});
  final OnlineRoomService service;
  final String roomCode;
  final String myPlayerId;
  final bool isHost;

  @override
  State<_MedievalAbilityApp> createState() => _MedievalAbilityAppState();
}

class _MedievalAbilityAppState extends State<_MedievalAbilityApp> {
  String? _target;
  static const _gold = Color(0xFFC9A227);
  static const _burg = Color(0xFF7A1F2B);

  int _kompLevel(List<String> st) {
    if (st.contains('kompromitacja3')) return 3;
    if (st.contains('kompromitacja2')) return 2;
    if (st.contains('kompromitacja1')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return StreamBuilder<GameRoom?>(
      stream: widget.service.watchRoom(widget.roomCode),
      builder: (context, snap) {
        final room = snap.data;
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
          physics: const BouncingScrollPhysics(),
          children: [
            SectionHeader(title: 'Zdolność klasy', icon: Icons.bolt_rounded),
            const SizedBox(height: 12),
            if (widget.isHost)
              const _EmptyHint(text: 'Jesteś gospodarzem — prowadzisz dwór, nie masz własnej klasy.')
            else if (room == null)
              const _EmptyHint(text: 'Ładowanie…')
            else
              ..._body(room),
          ],
        );
      },
    );
  }

  List<Widget> _body(GameRoom room) {
    final mineList = room.players.where((p) => p.id == widget.myPlayerId).toList();
    if (mineList.isEmpty) return [const _EmptyHint(text: 'Brak Twojej postaci w pokoju.')];
    final me = mineList.first;
    final cls = me.medievalClass;
    if (cls == null) return [const _EmptyHint(text: 'Nie masz jeszcze przypisanej klasy.')];
    final def = MedievalClasses.definitionOf(cls);
    final wplywy = room.wplywy[widget.myPlayerId] ?? 0;
    final komp = _kompLevel(me.statuses);
    final dowody = me.statuses.where((s) => s.startsWith('dowod:')).length;
    final isNight = room.phase == GamePhase.night;
    final candidates = room.players.where((p) => p.alive && p.id != widget.myPlayerId).map((p) => p.name).toList();

    final widgets = <Widget>[
      MafiaPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(def.icon, color: _gold, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(def.name, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 6),
          Text(def.abilityTitle, style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 6),
          Text(def.description, style: TextStyle(color: AppColors.white.withValues(alpha: .8), fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _resChip('Wpływy', '$wplywy', _gold)),
        const SizedBox(width: 8),
        Expanded(child: _resChip('Kompromitacja', '$komp/3', _burg)),
        const SizedBox(width: 8),
        Expanded(child: _resChip('Dowody', '$dowody', const Color(0xFF6B6470))),
      ]),
      const SizedBox(height: 14),
    ];

    // Dowody you hold on others (from Strażniczka / Zebrane Grzechy) — burn to
    // force a truthful yes/no answer (asked verbally).
    final held = room.players.where((p) => p.statuses.contains('dowod:${me.name}')).toList();
    if (held.isNotEmpty) {
      widgets.add(MafiaPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Trzymasz dowody na:', style: TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 13)),
          const SizedBox(height: 8),
          for (final t in held)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(t.name, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800))),
                GestureDetector(
                  onTap: () async {
                    await widget.service.burnEvidence(code: widget.roomCode, holderName: me.name, targetPlayerId: t.id);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Spalasz dowód na ${t.name} — musi szczerze odpowiedzieć tak/nie.')));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _burg.withValues(alpha: .3), borderRadius: BorderRadius.circular(10), border: Border.all(color: _burg)),
                    child: const Text('Spal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ),
              ]),
            ),
        ]),
      ));
      widgets.add(const SizedBox(height: 14));
    }

    if (!me.alive) {
      widgets.add(const _EmptyHint(text: 'Zostałeś wygnany — obserwujesz dwór.'));
      return widgets;
    }

    switch (def.abilityKind) {
      case MedievalAbilityKind.compromise:
      case MedievalAbilityKind.evidence:
        if (!isNight) {
          widgets.add(const _EmptyHint(text: 'Ta zdolność działa w nocy. Poczekaj, aż gospodarz włączy noc.'));
          break;
        }
        final kind = def.abilityKind == MedievalAbilityKind.compromise ? 'komp' : 'dowod';
        final queued = me.statuses.firstWhere((s) => s.startsWith('na:'), orElse: () => '');
        if (queued.isNotEmpty) widgets.add(_noteBox('Wybrano: ${queued.split(':').last} — efekt rozliczy się o świcie. Możesz zmienić.'));
        widgets.addAll([
          _PlayerDropdown(label: 'Cel', value: _target, players: candidates, onChanged: (v) => setState(() => _target = v)),
          const SizedBox(height: 12),
          _actionBtn(def.abilityKind == MedievalAbilityKind.compromise ? 'Naznacz kompromitacją' : 'Zbierz dowód', () async {
            if (_target == null) return;
            await widget.service.setNightAction(code: widget.roomCode, actorId: widget.myPlayerId, kind: kind, targetName: _target!);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cel: $_target — rozliczy się o świcie.')));
          }),
        ]);
        break;
      case MedievalAbilityKind.treasury:
        widgets.addAll([
          _PlayerDropdown(label: 'Osoba', value: _target, players: candidates, onChanged: (v) => setState(() => _target = v)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _actionBtn('Opodatkuj (−10)', () => _tax(-10), color: _burg)),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Dotuj (+10)', () => _tax(10), color: const Color(0xFF2F6B4F))),
          ]),
        ]);
        break;
      case MedievalAbilityKind.declare:
        final f = me.podrzutekFaction;
        if (f != null) {
          widgets.add(_noteBox('Zadeklarowano: ${f == MedievalFaction.korona ? 'Korona' : 'Antagoniści'}. Decyzja jest nieodwołalna.'));
        } else if (room.roundNumber > 3) {
          widgets.add(const _EmptyHint(text: 'Minęły 3 tury — o Twojej stronie decyduje losowanie gospodarza.'));
        } else {
          widgets.addAll([
            Text('Masz czas do końca 3. tury (obecnie tura ${room.roundNumber}). Wybór jest NIEODWOŁALNY.', style: TextStyle(color: AppColors.white.withValues(alpha: .72), fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _actionBtn('Korona', () => _declare(MedievalFaction.korona), color: const Color(0xFF5B3A8C))),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn('Antagoniści', () => _declare(MedievalFaction.antagonisci), color: _burg)),
            ]),
          ]);
        }
        break;
      case MedievalAbilityKind.duel:
        if (me.statuses.contains('duel_used')) {
          widgets.add(const _EmptyHint(text: 'Pojedynek już wykorzystany w tej grze.'));
          break;
        }
        widgets.addAll([
          _PlayerDropdown(label: 'Przeciwnik', value: _target, players: candidates, onChanged: (v) => setState(() => _target = v)),
          const SizedBox(height: 10),
          Text('Rozstrzygnijcie pojedynek przy stole, potem zaznacz wynik. Decyzja jest NIEODWRACALNA.', style: TextStyle(color: AppColors.white.withValues(alpha: .7), fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _actionBtn('Zwyciężam', () => _duel(loserIsMe: false), color: const Color(0xFF2F6B4F))),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Ginę', () => _duel(loserIsMe: true), color: _burg)),
          ]),
        ]);
        break;
      case MedievalAbilityKind.gossip:
        final usedThisRound = me.statuses.contains('gossip_round:${room.roundNumber}');
        if (usedThisRound) {
          widgets.add(const _EmptyHint(text: 'Plotkę rzuciłeś już w tej turze. Wróć następnego dnia.'));
          break;
        }
        final gossiped = me.statuses.where((s) => s.startsWith('gossiped:')).map((s) => s.substring(9)).toSet();
        final pickable = candidates.where((n) => !gossiped.contains(n)).toList();
        if (pickable.isEmpty) {
          widgets.add(const _EmptyHint(text: 'Oplotkowałeś już wszystkich — nie można powtórzyć celu.'));
          break;
        }
        widgets.addAll([
          _PlayerDropdown(label: 'Kogo oplotkować', value: pickable.contains(_target) ? _target : null, players: pickable, onChanged: (v) => setState(() => _target = v)),
          const SizedBox(height: 10),
          Text('Cel trafia na listę głosowania i mówi pierwszy. +15 Wpływów, jeśli zostanie wygnany w najbliższym głosowaniu. Tej samej osoby nie można oplotkować dwa razy.', style: TextStyle(color: AppColors.white.withValues(alpha: .7), fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 12),
          _actionBtn('Rozpuść plotkę', _gossip, color: const Color(0xFF7C6A9C)),
        ]);
        break;
      case MedievalAbilityKind.sentence:
        final lastSentence = me.statuses
            .where((s) => s.startsWith('sentence_round:'))
            .map((s) => int.tryParse(s.substring(15)) ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b);
        if (lastSentence > 0 && room.roundNumber - lastSentence < 2) {
          widgets.add(_EmptyHint(text: 'Wyrok wydajesz raz na dwie tury. Następny dostępny w turze ${lastSentence + 2}.'));
          break;
        }
        widgets.addAll([
          _PlayerDropdown(label: 'Skazany', value: candidates.contains(_target) ? _target : null, players: candidates, onChanged: (v) => setState(() => _target = v)),
          const SizedBox(height: 10),
          Text('Skazany trafia pod wyrok (na listę głosowania). Wyrok zostaje wykonany, chyba że zwykła większość ułaskawi — głos ułaskawienia prowadzi gospodarz. Jeśli skażesz lojalistę, trwale tracisz moc.', style: TextStyle(color: AppColors.white.withValues(alpha: .7), fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 12),
          _actionBtn('Wydaj wyrok', _sentence, color: const Color(0xFF3A2A1A)),
        ]);
        break;
      case MedievalAbilityKind.confess:
        if (!isNight) {
          widgets.add(const _EmptyHint(text: 'Spowiedzi wysłuchujesz w nocy. Poczekaj, aż gospodarz włączy noc.'));
          break;
        }
        if (me.statuses.contains('confess_round:${room.roundNumber}')) {
          widgets.add(const _EmptyHint(text: 'Spowiedź na tę noc już przyjęta.'));
          break;
        }
        widgets.addAll([
          _PlayerDropdown(label: 'Kogo wezwać na spowiedź', value: candidates.contains(_target) ? _target : null, players: candidates, onChanged: (v) => setState(() => _target = v)),
          const SizedBox(height: 10),
          Text('Cel zostaje anonimowo wezwany na spowiedź i musi szczerze odpowiedzieć TAK/NIE na jedno pytanie — zadaj je werbalnie lub na priv. Nie zdradzaj publicznie treści spowiedzi, bo trwale stracisz moc.', style: TextStyle(color: AppColors.white.withValues(alpha: .7), fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 12),
          _actionBtn('Wezwij na spowiedź', _confess, color: const Color(0xFF4B3621)),
        ]);
        break;
      case MedievalAbilityKind.none:
        widgets.add(const _EmptyHint(text: 'Twoja siła jest bierna — działa sama, zgodnie z opisem klasy powyżej.'));
    }
    return widgets;
  }

  Future<void> _gossip() async {
    if (_target == null) return;
    await widget.service.gossip(code: widget.roomCode, actorId: widget.myPlayerId, targetName: _target!);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plotka rozpuszczona: $_target trafia na listę głosowania.')));
  }

  Future<void> _sentence() async {
    if (_target == null) return;
    await widget.service.sentence(code: widget.roomCode, actorId: widget.myPlayerId, targetName: _target!);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wyrok wydany na $_target — potrzeba większości, by ułaskawić.')));
  }

  Future<void> _confess() async {
    if (_target == null) return;
    await widget.service.confess(code: widget.roomCode, actorId: widget.myPlayerId, targetName: _target!);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_target wezwany na spowiedź — musi szczerze odpowiedzieć tak/nie.')));
  }

  Future<void> _duel({required bool loserIsMe}) async {
    if (_target == null) return;
    final room = await widget.service.getRoom(widget.roomCode);
    final opp = room?.players.where((p) => p.name == _target).toList() ?? const [];
    if (opp.isEmpty) return;
    final loserId = loserIsMe ? widget.myPlayerId : opp.first.id;
    await widget.service.duel(code: widget.roomCode, knightId: widget.myPlayerId, loserId: loserId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loserIsMe ? 'Poległeś w pojedynku.' : '$_target poległ w pojedynku.')));
  }

  Future<void> _tax(int amount) async {
    if (_target == null) return;
    final room = await widget.service.getRoom(widget.roomCode);
    final t = room?.players.where((p) => p.name == _target).toList() ?? const [];
    if (t.isEmpty) return;
    await widget.service.awardInfluence(code: widget.roomCode, playerId: t.first.id, amount: amount);
    await widget.service.awardInfluence(code: widget.roomCode, playerId: widget.myPlayerId, amount: -amount);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${amount < 0 ? 'Opodatkowano' : 'Dotowano'}: $_target')));
  }

  Future<void> _declare(MedievalFaction f) async {
    await widget.service.declarePodrzutek(code: widget.roomCode, playerId: widget.myPlayerId, faction: f);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Zadeklarowano: ${f == MedievalFaction.korona ? 'Korona' : 'Antagoniści'}')));
  }

  Widget _resChip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .5))),
        child: Column(children: [
          Text(value, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _noteBox(String text) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _gold.withValues(alpha: .14), borderRadius: BorderRadius.circular(14), border: Border.all(color: _gold.withValues(alpha: .45))),
        child: Text(text, style: const TextStyle(color: _gold, fontWeight: FontWeight.w800, height: 1.3)),
      );

  Widget _actionBtn(String text, VoidCallback onTap, {Color color = const Color(0xFF7A1F2B)}) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text(text),
        ),
      );
}

/// Host-only medieval console for the narrative cards the game master runs by
/// hand (Plotka Dworska, Kontrplotka, Fałszywy Świadek, Głos Ludu, Odroczona
/// Audiencja, Nadzwyczajny Zjazd, Dzień Żałoby, Prawo Pierwszeństwa, List
/// Miłosny, Skup Długów, Sfałszowany List, Tajny Pakt). Each entry applies a
/// safe mechanical primitive and, where sensible, broadcasts an anonymous
/// herald announcement to the general channel.
class _MedievalHostPanel extends StatefulWidget {
  const _MedievalHostPanel({required this.service, required this.roomCode});
  final OnlineRoomService service;
  final String roomCode;

  @override
  State<_MedievalHostPanel> createState() => _MedievalHostPanelState();
}

class _MedievalHostPanelState extends State<_MedievalHostPanel> {
  final Map<String, String?> _sel = {};
  final TextEditingController _gossipCtl = TextEditingController();
  final TextEditingController _orderCtl = TextEditingController();
  final TextEditingController _amountCtl = TextEditingController();

  static const _gold = Color(0xFFC9A227);
  static const _plum = Color(0xFF7C6A9C);
  static const _royal = Color(0xFF5B3A8C);
  static const _green = Color(0xFF2F6B4F);
  static const _burg = Color(0xFF7A1F2B);

  @override
  void dispose() {
    _gossipCtl.dispose();
    _orderCtl.dispose();
    _amountCtl.dispose();
    super.dispose();
  }

  Future<void> _announce(String text) =>
      widget.service.sendMessage(code: widget.roomCode, channelId: 'general', senderName: '👑 Herold dworu', text: text);

  void _toast(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String? _idOf(GameRoom room, String? name) {
    if (name == null) return null;
    final m = room.players.where((p) => p.name == name).toList();
    return m.isEmpty ? null : m.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return StreamBuilder<GameRoom?>(
      stream: widget.service.watchRoom(widget.roomCode),
      builder: (context, snap) {
        final room = snap.data;
        if (room == null) {
          return const Center(child: _EmptyHint(text: 'Ładowanie…'));
        }
        final names = room.players.where((p) => p.alive).map((p) => p.name).toList();
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
          physics: const BouncingScrollPhysics(),
          children: [
            SectionHeader(title: 'Intrygi dworu', icon: Icons.castle_rounded),
            const SizedBox(height: 8),
            Text(
              'Rozstrzygaj karty prowadzone przez gospodarza. Akcja stosuje efekt mechaniczny i — gdzie to zasadne — ogłasza go anonimowo na kanale ogólnym jako Herold.',
              style: TextStyle(color: AppColors.white.withValues(alpha: .66), fontSize: 13, fontWeight: FontWeight.w600, height: 1.35),
            ),
            const SizedBox(height: 14),
            _plotka(room, names),
            _kontrplotka(room, names),
            _swiadek(room, names),
            _glosLudu(),
            _audiencja(),
            _zjazd(),
            _zaloba(),
            _pierwszenstwo(),
            _listMilosny(room, names),
            _skupDlugow(room, names),
            _sfalszowany(names),
            _tajnyPakt(names),
          ],
        );
      },
    );
  }

  // ---- reusable pieces ------------------------------------------------------

  Widget _tile({required IconData icon, required Color color, required String title, required String desc, required List<Widget> controls}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MafiaPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: AppColors.white.withValues(alpha: .72), fontSize: 13, fontWeight: FontWeight.w600, height: 1.35)),
          const SizedBox(height: 12),
          ...controls,
        ]),
      ),
    );
  }

  Widget _drop(String key, String label, List<String> names) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _PlayerDropdown(label: label, value: names.contains(_sel[key]) ? _sel[key] : null, players: names, onChanged: (v) => setState(() => _sel[key] = v)),
      );

  Widget _field(TextEditingController c, String hint, {TextInputType? kb}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: c,
          keyboardType: kb,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.white.withValues(alpha: .4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: .08),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: .14))),
          ),
        ),
      );

  Widget _btn(String text, VoidCallback onTap, Color color) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text(text),
        ),
      );

  // ---- individual intrigues -------------------------------------------------

  Widget _plotka(GameRoom room, List<String> names) => _tile(
        icon: Icons.campaign_rounded,
        color: _plum,
        title: 'Plotka Dworska',
        desc: 'Cel trafia pod głosowanie i mówi pierwszy. Jeśli jest chroniony Kontrplotką, skutek zostaje skasowany.',
        controls: [
          _drop('plotka', 'Cel plotki', names),
          _field(_gossipCtl, 'Treść plotki (opcjonalnie, ogłoszona anonimowo)'),
          _btn('Ogłoś plotkę', () => _applyPlotka(room), _plum),
        ],
      );

  Future<void> _applyPlotka(GameRoom room) async {
    final name = _sel['plotka'];
    final id = _idOf(room, name);
    if (id == null) {
      _toast('Wybierz cel plotki.');
      return;
    }
    final target = room.players.firstWhere((p) => p.id == id);
    if (target.statuses.contains('plotka_shield')) {
      await widget.service.removeStatus(code: widget.roomCode, playerId: id, status: 'plotka_shield');
      await _announce('Plotka o $name rozpłynęła się bez echa — ktoś ją wyprzedził (Kontrplotka).');
      _toast('$name był chroniony Kontrplotką — plotka skasowana.');
      return;
    }
    await widget.service.markStatus(code: widget.roomCode, playerId: id, status: 'onballot');
    final gossip = _gossipCtl.text.trim();
    await _announce('🗣️ Plotka dworska: $name trafia pod głosowanie i mówi pierwszy.${gossip.isEmpty ? '' : ' „$gossip”'}');
    _toast('Plotka ogłoszona: $name na wokandzie.');
    _gossipCtl.clear();
  }

  Widget _kontrplotka(GameRoom room, List<String> names) => _tile(
        icon: Icons.block_rounded,
        color: _plum,
        title: 'Kontrplotka',
        desc: 'Chroni wskazaną osobę: najbliższa Plotka Dworska rzucona na nią zostanie skasowana.',
        controls: [
          _drop('kontra', 'Chroniona osoba', names),
          _btn('Załóż ochronę', () => _applyKontrplotka(room), _plum),
        ],
      );

  Future<void> _applyKontrplotka(GameRoom room) async {
    final id = _idOf(room, _sel['kontra']);
    if (id == null) {
      _toast('Wybierz osobę do ochrony.');
      return;
    }
    await widget.service.markStatus(code: widget.roomCode, playerId: id, status: 'plotka_shield');
    _toast('${_sel['kontra']} chroniony przed najbliższą Plotką Dworską.');
  }

  Widget _swiadek(GameRoom room, List<String> names) => _tile(
        icon: Icons.record_voice_over_rounded,
        color: _burg,
        title: 'Fałszywy Świadek',
        desc: 'Pierwsza osoba musi publicznie oskarżyć drugą. Oskarżony trafia pod głosowanie.',
        controls: [
          _drop('swiadekA', 'Oskarżyciel', names),
          _drop('swiadekB', 'Oskarżony', names),
          _btn('Ogłoś oskarżenie', () => _applySwiadek(room), _burg),
        ],
      );

  Future<void> _applySwiadek(GameRoom room) async {
    final a = _sel['swiadekA'];
    final b = _sel['swiadekB'];
    if (a == null || b == null || a == b) {
      _toast('Wybierz dwie różne osoby.');
      return;
    }
    final idB = _idOf(room, b);
    if (idB != null) await widget.service.markStatus(code: widget.roomCode, playerId: idB, status: 'onballot');
    await _announce('⚖️ Fałszywy świadek: $a musi dziś publicznie oskarżyć $b. $b trafia pod głosowanie.');
    _toast('Ogłoszono: $a oskarża $b.');
  }

  Widget _glosLudu() => _tile(
        icon: Icons.groups_rounded,
        color: _plum,
        title: 'Głos Ludu',
        desc: 'Ujawnij, kto aktualnie prowadzi w sondażu głosów, zanim padnie oficjalny wynik.',
        controls: [
          StreamBuilder<VoteSession?>(
            stream: widget.service.watchVote(widget.roomCode),
            builder: (context, vs) {
              final vote = vs.data;
              if (vote == null || vote.state != VoteState.open || vote.tally.isEmpty) {
                return const _EmptyHint(text: 'Brak aktywnego głosowania z oddanymi głosami.');
              }
              final entries = vote.tally.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              final leader = entries.first;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Prowadzi: ${leader.key} (${leader.value} gł.)', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 10),
                _btn('Ogłoś prowadzącego', () => _announceLeader(leader.key, leader.value), _plum),
              ]);
            },
          ),
        ],
      );

  Future<void> _announceLeader(String name, int votes) async {
    await _announce('📣 Głos Ludu: w sondażu prowadzi $name ($votes gł.).');
    _toast('Ogłoszono prowadzącego.');
  }

  Widget _audiencja() => _tile(
        icon: Icons.schedule_rounded,
        color: _royal,
        title: 'Odroczona Audiencja',
        desc: 'Kasuje trwające głosowanie i przesuwa je o turę.',
        controls: [_btn('Odrocz głosowanie', _applyAudiencja, _royal)],
      );

  Future<void> _applyAudiencja() async {
    await widget.service.clearVote(widget.roomCode);
    await _announce('⏳ Odroczona Audiencja: najbliższe głosowanie zostaje przesunięte.');
    _toast('Głosowanie odroczone.');
  }

  Widget _zjazd() => _tile(
        icon: Icons.event_repeat_rounded,
        color: _royal,
        title: 'Nadzwyczajny Zjazd',
        desc: 'Zwołuje dodatkowe, nieplanowane głosowanie od zaraz.',
        controls: [_btn('Zwołaj głosowanie', _applyZjazd, _royal)],
      );

  Future<void> _applyZjazd() async {
    await widget.service.startVote(widget.roomCode);
    await _announce('🔔 Nadzwyczajny Zjazd: zwołano dodatkowe głosowanie!');
    _toast('Rozpoczęto nadzwyczajne głosowanie.');
  }

  Widget _zaloba() => _tile(
        icon: Icons.dark_mode_rounded,
        color: _royal,
        title: 'Dzień Żałoby',
        desc: 'Ogłasza pominięcie najbliższej nocy — utrzymaj fazę dzienną, kart nocnych nie używa się.',
        controls: [_btn('Ogłoś Dzień Żałoby', _applyZaloba, _royal)],
      );

  Future<void> _applyZaloba() async {
    await _announce('🌑 Dzień Żałoby: najbliższa noc zostaje pominięta — kart nocnych nie używa się.');
    _toast('Ogłoszono Dzień Żałoby (utrzymaj fazę dzienną).');
  }

  Widget _pierwszenstwo() => _tile(
        icon: Icons.format_list_numbered_rounded,
        color: _royal,
        title: 'Prawo Pierwszeństwa',
        desc: 'Ogłasza ustaloną kolejność zabierania głosu w debacie.',
        controls: [
          _field(_orderCtl, 'Kolejność, np. Ala → Ola → Jan'),
          _btn('Ogłoś kolejność', _applyPierwszenstwo, _royal),
        ],
      );

  Future<void> _applyPierwszenstwo() async {
    final order = _orderCtl.text.trim();
    if (order.isEmpty) {
      _toast('Wpisz kolejność.');
      return;
    }
    await _announce('📜 Prawo Pierwszeństwa — kolejność głosu w debacie: $order');
    _toast('Kolejność ogłoszona.');
    _orderCtl.clear();
  }

  Widget _listMilosny(GameRoom room, List<String> names) => _tile(
        icon: Icons.mail_rounded,
        color: _burg,
        title: 'List Miłosny',
        desc: 'Cel oddaje kartę (zabierz ją ręcznie) albo zostaje jawnie oskarżony i trafia pod głosowanie.',
        controls: [
          _drop('list', 'Cel', names),
          Row(children: [
            Expanded(child: _btn('Oddał kartę', _listGaveCard, _green)),
            const SizedBox(width: 10),
            Expanded(child: _btn('Oskarżony', () => _applyListOskarz(room), _burg)),
          ]),
        ],
      );

  void _listGaveCard() => _toast('Zabierz jedną kartę z ręki celu (panel rozdania). List spełniony.');

  Future<void> _applyListOskarz(GameRoom room) async {
    final id = _idOf(room, _sel['list']);
    if (id == null) {
      _toast('Wybierz cel.');
      return;
    }
    await widget.service.markStatus(code: widget.roomCode, playerId: id, status: 'onballot');
    await _announce('💌 List miłosny: ${_sel['list']} odmówił(a) — zostaje jawnie oskarżony i trafia pod głosowanie.');
    _toast('${_sel['list']} oskarżony.');
  }

  Widget _skupDlugow(GameRoom room, List<String> names) => _tile(
        icon: Icons.receipt_long_rounded,
        color: _gold,
        title: 'Skup Długów',
        desc: 'Przenosi Wpływy od dłużnika do wierzyciela (użyj, gdy dłużnikowi wpływa zysk z zadania).',
        controls: [
          _drop('debtor', 'Dłużnik (traci)', names),
          _drop('creditor', 'Wierzyciel (zyskuje)', names),
          _field(_amountCtl, 'Kwota Wpływów', kb: TextInputType.number),
          _btn('Przekaż Wpływy', () => _applySkup(room), _gold),
        ],
      );

  Future<void> _applySkup(GameRoom room) async {
    final dId = _idOf(room, _sel['debtor']);
    final cId = _idOf(room, _sel['creditor']);
    final amt = int.tryParse(_amountCtl.text.trim()) ?? 0;
    if (dId == null || cId == null || dId == cId || amt <= 0) {
      _toast('Wybierz dłużnika, wierzyciela i dodatnią kwotę.');
      return;
    }
    await widget.service.awardInfluence(code: widget.roomCode, playerId: dId, amount: -amt);
    await widget.service.awardInfluence(code: widget.roomCode, playerId: cId, amount: amt);
    await _announce('🧾 Skup długów: $amt Wpływów przechodzi od ${_sel['debtor']} do ${_sel['creditor']}.');
    _toast('Przekazano $amt Wpływów.');
    _amountCtl.clear();
  }

  Widget _sfalszowany(List<String> names) => _tile(
        icon: Icons.edit_note_rounded,
        color: const Color(0xFF3B3540),
        title: 'Sfałszowany List',
        desc: 'Przekierowanie wrogiego efektu: ogłoś zmianę celu, a następnie zastosuj efekt na nowej osobie.',
        controls: [
          _drop('redirFrom', 'Pierwotny cel', names),
          _drop('redirTo', 'Nowy cel', names),
          _btn('Ogłoś przekierowanie', _applySfalszowany, const Color(0xFF3B3540)),
        ],
      );

  Future<void> _applySfalszowany() async {
    final from = _sel['redirFrom'];
    final to = _sel['redirTo'];
    if (from == null || to == null || from == to) {
      _toast('Wybierz dwie różne osoby.');
      return;
    }
    await _announce('✒️ Sfałszowany list: efekt wymierzony w $from zostaje przekierowany na $to.');
    _toast('Przekierowano — zastosuj efekt na $to.');
  }

  Widget _tajnyPakt(List<String> names) => _tile(
        icon: Icons.handshake_rounded,
        color: _green,
        title: 'Tajny Pakt',
        desc: 'Dwie osoby pokazują sobie po jednej karcie — potajemnie, bez ogłaszania nikomu innemu.',
        controls: [
          _drop('paktA', 'Pierwsza osoba', names),
          _drop('paktB', 'Druga osoba', names),
          _btn('Zainicjuj wymianę', _applyPakt, _green),
        ],
      );

  void _applyPakt() {
    final a = _sel['paktA'];
    final b = _sel['paktB'];
    if (a == null || b == null || a == b) {
      _toast('Wybierz dwie różne osoby.');
      return;
    }
    _toast('$a i $b: pokażcie sobie po jednej karcie (bez ujawniania innym).');
  }
}

class _SamsungNotesApp extends StatefulWidget {
  const _SamsungNotesApp({required this.initialText, required this.onChanged});
  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_SamsungNotesApp> createState() => _SamsungNotesAppState();
}

class _SamsungNotesAppState extends State<_SamsungNotesApp> {
  late final TextEditingController controller;
  late final TextEditingController titleController;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
    titleController = TextEditingController(text: 'Notatka z gry');
    controller.addListener(() => widget.onChanged(controller.text));
  }

  @override
  void dispose() {
    controller.dispose();
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      color: const Color(0xFFF6E7B8),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(color: const Color(0xFFFFF3C4), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 12, offset: const Offset(0, 4))]),
          child: Row(children: [
            const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF4A2C00)),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: titleController, autocorrect: false, enableSuggestions: false, style: const TextStyle(color: Color(0xFF2A1800), fontSize: 20, fontWeight: FontWeight.w900), decoration: const InputDecoration(border: InputBorder.none, isDense: true))),
            IconButton(onPressed: () { controller.clear(); HapticFeedback.selectionClick(); }, icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF4A2C00))),
          ]),
        ),
        Expanded(
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _NoteLinesPainter())),
            TextField(
              controller: controller,
              expands: true,
              maxLines: null,
              minLines: null,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: Color(0xFF2A1800), fontSize: 18, fontWeight: FontWeight.w600, height: 1.55),
              decoration: InputDecoration(contentPadding: EdgeInsets.fromLTRB(20, 20, 20, 28 + bottom), border: InputBorder.none, hintText: 'Zapisz podejrzenia, alibi, kolejność nocy...', hintStyle: TextStyle(color: const Color(0xFF2A1800).withValues(alpha: .38), fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _NoteLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFB98B2E).withValues(alpha: .22)..strokeWidth = 1;
    for (double y = 58; y < size.height; y += 31) {
      canvas.drawLine(Offset(16, y), Offset(size.width - 16, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IOSGlass(opacity: .08, padding: const EdgeInsets.all(16), child: Text(text, style: TextStyle(color: AppColors.white.withValues(alpha: .70), fontWeight: FontWeight.w800, height: 1.35)));
  }
}


class _DealCardButton extends StatelessWidget {
  const _DealCardButton({required this.room, required this.onDealCard});
  final GameRoom room;
  final void Function(String playerId, String cardId)? onDealCard;

  @override
  Widget build(BuildContext context) {
    return LockButton(
      text: 'Rozdaj kartę graczowi',
      icon: Icons.card_giftcard_rounded,
      onTap: () async {
        final result = await showModalBottomSheet<({String playerId, String cardId})>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _DealCardSheet(room: room),
        );
        if (result == null) return;
        onDealCard?.call(result.playerId, result.cardId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Karta rozdana.')));
        }
      },
    );
  }
}

class _DealCardSheet extends StatefulWidget {
  const _DealCardSheet({required this.room});
  final GameRoom room;

  @override
  State<_DealCardSheet> createState() => _DealCardSheetState();
}

class _DealCardSheetState extends State<_DealCardSheet> {
  String? playerId;
  String? cardId;

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.white.withValues(alpha: .68)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .14))),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom;
    final participants = <({String id, String name})>[
      (id: widget.room.hostId, name: '${widget.room.hostName} (gospodarz)'),
      ...widget.room.players.map((p) => (id: p.id, name: p.name)),
    ];
    final canDeal = playerId != null && cardId != null;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
        decoration: const BoxDecoration(color: Color(0xFF120505), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          const Text('Rozdaj kartę mocy', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: playerId,
            isExpanded: true,
            items: participants.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (value) => setState(() => playerId = value),
            dropdownColor: const Color(0xFF220808),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
            decoration: _deco('Gracz'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: cardId,
            isExpanded: true,
            items: cardsFor(activeEdition).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (value) => setState(() => cardId = value),
            dropdownColor: const Color(0xFF220808),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
            decoration: _deco('Karta mocy'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canDeal ? () => Navigator.pop(context, (playerId: playerId!, cardId: cardId!)) : null,
              icon: const Icon(Icons.card_giftcard_rounded),
              label: const Text('Przydziel'),
              style: ElevatedButton.styleFrom(backgroundColor: kOneAccent, foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    );
  }
}


class _TasksApp extends StatefulWidget {
  const _TasksApp({required this.service, required this.roomCode, required this.isHost, required this.myPlayerId, required this.room});
  final OnlineRoomService service;
  final String roomCode;
  final bool isHost;
  final String myPlayerId;
  final GameRoom room;

  @override
  State<_TasksApp> createState() => _TasksAppState();
}

class _TasksAppState extends State<_TasksApp> {
  Map<String, String> get _nameById => {
        widget.room.hostId: widget.room.hostName,
        for (final p in widget.room.players) p.id: p.name,
      };

  Future<void> _newTask() async {
    final prizeCardId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewTaskSheet(),
    );
    if (prizeCardId == null) return;
    final q = drawQuizQuestion(); // fresh, non-repeating question each round
    final task = GameTask(
      state: GameTaskState.waiting,
      prizeCardId: prizeCardId,
      question: q.question,
      options: q.options,
      correctIndex: q.correctIndex,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await widget.service.createTask(code: widget.roomCode, task: task);
  }

  Future<void> _start() => widget.service.startTask(code: widget.roomCode);

  Future<void> _resolve() => widget.service.resolveTask(code: widget.roomCode, nameById: _nameById);
  Future<void> _clear() => widget.service.clearTask(widget.roomCode);
  // Host is Game Master only — never a task participant.
  bool get _amAlive => !widget.isHost && widget.room.players.any((p) => p.id == widget.myPlayerId && p.alive);

  Future<void> _submitQuiz(int index) async {
    if (!_amAlive) return;
    await widget.service.submitTask(code: widget.roomCode, playerId: widget.myPlayerId, value: index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return StreamBuilder<GameTask?>(
      stream: widget.service.watchTask(widget.roomCode),
      builder: (context, snapshot) {
        final task = snapshot.data;
        return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
          physics: const BouncingScrollPhysics(),
          children: [
            SectionHeader(title: 'Zadania o kartę', icon: Icons.emoji_events_rounded),
            const SizedBox(height: 6),
            Text('1. miejsce wygrywa kartę mocy, reszta dostaje kasę (2. → 30\$, 3. → 15\$…).', style: TextStyle(color: AppColors.white.withValues(alpha: .60), fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 16),
            if (task == null)
              ..._buildNoTask()
            else if (task.state == GameTaskState.waiting)
              ..._buildWaiting(task)
            else if (task.state == GameTaskState.active)
              ..._buildActive(task)
            else
              ..._buildFinished(task),
          ],
        );
      },
    );
  }

  List<Widget> _buildNoTask() {
    if (!widget.isHost) {
      return const [_EmptyHint(text: 'Brak aktywnego zadania. Poczekaj, aż gospodarz je uruchomi.')];
    }
    return [
      LockButton(text: 'Nowe zadanie: Quiz', icon: Icons.quiz_rounded, light: true, onTap: _newTask),
    ];
  }

  List<Widget> _buildWaiting(GameTask task) {
    if (!widget.isHost) {
      return [
        IOSGlass(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Zaraz startuje', style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(task.typeLabel, style: const TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Przygotuj się! Szczegóły zobaczysz po starcie.', style: TextStyle(color: kOneDim, fontWeight: FontWeight.w700)),
          ]),
        ),
      ];
    }
    return [
      IOSGlass(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.typeLabel, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Nagroda: ${PowerCards.byId(task.prizeCardId).name}', style: const TextStyle(color: kOneDim, fontWeight: FontWeight.w700)),
          if (task.question != null) ...[
            const SizedBox(height: 6),
            Text('Pytanie: ${task.question}', style: const TextStyle(color: kOneDim, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      LockButton(text: 'Start', icon: Icons.play_arrow_rounded, light: true, onTap: _start),
    ];
  }

  List<Widget> _buildActive(GameTask task) {
    // Host is Game Master only — monitors the task, never plays it.
    if (widget.isHost) {
      return [
        IOSGlass(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Zadanie w toku — ${task.typeLabel}', style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            if (task.question != null) ...[
              const SizedBox(height: 8),
              Text(task.question!, style: const TextStyle(color: kOneDim, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 6),
            Text('Nagroda: ${PowerCards.byId(task.prizeCardId).name}', style: const TextStyle(color: kOneDim, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 16),
        StreamBuilder<int>(
          stream: widget.service.watchSubmissionCount(widget.roomCode),
          builder: (context, snap) => Text('Wykonało: ${snap.data ?? 0} / ${widget.room.players.length}', style: const TextStyle(color: kOneDim, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        LockButton(text: 'Zakończ i rozlicz', icon: Icons.flag_rounded, light: true, onTap: _resolve),
      ];
    }
    return [
      _QuizPlayerView(key: ValueKey('quiz-${task.question}'), question: task.question ?? '', options: task.options, correctIndex: task.correctIndex ?? -1, onAnswer: _submitQuiz),
    ];
  }

  List<Widget> _buildFinished(GameTask task) {
    return [
      IOSGlass(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD166)),
            const SizedBox(width: 8),
            Expanded(child: Text(task.winnerName != null ? 'Wygrywa: ${task.winnerName}' : 'Wyniki', style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 12),
          if (task.resultLines.isEmpty)
            const Text('Brak zgłoszeń w tej rundzie.', style: TextStyle(color: kOneDim, fontWeight: FontWeight.w700))
          else
            ...task.resultLines.map((l) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(l, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)))),
        ]),
      ),
      const SizedBox(height: 14),
      if (widget.isHost)
        LockButton(text: 'Nowe zadanie', icon: Icons.refresh_rounded, light: true, onTap: _clear)
      else
        const _EmptyHint(text: 'Czekaj na kolejne zadanie od gospodarza.'),
    ];
  }
}

class _QuizPlayerView extends StatefulWidget {
  const _QuizPlayerView({super.key, required this.question, required this.options, required this.correctIndex, required this.onAnswer});
  final String question;
  final List<String> options;
  final int correctIndex;
  final Future<void> Function(int) onAnswer;

  @override
  State<_QuizPlayerView> createState() => _QuizPlayerViewState();
}

class _QuizPlayerViewState extends State<_QuizPlayerView> {
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final answered = _picked != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      IOSGlass(padding: const EdgeInsets.all(16), child: Text(widget.question, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w800))),
      const SizedBox(height: 12),
      for (var i = 0; i < widget.options.length; i++) ...[
        _QuizOption(
          text: widget.options[i],
          selected: _picked == i,
          enabled: !answered,
          // 0 = neutral, 1 = correct (green), -1 = wrong pick (red)
          result: !answered ? 0 : (i == widget.correctIndex ? 1 : (i == _picked ? -1 : 0)),
          onTap: () {
            setState(() => _picked = i);
            widget.onAnswer(i);
          },
        ),
        const SizedBox(height: 10),
      ],
      if (answered)
        Text(
          _picked == widget.correctIndex ? 'Dobrze! ✅' : 'Źle ❌ — poprawna odpowiedź jest na zielono.',
          style: TextStyle(color: _picked == widget.correctIndex ? const Color(0xFF34D399) : const Color(0xFFEF4444), fontWeight: FontWeight.w800),
        ),
    ]);
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({required this.text, required this.selected, required this.enabled, required this.result, required this.onTap});
  final String text;
  final bool selected;
  final bool enabled;
  final int result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF34D399);
    const red = Color(0xFFEF4444);
    final bg = result == 1 ? green : (result == -1 ? red : (selected ? kOneAccent : kOneSurfaceHigh));
    return PressableScale(
      onTap: enabled ? onTap : () {},
      haptic: HapticFeedbackType.selection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: result == 0 && !selected ? kOneStroke : bg),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
            if (result == 1) const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            if (result == -1) const Icon(Icons.close_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Prize picker for a new Quiz round. Returns the chosen prize card id (or a
/// random one). The question itself is drawn automatically (non-repeating).
class _NewTaskSheet extends StatefulWidget {
  const _NewTaskSheet();

  @override
  State<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<_NewTaskSheet> {
  String? prizeCardId = '__random__';

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.white.withValues(alpha: .68)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .14))),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
        decoration: const BoxDecoration(color: Color(0xFF120505), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          const Text('Nowe zadanie: Quiz', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Pytanie zostanie wylosowane automatycznie (bez powtórek).', style: TextStyle(color: AppColors.white.withValues(alpha: .6), fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: prizeCardId,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: '__random__', child: Text('🎲 Losowa karta')),
              ...PowerCards.all.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (value) => setState(() => prizeCardId = value),
            dropdownColor: const Color(0xFF220808),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
            decoration: _deco('Nagroda (karta mocy)'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: prizeCardId == null
                  ? null
                  : () => Navigator.pop(
                        context,
                        prizeCardId == '__random__' ? (PowerCards.all.toList()..shuffle()).first.id : prizeCardId!,
                      ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Utwórz'),
              style: ElevatedButton.styleFrom(backgroundColor: kOneAccent, foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    );
  }
}


class _AuctionApp extends StatefulWidget {
  const _AuctionApp({required this.service, required this.roomCode, required this.isHost, required this.myPlayerId, required this.room});
  final OnlineRoomService service;
  final String roomCode;
  final bool isHost;
  final String myPlayerId;
  final GameRoom room;

  @override
  State<_AuctionApp> createState() => _AuctionAppState();
}

class _AuctionAppState extends State<_AuctionApp> {
  GameRoom? _liveRoom;
  GameRoom get _room => _liveRoom ?? widget.room;
  Map<String, String> get _nameById => {
        _room.hostId: _room.hostName,
        for (final p in _room.players) p.id: p.name,
      };
  int get _balance => _room.wallets[widget.myPlayerId] ?? 0;

  Future<void> _start() async {
    final cardId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _StartAuctionSheet(),
    );
    if (cardId == null) return;
    await widget.service.startAuction(code: widget.roomCode, cardId: cardId);
  }

  Future<void> _bid(int amount) async {
    try {
      await widget.service.placeBid(code: widget.roomCode, playerId: widget.myPlayerId, amount: amount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  Future<void> _close() => widget.service.closeAuction(code: widget.roomCode, nameById: _nameById);
  Future<void> _clear() => widget.service.clearAuction(widget.roomCode);

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    return StreamBuilder<GameRoom?>(
      stream: widget.service.watchRoom(widget.roomCode),
      builder: (context, roomSnap) {
        _liveRoom = roomSnap.data ?? _liveRoom;
        return StreamBuilder<Auction?>(
          stream: widget.service.watchAuction(widget.roomCode),
          builder: (context, snapshot) {
            final auction = snapshot.data;
            return ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomSafe),
          physics: const BouncingScrollPhysics(),
          children: [
            SectionHeader(title: 'Licytacja kart', icon: Icons.gavel_rounded),
            const SizedBox(height: 6),
            Text('Wystaw kartę i licytuj walutą — wygrywa najwyższa oferta.', style: TextStyle(color: AppColors.white.withValues(alpha: .60), fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 12),
            if (!widget.isHost)
              Row(children: [
                const Icon(Icons.payments_rounded, color: kOneAccent, size: 18),
                const SizedBox(width: 6),
                Text('Twoje saldo: $_balance\$', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900)),
              ])
            else
              Row(children: [
                const Icon(Icons.admin_panel_settings_rounded, color: kOneAccent, size: 18),
                const SizedBox(width: 6),
                Text('Prowadzisz licytację (gospodarz)', style: TextStyle(color: AppColors.white.withValues(alpha: .8), fontWeight: FontWeight.w900)),
              ]),
            const SizedBox(height: 16),
            if (auction == null)
              ..._buildNone()
            else if (auction.isOpen)
              ..._buildOpen(auction)
            else
              ..._buildClosed(auction),
          ],
        );
          },
        );
      },
    );
  }

  List<Widget> _buildNone() {
    if (!widget.isHost) {
      return const [_EmptyHint(text: 'Brak aktywnej licytacji. Poczekaj, aż gospodarz wystawi kartę.')];
    }
    return [LockButton(text: 'Wystaw kartę na licytację', icon: Icons.gavel_rounded, light: true, onTap: _start)];
  }

  List<Widget> _buildOpen(Auction auction) {
    final high = auction.highBid;
    final leader = auction.highBidderId != null ? (_nameById[auction.highBidderId] ?? 'Gracz') : null;
    return [
      IOSGlass(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Karta: ${PowerCards.byId(auction.cardId).name}', style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(high > 0 ? 'Najwyższa oferta: $high\$ — $leader' : 'Brak ofert. Bądź pierwszy!', style: const TextStyle(color: kOneDim, fontWeight: FontWeight.w700)),
        ]),
      ),
      if (!widget.isHost) ...[
        const SizedBox(height: 14),
        Text('Przebij:', style: TextStyle(color: AppColors.white.withValues(alpha: .8), fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final inc in const [5, 10, 25, 50])
            _BidChip(amount: high + inc, enabled: (high + inc) <= _balance, onTap: () => _bid(high + inc)),
        ]),
      ],
      if (widget.isHost) ...[
        const SizedBox(height: 18),
        LockButton(text: 'Zakończ licytację', icon: Icons.flag_rounded, light: true, onTap: _close),
      ],
    ];
  }

  List<Widget> _buildClosed(Auction auction) {
    return [
      IOSGlass(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD166)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            auction.winnerName != null
                ? '${auction.winnerName} wygrywa ${PowerCards.byId(auction.cardId).name} za ${auction.winningBid}\$'
                : 'Brak ofert — karta nie została sprzedana.',
            style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800),
          )),
        ]),
      ),
      const SizedBox(height: 14),
      if (widget.isHost)
        LockButton(text: 'Nowa licytacja', icon: Icons.refresh_rounded, light: true, onTap: _clear)
      else
        const _EmptyHint(text: 'Czekaj na kolejną licytację.'),
    ];
  }
}

class _BidChip extends StatelessWidget {
  const _BidChip({required this.amount, required this.enabled, required this.onTap});
  final int amount;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: enabled ? onTap : () {},
      haptic: HapticFeedbackType.medium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? kOneAccent : kOneSurfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: enabled ? kOneAccent : kOneStroke),
        ),
        child: Text('$amount\$', style: TextStyle(color: enabled ? Colors.white : Colors.white.withValues(alpha: .4), fontWeight: FontWeight.w900, fontSize: 15)),
      ),
    );
  }
}

class _StartAuctionSheet extends StatefulWidget {
  const _StartAuctionSheet();

  @override
  State<_StartAuctionSheet> createState() => _StartAuctionSheetState();
}

class _StartAuctionSheetState extends State<_StartAuctionSheet> {
  String? cardId;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom + MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
        decoration: const BoxDecoration(color: Color(0xFF120505), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(99)))),
          const SizedBox(height: 18),
          const Text('Wystaw kartę na licytację', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: cardId,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: '__random__', child: Text('🎲 Losowa karta')),
              ...PowerCards.all.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (value) => setState(() => cardId = value),
            dropdownColor: const Color(0xFF220808),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              labelText: 'Karta mocy',
              labelStyle: TextStyle(color: AppColors.white.withValues(alpha: .68)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: .08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: .14))),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cardId == null ? null : () => Navigator.pop(context, cardId == '__random__' ? (PowerCards.all.toList()..shuffle()).first.id : cardId),
              icon: const Icon(Icons.gavel_rounded),
              label: const Text('Wystaw'),
              style: ElevatedButton.styleFrom(backgroundColor: kOneAccent, foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      ),
    );
  }
}



/// Home app: roster split into alive / dead with card-effect statuses.
/// Everyone sees it; the host can toggle life state and clear statuses.
class _PlayersApp extends StatelessWidget {
  const _PlayersApp({required this.service, required this.roomCode, required this.isHost, required this.myPlayerId});
  final OnlineRoomService service;
  final String roomCode;
  final bool isHost;
  final String myPlayerId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: StreamBuilder<GameRoom?>(
          stream: service.watchRoom(roomCode),
          builder: (context, snap) {
            final room = snap.data;
            if (room == null) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            final alive = room.players.where((p) => p.alive).toList();
            final dead = room.players.where((p) => !p.alive).toList();
            final revealRoles = isHost || room.players.any((p) => p.id == myPlayerId && !p.alive);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.groups_rounded, color: Color(0xFFEC4899), size: 26),
                  const SizedBox(width: 10),
                  const Text('Gracze', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Text('${alive.length} żywych • ${dead.length} martwych', style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _sectionLabel('ŻYWI', const Color(0xFF34D399)),
                      if (alive.isEmpty) _emptyHint('Brak żywych graczy.'),
                      for (final p in alive) _playerRow(p, true, revealRoles),
                      const SizedBox(height: 14),
                      _sectionLabel('MARTWI', const Color(0xFFEF4444)),
                      if (dead.isEmpty) _emptyHint('Nikt jeszcze nie odpadł.'),
                      for (final p in dead) _playerRow(p, false, revealRoles),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      );

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: .35), fontSize: 12)),
      );

  Widget _playerRow(GamePlayer p, bool alive, bool revealRoles) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF33221F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (alive ? const Color(0xFF34D399) : const Color(0xFFEF4444)).withValues(alpha: .2),
              border: Border.all(color: (alive ? const Color(0xFF34D399) : const Color(0xFFEF4444)).withValues(alpha: .6)),
            ),
            child: Text(p.name.isEmpty ? '?' : p.name.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.id == myPlayerId ? '${p.name} (Ty)' : p.name,
                  style: TextStyle(
                    color: alive ? Colors.white : Colors.white.withValues(alpha: .5),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (revealRoles && p.role != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Rola: ${GameRoles.nameOf(p.role!)}', style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                if (revealRoles && p.medievalClass != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Klasa: ${MedievalClasses.nameOf(p.medievalClass!)}${p.podrzutekFaction != null ? ' (${p.podrzutekFaction == MedievalFaction.korona ? 'Korona' : 'Antagoniści'})' : ''}', style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                if (p.statuses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(spacing: 6, runSpacing: 6, children: [for (final s in p.statuses) if (!s.startsWith('na:') && !s.startsWith('checkresult:') && !s.startsWith('gossip') && !s.startsWith('sentence_round') && !s.startsWith('confess_round') && s != 'duel_used' && s != 'discard1' && s != 'plotka_shield' && !s.startsWith('identity:')) _statusChip(s)]),
                  ),
              ],
            ),
          ),
          if (isHost) ...[
            IconButton(
              onPressed: () => service.setPlayerAlive(code: roomCode, playerId: p.id, alive: !alive),
              icon: Icon(alive ? Icons.heart_broken_rounded : Icons.favorite_rounded, color: alive ? const Color(0xFFEF4444) : const Color(0xFF34D399)),
            ),
            IconButton(
              onPressed: () => service.kickPlayer(code: roomCode, playerId: p.id),
              icon: Icon(Icons.person_remove_rounded, color: Colors.redAccent.withValues(alpha: .8), size: 20),
            ),
            if (p.statuses.isNotEmpty)
              IconButton(
                onPressed: () => service.clearPlayerStatuses(code: roomCode, playerId: p.id),
                icon: Icon(Icons.cleaning_services_rounded, color: Colors.white.withValues(alpha: .6), size: 20),
              ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final base = status.contains(':') ? status.split(':').first : status;
    final map = <String, (String, Color, IconData)>{
      'poisoned': ('Zatruty', Color(0xFF8B5CF6), Icons.local_bar_rounded),
      'poisoned2': ('Zatruty', Color(0xFF8B5CF6), Icons.local_bar_rounded),
      'protected': ('Chroniony', Color(0xFF06B6D4), Icons.shield_rounded),
      'blocked': ('Zakuty', Color(0xFF94A3B8), Icons.link_rounded),
      'marked': ('Naznaczony', Color(0xFFDC2626), Icons.track_changes_rounded),
      'bound': ('Pakt krwi', Color(0xFFE11D48), Icons.favorite_rounded),
      'silenced': ('Wyciszony', Color(0xFF60A5FA), Icons.nightlight_round),
      'watched': ('Obserwowany', Color(0xFF38BDF8), Icons.visibility_rounded),
      'onballot': ('Na wokandzie', Color(0xFFF97316), Icons.how_to_vote_rounded),
      'intimidated': ('Zastraszony', Color(0xFFEF4444), Icons.psychology_alt_rounded),
      'trading': ('Wymiana', Color(0xFFA3E635), Icons.handshake_rounded),
      'bequeath': ('Spadek', Color(0xFFF43F5E), Icons.volunteer_activism_rounded),
      'kompromitacja1': ('Kompromitacja I', Color(0xFF7A1F2B), Icons.warning_amber_rounded),
      'kompromitacja2': ('Kompromitacja II', Color(0xFF7A1F2B), Icons.warning_amber_rounded),
      'kompromitacja3': ('Kompromitacja III', Color(0xFF7A1F2B), Icons.gavel_rounded),
      'dowod': ('Dowód', Color(0xFF6B6470), Icons.folder_shared_rounded),
      'pakt': ('Pakt krwi', Color(0xFF2F6B4F), Icons.favorite_rounded),
      'sentenced': ('Pod wyrokiem', Color(0xFF9A3412), Icons.gavel_rounded),
      'confessed': ('Na spowiedzi', Color(0xFF4B3621), Icons.menu_book_rounded),
    };
    final spec = map[base];
    final label = spec?.$1 ?? base;
    final color = spec?.$2 ?? Colors.white70;
    final icon = spec?.$3 ?? Icons.bolt_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: .2), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .5))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

/// Right-swipe page: live day-voting. Players cast/change a vote and watch the
/// tally update in real time; the host starts/closes it and sees who voted whom.
class _VotingApp extends StatelessWidget {
  const _VotingApp({required this.service, required this.roomCode, required this.isHost, required this.myPlayerId, required this.room});
  final OnlineRoomService service;
  final String roomCode;
  final bool isHost;
  final String myPlayerId;
  final GameRoom room;

  String _voterName(String id) {
    if (id == room.hostId) return room.hostName;
    for (final p in room.players) {
      if (p.id == id) return p.name;
    }
    return 'Gracz';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: StreamBuilder<VoteSession?>(
          stream: service.watchVote(roomCode),
          builder: (context, snap) {
            final session = snap.data;
            final open = session?.isOpen ?? false;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.how_to_vote_rounded, color: Color(0xFFE5404F), size: 26),
                    const SizedBox(width: 10),
                    const Text('Głosowanie', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    _stateChip(session),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Przesuń w lewo, aby wrócić do pulpitu.', style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                Expanded(child: _body(session, open)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stateChip(VoteSession? session) {
    final open = session?.isOpen ?? false;
    final closed = session != null && !open;
    final label = open ? 'TRWA' : (closed ? 'ZAMKNIĘTE' : 'NIEAKTYWNE');
    final color = open ? const Color(0xFF34D399) : (closed ? const Color(0xFFF59E0B) : Colors.white54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: .6))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: .6)),
    );
  }

  Widget _body(VoteSession? session, bool open) {
    if (session == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_vote_outlined, color: Colors.white.withValues(alpha: .28), size: 54),
            const SizedBox(height: 12),
            Text(
              isHost ? 'Rozpocznij głosowanie, aby gracze mogli oddać głosy.' : 'Głosowanie nieaktywne.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .55), fontWeight: FontWeight.w700),
            ),
            if (isHost) ...[
              const SizedBox(height: 18),
              _bigButton(icon: Icons.play_arrow_rounded, label: 'Rozpocznij głosowanie', onTap: () => service.startVote(roomCode)),
            ],
          ],
        ),
      );
    }

    final tally = session.tally;
    final total = session.castCount;
    final myVote = session.ballots[myPlayerId];
    final onballot = room.players.where((p) => p.alive && p.statuses.contains('onballot')).map((p) => p.name).toList();
    final aliveNames = room.players.where((p) => p.alive).map((p) => p.name).toList();
    final candidates = session.isRunoff
        ? session.runoffCandidates.where(aliveNames.contains).toList()
        : (onballot.isNotEmpty ? onballot : aliveNames);
    final leader = session.leader;
    final amAlive = isHost || room.players.any((p) => p.id == myPlayerId && p.alive);
    final iAmIntimidated = !isHost && room.players.any((p) => p.id == myPlayerId && p.statuses.contains('intimidated'));
    // Kompromitacja (medieval): any level costs you your vote.
    final iAmCompromised = !isHost && room.players.any((p) => p.id == myPlayerId && p.statuses.any((s) => s.startsWith('kompromitacja')));
    final canVote = open && !isHost && amAlive && !iAmIntimidated && !iAmCompromised;
    // Przysięga Krwi: you cannot vote against your pact partner.
    final myPakts = room.players
        .where((p) => p.id == myPlayerId)
        .expand((p) => p.statuses)
        .where((s) => s.startsWith('pakt:'))
        .map((s) => s.substring(5))
        .toSet();

    return Column(
      children: [
        if (iAmIntimidated)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: .5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_alt_rounded, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jesteś zastraszony — Twój głos (${myVote == null || myVote.isEmpty ? '—' : myVote}) jest wymuszony i zablokowany.',
                    style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900, fontSize: 12.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        if (session.isRunoff)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: .5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel_rounded, color: Color(0xFFFFD166), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DOGRYWKA — remis. Głosujecie tylko na: ${candidates.join(', ')}',
                    style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.w900, fontSize: 12.5, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              for (final name in candidates)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _candidateTile(name: name, count: tally[name] ?? 0, total: total, mine: myVote == name, canVote: canVote && !myPakts.contains(name)),
                ),
              if (canVote)
                _abstainTile(mine: myVote == ''),
              if (isHost) ...[
                const SizedBox(height: 10),
                _hostBreakdown(session),
              ],
            ],
          ),
        ),
        _resultLine(session, open, leader, tally),
        if (isHost) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: open
                    ? _bigButton(icon: Icons.stop_rounded, label: 'Zakończ', onTap: () => service.closeVote(roomCode))
                    : _bigButton(icon: Icons.play_arrow_rounded, label: 'Nowe głosowanie', onTap: () => service.startVote(roomCode)),
              ),
              const SizedBox(width: 10),
              _iconButton(icon: Icons.delete_outline_rounded, onTap: () => service.clearVote(roomCode)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _resultLine(VoteSession session, bool open, String? leader, Map<String, int> tally) {
    String text;
    Color color = Colors.white;
    if (open) {
      if (leader == null) {
        text = session.isRunoff ? 'Dogrywka trwa — brak głosów' : 'Brak głosów';
        color = Colors.white.withValues(alpha: .6);
      } else if (session.isTie) {
        text = 'Remis: ${session.topCandidates.join(', ')} (po ${tally[leader] ?? 0})';
        color = const Color(0xFFFFD166);
      } else {
        text = 'Prowadzi: $leader (${tally[leader] ?? 0})';
      }
    } else {
      final decisive = session.decisiveTarget;
      if (decisive != null) {
        text = 'Wynik: odpada $decisive (${tally[decisive] ?? 0} głosów)';
        color = const Color(0xFFE5404F);
      } else if (session.isTie) {
        text = 'Remis — nikt nie odpadł';
        color = const Color(0xFFFFD166);
      } else {
        text = 'Nikt nie zagłosował — nikt nie odpadł';
        color = Colors.white.withValues(alpha: .7);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
    );
  }

  Widget _candidateTile({required String name, required int count, required int total, required bool mine, required bool canVote}) {
    final frac = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: canVote ? () => service.castVote(code: roomCode, voterId: myPlayerId, targetName: name) : null,
      child: Container(
        height: 54,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF33221F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mine ? const Color(0xFFE5404F) : Colors.white.withValues(alpha: .08), width: mine ? 1.5 : 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: frac,
                heightFactor: 1,
                child: Container(color: const Color(0xFFE5404F).withValues(alpha: mine ? .34 : .18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
                  if (mine) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.check_circle_rounded, color: Color(0xFFE5404F), size: 18)),
                  Text('$count', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _abstainTile({required bool mine}) {
    return GestureDetector(
      onTap: () => service.castVote(code: roomCode, voterId: myPlayerId, targetName: ''),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mine ? Colors.white54 : Colors.white.withValues(alpha: .08)),
        ),
        child: Row(
          children: [
            Icon(Icons.block_rounded, size: 18, color: Colors.white.withValues(alpha: .6)),
            const SizedBox(width: 10),
            Text('Wstrzymaj się', style: TextStyle(color: Colors.white.withValues(alpha: .7), fontWeight: FontWeight.w700)),
            const Spacer(),
            if (mine) const Icon(Icons.check_rounded, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _hostBreakdown(VoteSession session) {
    final entries = session.ballots.entries.where((e) => e.value.trim().isNotEmpty).toList();
    if (entries.isEmpty) {
      return Text('Nikt jeszcze nie zagłosował.', style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 12));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kto na kogo:', style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text('${_voterName(e.key)} → ${e.value}', style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12.5)),
          ),
      ],
    );
  }

  Widget _bigButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5404F), foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      width: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, side: BorderSide(color: Colors.white.withValues(alpha: .2)), padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Icon(icon),
      ),
    );
  }
}

/// Android-style pull-down quick panel. Host controls the phase live; players
/// get a read-only summary.
class _QuickPanel extends StatelessWidget {
  const _QuickPanel({required this.room, required this.isHost, required this.myPlayerId, required this.myRoleLabel, required this.pendingCards, required this.onChangePhase, required this.onEndGame, required this.onClose});
  final GameRoom room;
  final bool isHost;
  final String myPlayerId;
  final String myRoleLabel;
  final int pendingCards;
  final ValueChanged<GamePhase> onChangePhase;
  final VoidCallback onEndGame;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.viewPaddingOf(context).top;
    final alive = room.players.where((p) => p.alive).length;
    final dead = room.players.where((p) => !p.alive).length;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 10 + topPad, 16, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0E10),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(isHost ? Icons.admin_panel_settings_rounded : Icons.tune_rounded, color: kOneAccent, size: 22),
              const SizedBox(width: 8),
              Text(isHost ? (room.edition.isMedieval ? 'Panel króla' : 'Panel gospodarza') : 'Panel', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: kOneAccent.withValues(alpha: .18), borderRadius: BorderRadius.circular(99), border: Border.all(color: kOneAccent.withValues(alpha: .5))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(phaseIcon(room.phase), color: kOneAccent, size: 15),
                  const SizedBox(width: 6),
                  Text(phaseLabel(room.phase), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            if (isHost) ...[
              Align(alignment: Alignment.centerLeft, child: Text('Zmień fazę', style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 12, fontWeight: FontWeight.w800))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final ph in const [GamePhase.day, GamePhase.night, GamePhase.voting])
                  _PhaseButton(phase: ph, active: room.phase == ph, onTap: () => onChangePhase(ph)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _stat('Żywi', '$alive', const Color(0xFF34D399)),
                const SizedBox(width: 8),
                _stat('Martwi', '$dead', const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _stat('Karty w kolejce', '$pendingCards', kOneAccent),
              ]),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onEndGame,
                  icon: const Icon(Icons.flag_circle_rounded),
                  label: const Text('Zakończ grę → Lobby'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5404F),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else ...[
              _infoRow(Icons.flag_rounded, 'Faza', phaseLabel(room.phase)),
              _infoRow(Icons.badge_rounded, 'Twoja rola', myRoleLabel),
              _infoRow(Icons.payments_rounded, 'Portfel', '\$${room.wallets[myPlayerId] ?? 0}'),
              if (room.edition.isMedieval) _infoRow(Icons.savings_rounded, 'Wpływy', '${room.wplywy[myPlayerId] ?? 0}'),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (d) {
                if (d.delta.dy < -2) onClose();
              },
              child: Container(
                width: 120,
                height: 22,
                alignment: Alignment.center,
                child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(99))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .35))),
          child: Column(children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 10, fontWeight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, color: Colors.white.withValues(alpha: .6), size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .6), fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ]),
      );

}


class _PhaseButton extends StatelessWidget {
  const _PhaseButton({required this.phase, required this.active, required this.onTap});
  final GamePhase phase;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kOneAccent : Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? kOneAccent : Colors.white.withValues(alpha: .12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(phaseIcon(phase), color: active ? Colors.white : Colors.white.withValues(alpha: .7), size: 16),
          const SizedBox(width: 6),
          Text(phaseLabel(phase), style: TextStyle(color: active ? Colors.white : Colors.white.withValues(alpha: .8), fontSize: 13, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

/// Small pull-tab at the very top; tap or drag down to open the quick panel.
class _PanelGrip extends StatelessWidget {
  const _PanelGrip({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (d) {
        if (d.delta.dy > 0.5) onOpen();
      },
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 120) onOpen();
      },
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 7,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .5), borderRadius: BorderRadius.circular(99)),
                ),
                const SizedBox(height: 3),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: .32), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent bottom banner shown to eliminated players (spectator mode).
class _GhostBanner extends StatelessWidget {
  const _GhostBanner();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.viewPaddingOf(context).top + 30),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF120505).withValues(alpha: .92),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: .55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_rounded, color: Colors.white.withValues(alpha: .85), size: 16),
                const SizedBox(width: 8),
                Text('Nie żyjesz — obserwujesz', style: TextStyle(color: Colors.white.withValues(alpha: .9), fontWeight: FontWeight.w900, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Victory overlay shown to everyone when a side wins.
class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.mafia, required this.isHost, required this.onNewGame, this.medieval = false, this.prestige});
  final bool mafia;
  final bool isHost;
  final VoidCallback onNewGame;
  final bool medieval;
  final String? prestige;

  @override
  Widget build(BuildContext context) {
    final color = medieval
        ? (mafia ? const Color(0xFF7A0E14) : const Color(0xFFC9A227))
        : (mafia ? const Color(0xFFD62330) : const Color(0xFF34D399));
    final title = medieval
        ? (mafia ? 'RÓD WĘŻA ZWYCIĘŻA' : 'KORONA OCALAŁA')
        : (mafia ? 'MAFIA WYGRYWA' : 'MIASTO WYGRYWA');
    final subtitle = medieval
        ? (mafia
            ? 'Spiskowcy przejęli dwór — tron należy do Rodu Węża.'
            : 'Zdrajcy zdemaskowani, Korona zachowała władzę.')
        : (mafia
            ? 'Mafia zrównała siły z resztą miasta.'
            : 'Wszyscy mafiozi zostali wyeliminowani.');
    final icon = medieval
        ? (mafia ? Icons.dark_mode_rounded : Icons.castle_rounded)
        : (mafia ? Icons.local_fire_department_rounded : Icons.groups_rounded);
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 30),
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF120505),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: .6), width: 2),
          boxShadow: [BoxShadow(color: color.withValues(alpha: .4), blurRadius: 44, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 72),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 14, height: 1.4),
            ),
            if (medieval && prestige != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A227).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC9A227).withValues(alpha: .5)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Color(0xFFC9A227), size: 18),
                        SizedBox(width: 6),
                        Text('Prestiż dworu', style: TextStyle(color: Color(0xFFC9A227), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .5)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      prestige!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
            if (isHost) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onNewGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Nowa gra (do lobby)'),
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w900), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text('Dotknij, aby zamknąć', style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Full-screen overlay shown to a player when a card resolves against them.
class _CardHitCard extends StatefulWidget {
  const _CardHitCard({required this.action});
  final PlayedPowerCardAction action;

  @override
  State<_CardHitCard> createState() => _CardHitCardState();
}

class _CardHitCardState extends State<_CardHitCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _timer = Timer(const Duration(milliseconds: 4200), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.action.card;
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 34),
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
        decoration: BoxDecoration(
          color: const Color(0xFF241619),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: card.color.withValues(alpha: .55), width: 1.5),
          boxShadow: [
            BoxShadow(color: card.color.withValues(alpha: .35), blurRadius: 40, spreadRadius: 2),
            const BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [card.color.withValues(alpha: .9), card.color.withValues(alpha: .32)],
                ),
                boxShadow: [BoxShadow(color: card.color.withValues(alpha: .6), blurRadius: 26, spreadRadius: 1)],
              ),
              child: Icon(card.icon, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              'ZAGRANO NA CIEBIE',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .62), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              card.name,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              card.effectDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Dotknij, aby zamknąć',
              style: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Left-swipe page: graphical feed of resolved power-card plays.
/// Players see the target + card + effect (never the source); the host sees all.
class _CardFeedApp extends StatelessWidget {
  const _CardFeedApp({required this.actions, required this.isHost, required this.myName});
  final List<PlayedPowerCardAction> actions;
  final bool isHost;
  final String myName;

  @override
  Widget build(BuildContext context) {
    final resolved = actions.where((a) => a.resolved).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dynamic_feed_rounded, color: Color(0xFFE5404F), size: 26),
                const SizedBox(width: 10),
                const Text('Zagrane karty', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('${resolved.length}', style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isHost
                  ? 'Widzisz kto rzucił i na kogo. Przesuń w prawo, aby wrócić.'
                  : 'Widać kto oberwał — nie widać kto rzucił. Przesuń w prawo, aby wrócić.',
              style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: resolved.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.style_outlined, color: Colors.white.withValues(alpha: .28), size: 54),
                          const SizedBox(height: 12),
                          Text('Jeszcze nikt nie zagrał karty.', style: TextStyle(color: Colors.white.withValues(alpha: .5), fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Zagrane karty aktywują się w kolejnej fazie.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .34), fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: resolved.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final a = resolved[i];
                        return _CardFeedTile(action: a, isHost: isHost, isMine: a.targetPlayerName == myName);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, height: 1.35),
          children: [
            TextSpan(text: '$label: ', style: TextStyle(color: Colors.white.withValues(alpha: .45), fontWeight: FontWeight.w600)),
            TextSpan(text: value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _CardFeedTile extends StatelessWidget {
  const _CardFeedTile({required this.action, required this.isHost, required this.isMine});
  final PlayedPowerCardAction action;
  final bool isHost;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final card = action.card;
    final target = action.targetPlayerName;
    final source = action.sourcePlayerName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF33221F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMine ? const Color(0xFFE5404F) : Colors.white.withValues(alpha: .08),
          width: isMine ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: card.color.withValues(alpha: .22),
              border: Border.all(color: card.color.withValues(alpha: .7), width: 1.4),
            ),
            child: Icon(card.icon, color: card.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(card.name, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, decoration: action.negated ? TextDecoration.lineThrough : null, decorationColor: const Color(0xFF67E8F9)))),
                    if (action.negated)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF06B6D4).withValues(alpha: .22), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF06B6D4))),
                        child: const Text('ZNIWELOWANE', style: TextStyle(color: Color(0xFF67E8F9), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .5)),
                      ),
                    if (isMine)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFE5404F), borderRadius: BorderRadius.circular(20)),
                        child: const Text('NA CIEBIE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: .5)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('na: ', style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12.5)),
                    Flexible(
                      child: Text(
                        target == null || target.isEmpty ? '—' : target,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  card.effectDescription,
                  style: TextStyle(color: Colors.white.withValues(alpha: .68), fontSize: 12.5, height: 1.4),
                ),
                if (action.negated)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_rounded, size: 13, color: Color(0xFF67E8F9)),
                        const SizedBox(width: 5),
                        Expanded(child: Text(action.negatedReason ?? 'Efekt tej karty został zniwelowany.', style: const TextStyle(color: Color(0xFF67E8F9), fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.3))),
                      ],
                    ),
                  ),
                if (isHost) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: .22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.visibility_rounded, size: 13, color: Color(0xFFFFD166)),
                            const SizedBox(width: 5),
                            const Text('LOG GOSPODARZA', style: TextStyle(color: Color(0xFFFFD166), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .8)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _LogLine(label: 'Zagrał', value: source.trim().isEmpty ? '—' : source),
                        _LogLine(label: 'Cel', value: target == null || target.isEmpty ? '—' : target),
                        if (action.secondTargetPlayerName != null && action.secondTargetPlayerName!.isNotEmpty)
                          _LogLine(label: card.id == 'intimidation' ? 'Ma zagłosować na' : 'Drugi cel', value: action.secondTargetPlayerName!),
                        if (action.note != null && action.note!.trim().isNotEmpty)
                          _LogLine(label: 'Notatka', value: action.note!.trim()),
                        if (action.phasePlayed != null && action.phasePlayed!.isNotEmpty)
                          _LogLine(label: 'Faza zagrania', value: action.phasePlayed!),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
