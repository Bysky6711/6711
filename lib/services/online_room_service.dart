import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../chat/chat_message.dart';
import '../data/card_registry.dart';
import '../data/medieval_cards.dart';
import '../data/medieval_classes.dart';
import '../data/power_cards.dart';
import '../data/roles.dart';
import '../models/auction.dart';
import '../models/game_edition.dart';
import '../models/game_phase.dart';
import '../models/game_player.dart';
import '../models/game_room.dart';
import '../models/game_task.dart';
import '../models/room_status.dart';
import '../models/vote_session.dart';

/// Realtime online backend (Cloud Firestore).
///
/// Firestore layout:
///   rooms/{ROOMCODE}                    -> GameRoom.toMap()
///   rooms/{ROOMCODE}/messages/{autoId}  -> chat message
///   rooms/{ROOMCODE}/actions/{autoId}   -> played power-card action
///
/// The room code is the document id (uppercased), so joining by code is a
/// single direct lookup — no queries, minimal latency.
/// The Firestore database in this project is a NAMED database with id "default"
/// (NOT the special "(default)"). The SDK targets "(default)" unless told
/// otherwise, which fails with: Database '(default)' not found. So we point
/// every Firestore call at the "default" database explicitly.
const String kFirestoreDatabaseId = 'default';

FirebaseFirestore mafiaFirestore() =>
    FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: kFirestoreDatabaseId);

class OnlineRoomService {
  OnlineRoomService({FirebaseFirestore? firestore})
      : _db = firestore ?? mafiaFirestore();

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');
  DocumentReference<Map<String, dynamic>> _roomDoc(String code) =>
      _rooms.doc(code.toUpperCase());

  // ---- room lifecycle -------------------------------------------------------

  Future<GameRoom> createRoom({
    required String hostName,
    required int maxPlayers,
    required Map<MafiaRoleCardType, int> roleCounts,
    GameEdition edition = GameEdition.standard,
  }) async {
    final code = await _uniqueRoomCode();
    final room = GameRoom(
      roomCode: code,
      hostId: _generateId('host'),
      hostName: hostName.trim().isEmpty ? 'Gospodarz' : hostName.trim(),
      maxPlayers: maxPlayers,
      roleCounts: Map<MafiaRoleCardType, int>.from(roleCounts),
      players: const [],
      status: RoomStatus.waiting,
      phase: GamePhase.setup,
      createdAt: DateTime.now(),
      edition: edition,
    );
    await _roomDoc(code).set(room.toMap());
    return room;
  }

  /// Live room document — drives every screen. Emits null if the room is gone.
  Stream<GameRoom?> watchRoom(String code) => _roomDoc(code).snapshots().map(
        (snap) => snap.exists ? GameRoom.fromMap(snap.data()!) : null,
      );

  Future<GameRoom?> getRoom(String code) async {
    final snap = await _roomDoc(code).get();
    return snap.exists ? GameRoom.fromMap(snap.data()!) : null;
  }

  /// Joins a room by code. Returns the created player; its [GamePlayer.id]
  /// is how this device knows which player it is for the rest of the game.
  Future<GamePlayer> joinRoom({
    required String code,
    required String playerName,
  }) async {
    final name = playerName.trim();
    if (name.isEmpty) throw Exception('Nazwa gracza nie może być pusta.');
    final doc = _roomDoc(code);
    return _db.runTransaction<GamePlayer>((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) {
        throw Exception('Nie znaleziono pokoju ${code.toUpperCase()}.');
      }
      final room = GameRoom.fromMap(snap.data()!);
      if (!room.isWaiting) throw Exception('Gra już wystartowała.');
      if (room.isFull) throw Exception('Pokój jest pełny.');
      if (room.players.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
        throw Exception('Ktoś już gra pod nazwą "$name".');
      }
      final player = GamePlayer(
        id: _generateId('player'),
        name: name,
        joinedAt: DateTime.now(),
      );
      tx.update(doc, {
        'players': [...room.players, player].map((p) => p.toMap()).toList(),
      });
      return player;
    });
  }

  Future<void> removePlayer({
    required String code,
    required String playerId,
  }) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      if (!room.isWaiting) return;
      tx.update(doc, {
        'players': room.players
            .where((p) => p.id != playerId)
            .map((p) => p.toMap())
            .toList(),
      });
    });
  }

  /// Host removes a player at any time (even mid-game); the player is booted.
  Future<void> kickPlayer({required String code, required String playerId}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players.where((p) => p.id != playerId).map((p) => p.toMap()).toList(),
      });
    });
  }

  String? startGameError(GameRoom room) {
    if (!room.isWaiting) return 'Gra już została rozpoczęta.';
    if (room.currentPlayersCount < room.maxPlayers) {
      return 'Brakuje graczy: ${room.currentPlayersCount}/${room.maxPlayers}.';
    }
    if (room.currentPlayersCount > room.maxPlayers) {
      return 'W pokoju jest za dużo graczy.';
    }
    if (!room.hasValidDeck) {
      return 'Liczba kart ról nie zgadza się z liczbą graczy.';
    }
    return null;
  }

  /// Shuffles the deck and assigns a role to every player, atomically.
  Future<void> startGame(String code, {bool force = false}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) throw Exception('Nie znaleziono pokoju.');
      final room = GameRoom.fromMap(snap.data()!);
      if (!force) {
        final error = startGameError(room);
        if (error != null) throw Exception(error);
      }
      final deckSize = force ? room.players.length : room.maxPlayers;
      final List<Map<String, dynamic>> updatedPlayers;
      if (room.edition.isMedieval) {
        final deck = MedievalClasses.buildDeck(players: deckSize)..shuffle();
        updatedPlayers = [
          for (var i = 0; i < room.players.length; i++)
            room.players[i]
                .copyWith(medievalClass: deck.isEmpty ? MedievalClassType.podrzutek : deck[i % deck.length])
                .toMap(),
        ];
      } else {
        final deck = GameRoles.buildDeck(players: deckSize, roleCounts: room.roleCounts);
        final shuffled = List<MafiaRoleCardType>.from(deck)..shuffle();
        updatedPlayers = [
          for (var i = 0; i < room.players.length; i++)
            room.players[i]
                .copyWith(role: shuffled.isEmpty ? MafiaRoleCardType.citizen : shuffled[i % shuffled.length])
                .toMap(),
        ];
      }
      tx.update(doc, {
        'players': updatedPlayers,
        'status': RoomStatus.inProgress.name,
        'phase': GamePhase.setup.name,
      });
    });
  }

  Future<void> changePhase({
    required String code,
    required GamePhase phase,
  }) async {
    // Queued power cards fire when we leave their phase; poison then ages toward
    // death and blood-bonds cascade. All applied atomically to the room doc.
    final pending = await _roomDoc(code)
        .collection('actions')
        .where('resolved', isEqualTo: false)
        .get();
    // Keep each action paired with its doc so we can also flag negated ones.
    final entries = pending.docs
        .map((d) => (doc: d, action: PlayedPowerCardAction.fromMap(d.data())))
        .toList()
      ..sort((a, b) => _effectPriority(a.action.card.id).compareTo(_effectPriority(b.action.card.id)));

    final negated = <String, String>{}; // docId -> reason it was cancelled

    await _db.runTransaction((tx) async {
      final snap = await tx.get(_roomDoc(code));
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      var players = room.players;
      players = _expireTransient(players);
      // Kukła (puppet) grants its owner 'protected' and, per its text, must
      // survive the mafia's night attack. Its protection therefore has to land
      // BEFORE the night kill resolves — otherwise a Kukła played during the
      // night could never stop the hit that resolves in this same night→day
      // transition (the card's whole purpose). We pre-apply it here; the main
      // loop below re-applies it idempotently.
      // (Nie tym razem is NOT pre-applied: it only negates targeted *cards*, not
      // the mafia's innate kill, and its priority-0 slot in the loop already
      // shields it before any negatable card is processed.)
      for (final e in entries) {
        if (e.action.card.id == 'puppet') {
          final src = e.action.sourcePlayerName.trim();
          if (src.isNotEmpty) players = _addStatusTo(players, {src}, 'protected');
        }
      }
      // Automated class night-abilities (Mafia/Szeryf kill, Lekarz heal,
      // Detektyw check) resolve the moment the night ends.
      if (room.phase == GamePhase.night) players = _resolveNightActions(players);
      for (final e in entries) {
        // Defensive cards (protected) resolve first (priority 0), so by the time
        // a negative card is processed the shield is already on its target.
        final reason = _negationReason(players, e.action);
        if (reason != null) {
          negated[e.doc.id] = reason;
          continue; // effect cancelled — do not apply
        }
        players = _applyCardEffect(players, e.action, room.roleCounts);
      }
      players = _tickStatuses(players);
      tx.update(_roomDoc(code), {
        'players': players.map((p) => p.toMap()).toList(),
      });
    });

    if (entries.isNotEmpty) {
      final batch = _db.batch();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final e in entries) {
        final reason = negated[e.doc.id];
        final data = <String, dynamic>{'resolved': true, 'resolvedAt': now};
        if (reason != null) {
          data['negated'] = true;
          data['negatedReason'] = reason;
        }
        batch.update(e.doc.reference, data);
      }
      await batch.commit();
    }
    await _roomDoc(code).update({
      'phase': phase.name,
      'status': (phase == GamePhase.finished
              ? RoomStatus.finished
              : RoomStatus.inProgress)
          .name,
    });
    await _settleDeadHands(code);
    await _settleForcedDiscards(code);
    await _medievalPhaseTick(code, phase);
  }

  /// Czara Cykuty played on a target with clean reputation (no kompromitacja):
  /// instead of poisoning them, they lose one random card from hand. The effect
  /// tags them 'discard1' during resolution; we settle it here because hands
  /// live in a subcollection that _applyCardEffect (pure over players) can't
  /// touch.
  Future<void> _settleForcedDiscards(String code) async {
    final snap = await _roomDoc(code).get();
    if (!snap.exists) return;
    final room = GameRoom.fromMap(snap.data()!);
    final marked = room.players.where((p) => p.statuses.contains('discard1')).toList();
    if (marked.isEmpty) return;
    for (final p in marked) {
      final handRef = _roomDoc(code).collection('hands').doc(p.id);
      final handSnap = await handRef.get();
      final cards = List<String>.from((handSnap.data()?['cards'] as List?) ?? const []);
      if (cards.isNotEmpty) {
        cards.removeAt(math.Random().nextInt(cards.length));
        await handRef.set({'cards': cards});
      }
    }
    // Clear the one-shot marker once settled.
    await _db.runTransaction((tx) async {
      final s = await tx.get(_roomDoc(code));
      if (!s.exists) return;
      final r = GameRoom.fromMap(s.data()!);
      tx.update(_roomDoc(code), {
        'players': r.players
            .map((p) => p.statuses.contains('discard1')
                ? p.copyWith(statuses: p.statuses.where((x) => x != 'discard1').toList()).toMap()
                : p.toMap())
            .toList(),
      });
    });
  }

  /// Per-phase upkeep for the medieval edition only (no-op for the base game):
  ///  * compromise level 3 → permanent exile (bond deaths cascade),
  ///  * passive Wpływy income (Wróg Publiczny +5 each phase),
  ///  * roundNumber advances when a new day begins (Podrzutek's 3-turn window).
  Future<void> _medievalPhaseTick(String code, GamePhase newPhase) async {
    // Read hands once — needed both for Ostatnia Wola (which of the dead held
    // the card) and Renta Dworska (+5 Wpływów per holder). Hands are stable
    // here: this runs at the very end of changePhase, after all card resolution.
    final handsSnap = await _roomDoc(code).collection('hands').get();
    final handCards = <String, List<String>>{
      for (final d in handsSnap.docs) d.id: List<String>.from((d.data()['cards'] as List?) ?? const []),
    };
    final ostatniaWolaHolders = <String>{
      for (final e in handCards.entries) if (e.value.contains('ostatnia_wola')) e.key,
    };
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_roomDoc(code));
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      if (!room.edition.isMedieval) return;
      var players = [
        for (final p in room.players)
          (p.alive && p.statuses.contains('kompromitacja3')) ? p.copyWith(alive: false) : p,
      ];
      players = _resolveBonds(players);
      // Ostatnia Wola Umierającego: only a dead player who HELD this card gets
      // the unburned evidence against them annulled (matches the card text).
      // Evidence against any other corpse is harmless (you can't interrogate the
      // dead), so it is left in place.
      players = [
        for (final p in players)
          (!p.alive && ostatniaWolaHolders.contains(p.id) && p.statuses.any((s) => s.startsWith('dowod:')))
              ? p.copyWith(statuses: p.statuses.where((s) => !s.startsWith('dowod:')).toList())
              : p,
      ];
      final wplywy = <String, int>{...room.wplywy};
      for (final p in players) {
        if (p.alive && p.medievalClass == MedievalClassType.wrogPubliczny) {
          wplywy[p.id] = (wplywy[p.id] ?? 0) + 5;
        }
      }
      tx.update(_roomDoc(code), {
        'players': players.map((e) => e.toMap()).toList(),
        'wplywy': wplywy,
        'roundNumber': newPhase == GamePhase.day ? room.roundNumber + 1 : room.roundNumber,
      });
    });
    // Renta Dworska: +5 Wpływów co fazę każdemu, kto trzyma tę kartę w ręce.
    final pre = await _roomDoc(code).get();
    if (!pre.exists || !GameRoom.fromMap(pre.data()!).edition.isMedieval) return;
    for (final e in handCards.entries) {
      if (e.value.contains('renta_dworska')) {
        await awardInfluence(code: code, playerId: e.key, amount: 5);
      }
    }
  }

  /// Grants (or removes, if negative) Wpływy — the medieval second resource,
  /// exactly parallel to [awardMoney].
  Future<void> awardInfluence({
    required String code,
    required String playerId,
    required int amount,
  }) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final raw = (snap.data()?['wplywy'] as Map?) ?? const {};
      final wplywy = <String, int>{
        for (final e in raw.entries) e.key as String: (e.value as num).toInt(),
      };
      wplywy[playerId] = (wplywy[playerId] ?? 0) + amount;
      tx.update(doc, {'wplywy': wplywy});
    });
  }

  /// Bankructwo: zeroes a player's Wpływy.
  Future<void> zeroInfluence({required String code, required String playerId}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final raw = (snap.data()?['wplywy'] as Map?) ?? const {};
      final wplywy = <String, int>{
        for (final e in raw.entries) e.key as String: (e.value as num).toInt(),
      };
      wplywy[playerId] = 0;
      tx.update(doc, {'wplywy': wplywy});
    });
  }

  /// Burns one dowód that [holderName] holds against [targetPlayerId] (removes
  /// the `dowod:<holderName>` tag). The forced yes/no answer is run verbally.
  Future<void> burnEvidence({
    required String code,
    required String holderName,
    required String targetPlayerId,
  }) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players.map((p) {
          if (p.id != targetPlayerId) return p.toMap();
          final st = [...p.statuses];
          final idx = st.indexOf('dowod:$holderName');
          if (idx >= 0) st.removeAt(idx);
          return p.copyWith(statuses: st).toMap();
        }).toList(),
      });
    });
  }

  /// Podrzutek locks in a faction (medieval edition) — permanent once set.
  Future<void> declarePodrzutek({
    required String code,
    required String playerId,
    required MedievalFaction faction,
  }) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players
            .map((p) => p.id == playerId ? p.copyWith(podrzutekFaction: faction).toMap() : p.toMap())
            .toList(),
      });
    });
  }

  /// Rycerz Bez Herbu: a one-off duel. [loserId] is eliminated (bond deaths
  /// cascade) and the knight's duel is marked used.
  Future<void> duel({required String code, required String knightId, required String loserId}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      var players = [
        for (final p in room.players) p.id == loserId ? p.copyWith(alive: false) : p,
      ];
      players = _resolveBonds(players);
      players = [
        for (final p in players)
          p.id == knightId ? p.copyWith(statuses: _withStatus(p.statuses, 'duel_used')) : p,
      ];
      tx.update(doc, {'players': players.map((e) => e.toMap()).toList()});
    });
    await _settleDeadHands(code);
  }

  /// Trubadur: rozpuszcza plotkę dworską — [targetName] trafia na listę
  /// głosowania (`onballot`) i mówi pierwszy. Marker `gossip:<actorId>` daje
  /// Trubadurowi +15 Wpływów, jeśli cel zostanie wygnany w najbliższym
  /// głosowaniu (rozliczane w [closeVote]). `gossiped:<name>` blokuje ponowne
  /// oplotkowanie tej samej osoby, a `gossip_round:<n>` ogranicza do raz na turę.
  Future<void> gossip({required String code, required String actorId, required String targetName}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      // Kontrplotka: a shielded target has the gossip's mechanical effect
      // cancelled (the Trubadur casts a Plotka Dworska, so the same shield that
      // stops the card must stop this too). The shield is consumed; the
      // Trubadur still spends their turn.
      final tgt = room.players.where((p) => p.name == targetName).toList();
      final shielded = tgt.isNotEmpty && tgt.first.statuses.contains('plotka_shield');
      final players = room.players.map((p) {
        if (p.id == actorId) {
          return p.copyWith(statuses: _withStatus(_withStatus(p.statuses, 'gossiped:$targetName'), 'gossip_round:${room.roundNumber}')).toMap();
        }
        if (p.name == targetName) {
          if (shielded) {
            return p.copyWith(statuses: p.statuses.where((s) => s != 'plotka_shield').toList()).toMap();
          }
          return p.copyWith(statuses: _withStatus(_withStatus(p.statuses, 'onballot'), 'gossip:$actorId')).toMap();
        }
        return p.toMap();
      }).toList();
      tx.update(doc, {'players': players});
    });
  }

  /// Kat: dopisuje [targetName] do listy wyroków (`onballot` + `sentenced`) —
  /// wyrok rozstrzyga zwykłe głosowanie, o ile większość nie ułaskawi (głos
  /// ułaskawienia prowadzi werbalnie gospodarz). `sentence_round:<n>` wymusza
  /// odstęp dwóch tur między wyrokami.
  Future<void> sentence({required String code, required String actorId, required String targetName}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      final players = room.players.map((p) {
        if (p.id == actorId) {
          final cleaned = p.statuses.where((s) => !s.startsWith('sentence_round:')).toList();
          return p.copyWith(statuses: _withStatus(cleaned, 'sentence_round:${room.roundNumber}')).toMap();
        }
        if (p.name == targetName) {
          return p.copyWith(statuses: _withStatus(_withStatus(p.statuses, 'onballot'), 'sentenced')).toMap();
        }
        return p.toMap();
      }).toList();
      tx.update(doc, {'players': players});
    });
  }

  /// Kanonik: wzywa [targetName] na spowiedź — nakłada anonimowy, jednofazowy
  /// status `confessed` (cel musi szczerze odpowiedzieć tak/nie na pytanie
  /// zadane werbalnie; tożsamość Kanonika pozostaje ukryta). `confess_round:<n>`
  /// ogranicza do raz na noc.
  Future<void> confess({required String code, required String actorId, required String targetName}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      final players = room.players.map((p) {
        if (p.id == actorId) {
          final cleaned = p.statuses.where((s) => !s.startsWith('confess_round:')).toList();
          return p.copyWith(statuses: _withStatus(cleaned, 'confess_round:${room.roundNumber}')).toMap();
        }
        if (p.name == targetName) {
          return p.copyWith(statuses: _withStatus(p.statuses, 'confessed')).toMap();
        }
        return p.toMap();
      }).toList();
      tx.update(doc, {'players': players});
    });
  }

  /// Effect resolution order: protection first, then poison, then antidote.
  int _effectPriority(String cardId) {
    switch (cardId) {
      case 'puppet':
      case 'not_this_time':
        return 0;
      case 'poisoned_whiskey':
        return 1;
      case 'antidote':
        return 2;
      default:
        return 3;
    }
  }

  /// Cards whose harmful effect on a target is cancelled by a defensive shield
  /// ('protected', granted by "Nie tym razem"/"Kukła").
  static const _negatable = {'poisoned_whiskey', 'handcuffs', 'enemy_of_mafia', 'blood_bond'};

  /// Returns a human reason if [a]'s negative effect is nullified by the target's
  /// shield; otherwise null. Shown on the played-cards feed.
  String? _negationReason(List<GamePlayer> players, PlayedPowerCardAction a) {
    if (!_negatable.contains(a.card.id)) return null;
    final target = a.targetPlayerName?.trim() ?? '';
    if (target.isEmpty) return null;
    final tp = players.where((p) => p.name == target);
    if (tp.isEmpty || !tp.first.statuses.contains('protected')) return null;
    return 'Cel „$target" był chroniony (Nie tym razem / Kukła) — efekt zniwelowany.';
  }

  List<String> _withStatus(List<String> s, String v) =>
      s.contains(v) ? s : [...s, v];

  List<GamePlayer> _addStatusTo(List<GamePlayer> players, Set<String> names, String status) {
    final targets = names.where((n) => n.isNotEmpty).toSet();
    if (targets.isEmpty) return players;
    return [
      for (final p in players)
        targets.contains(p.name) ? p.copyWith(statuses: _withStatus(p.statuses, status)) : p,
    ];
  }

  List<GamePlayer> _mapName(List<GamePlayer> players, String name, GamePlayer Function(GamePlayer) fn) {
    if (name.isEmpty) return players;
    return [for (final p in players) p.name == name ? fn(p) : p];
  }

  /// Employment: re-rolls the caster into a random class that still has a FREE
  /// slot (per the room's roleCounts). If nothing is free the card is wasted
  /// (players unchanged) — matching the card text.
  List<GamePlayer> _reassignRole(List<GamePlayer> players, String name, Map<MafiaRoleCardType, int> roleCounts) {
    if (name.isEmpty) return players;
    // Count current assignments, ignoring the caster (their slot frees up).
    final used = <MafiaRoleCardType, int>{};
    for (final p in players) {
      if (p.name != name && p.role != null) {
        used[p.role!] = (used[p.role!] ?? 0) + 1;
      }
    }
    final free = <MafiaRoleCardType>[
      for (final entry in roleCounts.entries)
        if (entry.key != MafiaRoleCardType.mafia && (used[entry.key] ?? 0) < entry.value) entry.key,
    ];
    if (free.isEmpty) return players; // no vacancy — card destroyed, no change
    final pick = free[math.Random().nextInt(free.length)];
    return _mapName(players, name, (p) => p.copyWith(role: pick));
  }

  /// Applies one card's automated effect. Death timing (poison), bond cascades
  /// and hand transfers are handled by _tickStatuses / _settleDeadHands; the
  /// vote-cancel (liberum_veto) + re-deal (new_deal) run at play time.
  List<GamePlayer> _applyCardEffect(
    List<GamePlayer> players,
    PlayedPowerCardAction action,
    Map<MafiaRoleCardType, int> roleCounts,
  ) {
    final id = action.card.id;
    final src = action.sourcePlayerName.trim();
    final t1 = action.targetPlayerName?.trim() ?? '';
    final t2 = action.secondTargetPlayerName?.trim() ?? '';

    switch (id) {
      case 'blood_bond':
        if (src.isEmpty || t1.isEmpty) return players;
        return [
          for (final p in players)
            if (p.name == src)
              p.copyWith(statuses: _withStatus(p.statuses, 'bound:$t1'))
            else if (p.name == t1)
              p.copyWith(statuses: _withStatus(p.statuses, 'bound:$src'))
            else
              p,
        ];
      case 'puppet':
      case 'not_this_time':
        return _addStatusTo(players, {src}, 'protected');
      case 'night_owl':
        return _addStatusTo(players, {src}, 'silenced');
      case 'poisoned_whiskey':
        return _mapName(players, t1, (p) => p.statuses.contains('protected') ? p : p.copyWith(statuses: _withStatus(p.statuses, 'poisoned')));
      case 'antidote':
        return _mapName(players, t1.isEmpty ? src : t1, (p) => p.copyWith(statuses: p.statuses.where((s) => s != 'poisoned' && s != 'poisoned2').toList()));
      case 'handcuffs':
        return _addStatusTo(players, {t1}, 'blocked');
      case 'watchful_eye':
        return _addStatusTo(players, {t1}, 'watched');
      case 'enemy_of_mafia':
        return _addStatusTo(players, {t1}, 'marked:$src');
      case 'in_your_hands':
        return _addStatusTo(players, {src}, 'bequeath:$t1');
      case 'election_day':
        return _addStatusTo(players, {t1, t2}, 'onballot');
      // intimidation is applied immediately at play time (forceVote), not here.
      // 'deal' swaps hands immediately at play time (see _registerPowerCard).
      case 'employment':
        return _reassignRole(players, src, roleCounts);
      // ---- Medieval edition cards (status-based effects) ----
      case 'cien_przeszlosci': // +1 poziom kompromitacji
        return _mapName(players, t1, (p) => p.copyWith(statuses: _raiseCompromise(p.statuses)));
      case 'zebrane_grzechy': // dowód (posiadacz = grający)
        return _addStatusTo(players, {t1}, 'dowod:$src');
      case 'pieczec_milczenia':
      case 'zawstydzenie':
        return _addStatusTo(players, {t1}, 'silenced');
      case 'czara_cykuty': // ≥1 kompromitacji → trucizna; czysta reputacja → traci losową kartę
        return _mapName(players, t1, (p) {
          if (p.statuses.contains('protected')) return p;
          final hasKomp = p.statuses.any((s) => s.startsWith('kompromitacja'));
          // hasKomp → poison (kills after a full day); brak kompromitacji → cel
          // traci jedną losową kartę z ręki (rozliczane w _settleForcedDiscards).
          return p.copyWith(statuses: _withStatus(p.statuses, hasKomp ? 'poisoned' : 'discard1'));
        });
      case 'antidotum_medyka': // leczy truciznę + zdejmuje 1 poziom kompromitacji
        return _mapName(players, t1.isEmpty ? src : t1, (p) {
          final st = p.statuses.where((s) => s != 'poisoned' && s != 'poisoned2').toList();
          return p.copyWith(statuses: _lowerCompromise(st));
        });
      case 'skrytobojca': // zabija, jeśli cel nie ma ochrony ANI przysięgi (paktu)
        return _mapName(players, t1, (p) {
          final shielded = p.statuses.contains('protected') || p.statuses.any((s) => s.startsWith('pakt:'));
          return (p.alive && !shielded) ? p.copyWith(alive: false) : p;
        });
      case 'przysiega_krwi': // pakt — żadne z dwojga nie może głosować przeciw drugiemu
        if (src.isEmpty || t1.isEmpty) return players;
        return [
          for (final p in players)
            if (p.name == src)
              p.copyWith(statuses: _withStatus(p.statuses, 'pakt:$t1'))
            else if (p.name == t1)
              p.copyWith(statuses: _withStatus(p.statuses, 'pakt:$src'))
            else
              p,
        ];
      case 'zerwany_sojusz': // kończy pakt/przysięgę po OBU stronach (nie tylko u celu)
        if (t1.isEmpty) return players;
        return [
          for (final p in players)
            if (p.name == t1)
              p.copyWith(statuses: p.statuses.where((s) => !s.startsWith('pakt:')).toList())
            else if (p.statuses.contains('pakt:$t1'))
              p.copyWith(statuses: p.statuses.where((s) => s != 'pakt:$t1').toList())
            else
              p,
        ];
      case 'zniszczone_dowody': // usuwa jeden dowód zebrany przeciwko tobie
        return _mapName(players, src, (p) {
          final idx = p.statuses.indexWhere((s) => s.startsWith('dowod:'));
          if (idx < 0) return p;
          final st = [...p.statuses]..removeAt(idx);
          return p.copyWith(statuses: st);
        });
      default:
        return players;
    }
  }

  /// Removes one kompromitacja level (3→2→1→none).
  List<String> _lowerCompromise(List<String> s) {
    final base = s.where((e) => !e.startsWith('kompromitacja')).toList();
    if (s.contains('kompromitacja3')) return [...base, 'kompromitacja2'];
    if (s.contains('kompromitacja2')) return [...base, 'kompromitacja1'];
    return base; // kompromitacja1 or none -> none
  }

  /// One-phase statuses that expire at the start of the next phase change.
  static const _transient = {'protected', 'blocked', 'silenced', 'watched', 'onballot', 'intimidated', 'trading', 'doublevote', 'sentenced', 'confessed'};

  List<GamePlayer> _expireTransient(List<GamePlayer> players) => [
        for (final p in players)
          p.copyWith(statuses: p.statuses.where((s) => !_transient.contains(s) && !s.startsWith('identity:') && !s.startsWith('gossip:')).toList()),
      ];

  /// Advances time-based statuses on a phase change: fresh poison ages, aged
  /// poison kills (unless cured meanwhile), then blood-bonds cascade the deaths.
  List<GamePlayer> _tickStatuses(List<GamePlayer> players) {
    final result = <GamePlayer>[];
    for (final p in players) {
      if (!p.alive) {
        result.add(p);
        continue;
      }
      final s = [...p.statuses];
      if (s.contains('poisoned2')) {
        s.removeWhere((e) => e == 'poisoned' || e == 'poisoned2');
        result.add(p.copyWith(alive: false, statuses: s));
      } else if (s.contains('poisoned')) {
        s.remove('poisoned');
        s.add('poisoned2');
        result.add(p.copyWith(statuses: s));
      } else {
        result.add(p);
      }
    }
    return _resolveBonds(result);
  }

  /// If a bonded player is dead, their partner dies too (to a fixpoint).
  List<GamePlayer> _resolveBonds(List<GamePlayer> players) {
    var result = players;
    for (var iter = 0; iter < 10; iter++) {
      final deadNames = result.where((p) => !p.alive).map((p) => p.name).toSet();
      final next = [
        for (final p in result)
          if (p.alive &&
              p.statuses.any((s) => s.startsWith('bound:') && deadNames.contains(s.substring(6))))
            p.copyWith(alive: false)
          else
            p,
      ];
      final before = result.where((p) => !p.alive).length;
      final after = next.where((p) => !p.alive).length;
      result = next;
      if (after == before) break;
    }
    return result;
  }

  /// Resolves automated class night-abilities when the night ends: Lekarz heals
  /// grant protection; Mafia/Szeryf kills apply unless the target is protected;
  /// Detektyw checks store a private result on the detective.
  List<GamePlayer> _resolveNightActions(List<GamePlayer> players) {
    final heals = <String>{};
    final kills = <String>{};
    for (final p in players) {
      for (final s in p.statuses) {
        if (s.startsWith('na:heal:')) heals.add(s.substring(8));
        if (s.startsWith('na:kill:')) kills.add(s.substring(8));
      }
    }
    // 1) heals -> protection (and cure poison — the card text lets "pomoc
    //    lekarza" save a poisoned player, not just Antidotum).
    var result = [
      for (final p in players)
        heals.contains(p.name)
            ? p.copyWith(statuses: [
                for (final s in p.statuses)
                  if (s != 'poisoned' && s != 'poisoned2' && s != 'protected') s,
                'protected',
              ])
            : p,
    ];
    // 2) kills -> death unless protected
    result = [
      for (final p in result)
        (p.alive && kills.contains(p.name) && !p.statuses.contains('protected'))
            ? p.copyWith(alive: false)
            : p,
    ];
    // 3) detective checks -> private result written onto the detective
    final roleByName = {for (final p in result) p.name: p.role};
    result = [for (final p in result) _writeCheckResult(p, roleByName)];
    // 3b) MEDIEVAL night actions: Emisariusz kompromitacja + Strażniczka dowód.
    final kompTargets = <String>{};
    final dowodByTarget = <String, List<String>>{};
    for (final p in players) {
      for (final s in p.statuses) {
        if (s.startsWith('na:komp:')) kompTargets.add(s.substring(8));
        if (s.startsWith('na:dowod:')) (dowodByTarget[s.substring(9)] ??= <String>[]).add(p.name);
      }
    }
    if (kompTargets.isNotEmpty || dowodByTarget.isNotEmpty) {
      result = [
        for (final p in result)
          _applyMedievalNight(p, kompTargets.contains(p.name), dowodByTarget[p.name] ?? const []),
      ];
    }
    // 4) clear the one-shot night-action markers
    result = [
      for (final p in result)
        p.copyWith(statuses: p.statuses.where((s) => !s.startsWith('na:')).toList()),
    ];
    return result;
  }

  GamePlayer _applyMedievalNight(GamePlayer p, bool compromise, List<String> dowodHolders) {
    var statuses = [...p.statuses];
    if (compromise) statuses = _raiseCompromise(statuses);
    for (final holder in dowodHolders) {
      final tag = 'dowod:$holder';
      if (!statuses.contains(tag)) statuses.add(tag);
    }
    return p.copyWith(statuses: statuses);
  }

  /// Raises a player's kompromitacja by one level (1→2→3, capped at 3).
  List<String> _raiseCompromise(List<String> s) {
    final base = s.where((e) => !e.startsWith('kompromitacja')).toList();
    if (s.contains('kompromitacja3')) return [...base, 'kompromitacja3'];
    if (s.contains('kompromitacja2')) return [...base, 'kompromitacja3'];
    if (s.contains('kompromitacja1')) return [...base, 'kompromitacja2'];
    return [...base, 'kompromitacja1'];
  }

  GamePlayer _writeCheckResult(GamePlayer p, Map<String, MafiaRoleCardType?> roleByName) {
    final check = p.statuses.firstWhere((s) => s.startsWith('na:check:'), orElse: () => '');
    if (check.isEmpty) return p;
    final target = check.substring(9);
    final isMafia = roleByName[target] == MafiaRoleCardType.mafia;
    final cleaned = p.statuses.where((s) => !s.startsWith('checkresult:')).toList()
      ..add('checkresult:$target:${isMafia ? 'mafia' : 'clean'}');
    return p.copyWith(statuses: cleaned);
  }

  /// A class uses its unique night ability. [kind] is 'kill' | 'heal' | 'check'.
  /// Stored on the actor as `na:<kind>:<targetName>` until the night resolves.
  Future<void> setNightAction({
    required String code,
    required String actorId,
    required String kind,
    required String targetName,
  }) async {
    if (targetName.isEmpty) return;
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players.map((p) {
          if (p.id != actorId) return p.toMap();
          final cleaned = p.statuses.where((s) => !s.startsWith('na:')).toList()
            ..add('na:$kind:$targetName');
          return p.copyWith(statuses: cleaned).toMap();
        }).toList(),
      });
    });
  }

  Future<void> resetToLobby(String code) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players
            .map((p) => p.copyWith(clearRole: true, alive: true, statuses: const []).toMap())
            .toList(),
        'status': RoomStatus.waiting.name,
        'phase': GamePhase.setup.name,
      });
    });
  }

  /// Host toggles whether a player is still alive (drives the roster + voting).
  Future<void> setPlayerAlive({
    required String code,
    required String playerId,
    required bool alive,
  }) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players
            .map((p) => p.id == playerId ? p.copyWith(alive: alive).toMap() : p.toMap())
            .toList(),
      });
    });
    await _settleDeadHands(code);
  }

  /// Host clears a player's active card-effect statuses.
  Future<void> clearPlayerStatuses({
    required String code,
    required String playerId,
  }) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players
            .map((p) => p.id == playerId ? p.copyWith(statuses: const []).toMap() : p.toMap())
            .toList(),
      });
    });
  }

  // ---- chat -----------------------------------------------------------------

  Stream<List<MafiaChatMessage>> watchMessages(
    String code, {
    required String myName,
  }) {
    return _roomDoc(code)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (q) => q.docs
              .map((d) =>
                  MafiaChatMessage.fromDoc(d.id, d.data(), myName: myName))
              .toList(),
        );
  }

  Future<void> sendMessage({
    required String code,
    required String channelId,
    required String senderName,
    required String text,
    String? imageBase64,
  }) {
    return _roomDoc(code).collection('messages').add({
      'channelId': channelId,
      'senderName': senderName,
      'text': text,
      'imageData': imageBase64,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isSystem': false,
    });
  }

  // ---- power-card actions ---------------------------------------------------

  Stream<List<PlayedPowerCardAction>> watchActions(String code) {
    return _roomDoc(code)
        .collection('actions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (q) =>
              q.docs.map((d) => PlayedPowerCardAction.fromMap(d.data())).toList(),
        );
  }

  Future<void> playPowerCard({
    required String code,
    required PlayedPowerCardAction action,
  }) {
    return _roomDoc(code).collection('actions').add(action.toMap());
  }

  // ---- player hands (dealt by the host) ------------------------------------

  /// Live hand for one player: rooms/{code}/hands/{playerId}.cards = [cardId...]
  Stream<List<PowerCardDefinition>> watchHand(String code, String playerId) {
    return _roomDoc(code).collection('hands').doc(playerId).snapshots().map((snap) {
      final ids = ((snap.data()?['cards'] as List?) ?? const []).cast<String>();
      return ids.map(cardById).toList(); // resolves base + medieval ids
    });
  }

  Future<void> assignCard({
    required String code,
    required String playerId,
    required String cardId,
  }) async {
    final ref = _roomDoc(code).collection('hands').doc(playerId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final cards = List<String>.from((snap.data()?['cards'] as List?) ?? const []);
      cards.add(cardId);
      tx.set(ref, {'cards': cards});
    });
  }

  Future<void> removeCard({
    required String code,
    required String playerId,
    required String cardId,
  }) async {
    final ref = _roomDoc(code).collection('hands').doc(playerId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final cards = List<String>.from((snap.data()?['cards'] as List?) ?? const []);
      cards.remove(cardId);
      tx.set(ref, {'cards': cards});
    });
  }

  /// Atomically removes ONE copy of [cardId] from a player's hand, returning
  /// whether a copy was actually present. Because the whole check-and-remove is
  /// a single transaction, two rapid plays of the same card can't both succeed —
  /// Firestore serialises them, so the second sees the emptied hand and returns
  /// false. This is what stops a single card's effect from being stacked by
  /// spam-tapping before the hand stream refreshes.
  Future<bool> consumeCard({
    required String code,
    required String playerId,
    required String cardId,
  }) async {
    final ref = _roomDoc(code).collection('hands').doc(playerId);
    return _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final cards = List<String>.from((snap.data()?['cards'] as List?) ?? const []);
      final idx = cards.indexOf(cardId);
      if (idx < 0) return false;
      cards.removeAt(idx);
      tx.set(ref, {'cards': cards});
      return true;
    });
  }

  /// Deal: swaps the two players' whole hands.
  Future<void> swapHands({required String code, required String aId, required String bId}) async {
    if (aId == bId) return;
    final aRef = _roomDoc(code).collection('hands').doc(aId);
    final bRef = _roomDoc(code).collection('hands').doc(bId);
    final aSnap = await aRef.get();
    final bSnap = await bRef.get();
    final aCards = List<String>.from((aSnap.data()?['cards'] as List?) ?? const []);
    final bCards = List<String>.from((bSnap.data()?['cards'] as List?) ?? const []);
    await aRef.set({'cards': bCards});
    await bRef.set({'cards': aCards});
  }

  // ---- currency + mini-game tasks ------------------------------------------

  DocumentReference<Map<String, dynamic>> _taskDoc(String code) =>
      _roomDoc(code).collection('tasks').doc('current');

  Stream<GameTask?> watchTask(String code) => _taskDoc(code).snapshots().map(
        (snap) => snap.exists ? GameTask.fromMap(snap.data()!) : null,
      );

  Stream<int> watchSubmissionCount(String code) => _taskDoc(code)
      .collection('submissions')
      .snapshots()
      .map((q) => q.docs.length);

  Future<void> _clearSubmissions(String code) async {
    final subs = await _taskDoc(code).collection('submissions').get();
    for (final doc in subs.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> createTask({required String code, required GameTask task}) async {
    await _clearSubmissions(code);
    await _taskDoc(code).set(task.toMap());
  }

  Future<void> startTask({required String code}) {
    return _taskDoc(code).update({
      'state': GameTaskState.active.name,
    });
  }

  Future<void> submitTask({
    required String code,
    required String playerId,
    required int value,
  }) async {
    // The host is Game Master only — never accept a task submission from them.
    final roomSnap = await _roomDoc(code).get();
    if (roomSnap.exists && GameRoom.fromMap(roomSnap.data()!).hostId == playerId) return;
    await _taskDoc(code).collection('submissions').doc(playerId).set({
      'value': value,
      'at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> clearTask(String code) async {
    await _clearSubmissions(code);
    await _taskDoc(code).delete();
  }

  // ---- group games (Familiada / Kalambury / Znajomi) — host-driven, synced ---

  DocumentReference<Map<String, dynamic>> _groupGameDoc(String code) =>
      _roomDoc(code).collection('state').doc('groupgame');

  Stream<Map<String, dynamic>?> watchGroupGame(String code) =>
      _groupGameDoc(code).snapshots().map((s) => s.exists ? s.data() : null);

  /// Host writes group-game state; players read it (merge keeps other keys).
  Future<void> updateGroupGame(String code, Map<String, dynamic> patch) =>
      _groupGameDoc(code).set(patch, SetOptions(merge: true));

  /// Assign a player to team 'A'/'B' (null clears) — merges into the groups map.
  Future<void> assignGroup(String code, String playerId, String? team) =>
      _groupGameDoc(code).set({
        'groups': {playerId: team},
      }, SetOptions(merge: true));

  /// Overwrite the whole group-game doc (fresh board + cleared scores/groups).
  Future<void> resetGroupGame(String code, Map<String, dynamic> fresh) =>
      _groupGameDoc(code).set(fresh);

  Future<void> awardMoney({
    required String code,
    required String playerId,
    required int amount,
  }) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final raw = (snap.data()?['wallets'] as Map?) ?? const {};
      final wallets = <String, int>{
        for (final e in raw.entries) e.key as String: (e.value as num).toInt(),
      };
      wallets[playerId] = (wallets[playerId] ?? 0) + amount;
      tx.update(doc, {'wallets': wallets});
    });
  }

  /// Host-side ranking + payouts. 1st place wins the prize card; the rest get
  /// decreasing money (2nd 30, 3rd 15, 4th 8, else 5). [nameById] maps every
  /// participant id to a display name for the result lines.
  Future<void> resolveTask({
    required String code,
    required Map<String, String> nameById,
  }) async {
    // Atomically CLAIM the task (active -> finished) so a double-tap or a stream
    // rebuild during the await can't run the payout twice (was awarding 2 cards).
    final claimed = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(_taskDoc(code));
      if (!snap.exists) return false;
      final t = GameTask.fromMap(snap.data()!);
      if (t.state != GameTaskState.active) return false; // already resolved/ing
      tx.update(_taskDoc(code), {'state': GameTaskState.finished.name});
      return true;
    });
    if (!claimed) return;

    final taskSnap = await _taskDoc(code).get();
    if (!taskSnap.exists) return;
    final task = GameTask.fromMap(taskSnap.data()!);

    // The host is Game Master only — exclude any stray host submission from ranking.
    final roomSnap = await _roomDoc(code).get();
    final hostId = roomSnap.exists ? GameRoom.fromMap(roomSnap.data()!).hostId : null;

    final subsSnap = await _taskDoc(code).collection('submissions').get();
    final subs = [
      for (final doc in subsSnap.docs)
        if (doc.id != hostId)
          (
            playerId: doc.id,
            value: (doc.data()['value'] as num?)?.toInt() ?? 0,
            at: (doc.data()['at'] as num?)?.toInt() ?? 0,
          ),
    ];

    // Quiz ranking: correct answers first (fastest wins), then the rest by time.
    final correct = subs.where((s) => s.value == (task.correctIndex ?? -1)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final wrong = subs.where((s) => s.value != (task.correctIndex ?? -1)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
    final ranked = [...correct, ...wrong];

    final lines = <String>[];
    String? winnerName;
    for (var i = 0; i < ranked.length; i++) {
      final pid = ranked[i].playerId;
      final name = nameById[pid] ?? 'Gracz';
      if (i == 0) {
        winnerName = name;
        await assignCard(code: code, playerId: pid, cardId: task.prizeCardId);
        lines.add('1. $name — zdobywa nagrodę (kartę mocy)');
      } else {
        final pay = _payout(i);
        if (pay > 0) {
          await awardMoney(code: code, playerId: pid, amount: pay);
        }
        lines.add('${i + 1}. $name — +$pay\$');
      }
    }

    await _taskDoc(code).update({
      'state': GameTaskState.finished.name,
      'resultLines': lines,
      'winnerName': winnerName,
    });
  }

  int _payout(int placeZeroBased) {
    switch (placeZeroBased) {
      case 1:
        return 30;
      case 2:
        return 15;
      case 3:
        return 8;
      default:
        return 5;
    }
  }

  // ---- auction (bid power cards with currency) ------------------------------

  DocumentReference<Map<String, dynamic>> _auctionDoc(String code) =>
      _roomDoc(code).collection('auction').doc('current');

  Stream<Auction?> watchAuction(String code) => _auctionDoc(code).snapshots().map(
        (snap) => snap.exists ? Auction.fromMap(snap.data()!) : null,
      );

  Future<void> startAuction({required String code, required String cardId}) {
    return _auctionDoc(code).set(
      Auction(cardId: cardId, state: AuctionState.open).toMap(),
    );
  }

  Future<void> placeBid({
    required String code,
    required String playerId,
    required int amount,
  }) async {
    await _db.runTransaction((tx) async {
      final aRef = _auctionDoc(code);
      final rRef = _roomDoc(code);
      final aSnap = await tx.get(aRef);
      final rSnap = await tx.get(rRef);
      if (!aSnap.exists) throw Exception('Brak aktywnej licytacji.');
      final auction = Auction.fromMap(aSnap.data()!);
      if (!auction.isOpen) throw Exception('Licytacja jest zamknięta.');
      final wallets = (rSnap.data()?['wallets'] as Map?) ?? const {};
      final balance = (wallets[playerId] as num?)?.toInt() ?? 0;
      if (amount > balance) throw Exception('Nie masz tyle kasy.');
      if (amount <= auction.highBid) {
        throw Exception('Musisz przebić ${auction.highBid}\$.');
      }
      final bids = Map<String, int>.from(auction.bids);
      bids[playerId] = amount;
      tx.update(aRef, {'bids': bids});
    });
  }

  Future<void> closeAuction({
    required String code,
    required Map<String, String> nameById,
  }) async {
    final snap = await _auctionDoc(code).get();
    if (!snap.exists) return;
    final auction = Auction.fromMap(snap.data()!);
    final winnerId = auction.highBidderId;
    final bid = auction.highBid;
    if (winnerId != null && bid > 0) {
      await awardMoney(code: code, playerId: winnerId, amount: -bid);
      await assignCard(code: code, playerId: winnerId, cardId: auction.cardId);
      await _auctionDoc(code).update({
        'state': AuctionState.closed.name,
        'winnerId': winnerId,
        'winnerName': nameById[winnerId] ?? 'Gracz',
        'winningBid': bid,
      });
    } else {
      await _auctionDoc(code).update({
        'state': AuctionState.closed.name,
        'winnerId': null,
        'winnerName': null,
        'winningBid': 0,
      });
    }
  }

  Future<void> clearAuction(String code) => _auctionDoc(code).delete();

  // ---- day voting ----------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _voteDoc(String code) =>
      _roomDoc(code).collection('votes').doc('current');

  Stream<VoteSession?> watchVote(String code) => _voteDoc(code).snapshots().map(
        (snap) => snap.exists ? VoteSession.fromMap(snap.data()!) : null,
      );

  Future<void> startVote(String code) => _voteDoc(code).set(
        VoteSession(state: VoteState.open, startedAt: DateTime.now()).toMap(),
      );

  /// One voter casts (or changes) their ballot. Merge-set keeps other voters'
  /// ballots intact and creates the doc/field if missing.
  Future<void> castVote({
    required String code,
    required String voterId,
    required String targetName,
  }) =>
      _voteDoc(code).set({
        'ballots': {voterId: targetName},
      }, SetOptions(merge: true));

  /// Zastraszanie (intimidation): immediately locks [forcedName]'s ballot onto
  /// [voteForName] for the current vote and flags them 'intimidated' so the
  /// voting UI shows the forced choice and prevents changing it.
  Future<void> forceVote({
    required String code,
    required String forcedName,
    required String voteForName,
  }) async {
    if (forcedName.isEmpty || voteForName.isEmpty) return;
    // Act ONLY on an existing, OPEN vote. Never merge-create the vote doc here:
    // a merge-set on a missing doc produced a `votes/current` with no `state`,
    // which reads back as VoteState.closed — a phantom, already-finished vote
    // popping up the moment the card was played ("odpala głosowanie i je kończy").
    final voteSnap = await _voteDoc(code).get();
    if (!voteSnap.exists || !VoteSession.fromMap(voteSnap.data()!).isOpen) return;
    final roomSnap = await _roomDoc(code).get();
    if (!roomSnap.exists) return;
    final room = GameRoom.fromMap(roomSnap.data()!);
    final forced = room.players.where((p) => p.name == forcedName);
    if (forced.isEmpty) return;
    final forcedId = forced.first.id;
    await _roomDoc(code).update({
      'players': room.players
          .map((p) => p.name == forcedName
              ? p.copyWith(statuses: _withStatus(p.statuses, 'intimidated')).toMap()
              : p.toMap())
          .toList(),
    });
    await _voteDoc(code).set({
      'ballots': {forcedId: voteForName},
    }, SetOptions(merge: true));
  }

  /// Ślubowanie Wierności: forces [forcedName] to copy [sourceId]'s current vote.
  Future<void> copyVote({
    required String code,
    required String forcedName,
    required String sourceId,
  }) async {
    final voteSnap = await _voteDoc(code).get();
    final ballots = (voteSnap.data()?['ballots'] as Map?) ?? const {};
    final srcVote = ballots[sourceId] as String?;
    if (srcVote == null) return; // caller hasn't voted yet
    await forceVote(code: code, forcedName: forcedName, voteForName: srcVote);
  }

  /// Closing a vote:
  ///  * a single top candidate is eliminated (bond deaths cascade);
  ///  * a tie in round 1 opens a runoff (2nd round) among the tied names only;
  ///  * a tie in the runoff (or no votes at all) eliminates nobody.
  Future<void> closeVote(String code) async {
    final voteSnap = await _voteDoc(code).get();
    if (!voteSnap.exists) return;
    final vote = VoteSession.fromMap(voteSnap.data()!);

    // Effective tally accounts for medieval cards: Podrobiona Pieczęć (vote x2)
    // and Skradziona Tożsamość (swaps incoming votes between two players).
    final rSnap0 = await _roomDoc(code).get();
    final room0 = rSnap0.exists ? GameRoom.fromMap(rSnap0.data()!) : null;
    final counts = room0 != null ? _effectiveTally(vote, room0) : vote.tally;
    final top = _topOf(counts);

    // Round-1 tie -> reopen as a runoff among the tied candidates only.
    if (top.length > 1 && !vote.isRunoff) {
      await _voteDoc(code).set(
        VoteSession(
          state: VoteState.open,
          startedAt: DateTime.now(),
          round: 2,
          runoffCandidates: top,
        ).toMap(),
      );
      return;
    }

    // Decisive result -> eliminate. A tie in the runoff or no votes -> nobody dies.
    final targetName = top.length == 1 ? top.first : null;

    // Trubadur reward hook: if the exiled player carried this cycle's gossip
    // marker, the Trubadur that gossiped them earns +15 Wpływów.
    String? gossipReward;
    if (targetName != null && room0 != null) {
      final tp = room0.players.where((p) => p.name == targetName).toList();
      if (tp.isNotEmpty) {
        final tag = tp.first.statuses.firstWhere((s) => s.startsWith('gossip:'), orElse: () => '');
        if (tag.isNotEmpty) gossipReward = tag.substring(7);
      }
    }

    if (targetName != null && targetName.trim().isNotEmpty) {
      await _db.runTransaction((tx) async {
        final rSnap = await tx.get(_roomDoc(code));
        if (!rSnap.exists) return;
        final room = GameRoom.fromMap(rSnap.data()!);
        var players = [
          for (final p in room.players)
            p.name == targetName ? p.copyWith(alive: false) : p,
        ];
        players = _resolveBonds(players);
        tx.update(_roomDoc(code), {
          'players': players.map((p) => p.toMap()).toList(),
        });
      });
    }
    await _voteDoc(code).update({'state': VoteState.closed.name});
    await _settleDeadHands(code);
    if (gossipReward != null) {
      await awardInfluence(code: code, playerId: gossipReward, amount: 15);
    }
  }

  /// Vote counts with medieval modifiers applied: `doublevote` voters count
  /// twice; `identity:<other>` swaps votes cast on the two paired players.
  Map<String, int> _effectiveTally(VoteSession vote, GameRoom room) {
    final byId = {for (final p in room.players) p.id: p};
    final remap = <String, String>{};
    for (final p in room.players) {
      final tag = p.statuses.firstWhere((s) => s.startsWith('identity:'), orElse: () => '');
      if (tag.isNotEmpty) {
        final other = tag.substring(9);
        remap[other] = p.name;
        remap[p.name] = other;
      }
    }
    final counts = <String, int>{};
    vote.ballots.forEach((voterId, name) {
      if (name.trim().isEmpty) return;
      final target = remap[name] ?? name;
      final weight = (byId[voterId]?.statuses.contains('doublevote') ?? false) ? 2 : 1;
      counts[target] = (counts[target] ?? 0) + weight;
    });
    return counts;
  }

  List<String> _topOf(Map<String, int> counts) {
    if (counts.isEmpty) return const [];
    final max = counts.values.reduce((a, b) => a > b ? a : b);
    return [for (final e in counts.entries) if (e.value == max) e.key];
  }

  /// Adds a one-off status tag to a player (e.g. 'doublevote', `identity:<name>`).
  Future<void> markStatus({required String code, required String playerId, required String status}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players
            .map((p) => p.id == playerId ? p.copyWith(statuses: _withStatus(p.statuses, status)).toMap() : p.toMap())
            .toList(),
      });
    });
  }

  /// Removes a single status tag from a player (e.g. consuming `plotka_shield`).
  Future<void> removeStatus({required String code, required String playerId, required String status}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players
            .map((p) => p.id == playerId ? p.copyWith(statuses: p.statuses.where((s) => s != status).toList()).toMap() : p.toMap())
            .toList(),
      });
    });
  }

  Future<void> clearVote(String code) => _voteDoc(code).delete();

  /// Kajdanki: immediately mark a player 'blocked' so they can't play cards
  /// (clears on the next phase change via _expireTransient).
  Future<void> blockCards({required String code, required String targetName}) async {
    final doc = _roomDoc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final room = GameRoom.fromMap(snap.data()!);
      tx.update(doc, {
        'players': room.players
            .map((p) => p.name == targetName && !p.statuses.contains('blocked')
                ? p.copyWith(statuses: [...p.statuses, 'blocked']).toMap()
                : p.toMap())
            .toList(),
      });
    });
  }

  /// After any death, move eliminated players' cards per their statuses:
  /// `bequeath:<name>` hands the whole hand over; `marked:<name>` hands one card.
  Future<void> _settleDeadHands(String code) async {
    final snap = await _roomDoc(code).get();
    if (!snap.exists) return;
    final room = GameRoom.fromMap(snap.data()!);
    final byName = {for (final p in room.players) p.name: p};
    final players = [...room.players];
    var changed = false;
    for (var i = 0; i < players.length; i++) {
      final p = players[i];
      if (p.alive) continue;
      final bequeath = p.statuses.firstWhere((s) => s.startsWith('bequeath:'), orElse: () => '');
      final marked = p.statuses.firstWhere((s) => s.startsWith('marked:'), orElse: () => '');
      if (bequeath.isEmpty && marked.isEmpty) continue;
      final handRef = _roomDoc(code).collection('hands').doc(p.id);
      final handSnap = await handRef.get();
      final cards = List<String>.from((handSnap.data()?['cards'] as List?) ?? const []);
      if (bequeath.isNotEmpty) {
        final ben = byName[bequeath.substring(9)];
        if (ben != null) {
          for (final c in cards) {
            await assignCard(code: code, playerId: ben.id, cardId: c);
          }
          await handRef.set({'cards': <String>[]});
        }
      } else if (marked.isNotEmpty) {
        final ben = byName[marked.substring(7)];
        if (ben != null && cards.isNotEmpty) {
          await assignCard(code: code, playerId: ben.id, cardId: cards.first);
          cards.removeAt(0);
          await handRef.set({'cards': cards});
        }
      }
      players[i] = p.copyWith(
        statuses: p.statuses.where((s) => !s.startsWith('bequeath:') && !s.startsWith('marked:')).toList(),
      );
      changed = true;
    }
    if (changed) {
      await _roomDoc(code).update({'players': players.map((p) => p.toMap()).toList()});
    }
  }

  /// New Deal: replace the caster's whole hand with fresh random cards.
  Future<void> redealHand({required String code, required String playerId, int count = 3}) async {
    final roomSnap = await _roomDoc(code).get();
    final medieval = roomSnap.exists && GameRoom.fromMap(roomSnap.data()!).edition.isMedieval;
    final pool = medieval ? MedievalCards.all : PowerCards.all;
    final ids = pool.map((c) => c.id).toList()..shuffle();
    await _roomDoc(code).collection('hands').doc(playerId).set({'cards': ids.take(count).toList()});
  }

  // ---- helpers --------------------------------------------------------------

  Future<String> _uniqueRoomCode() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = generateRoomCode();
      final snap = await _roomDoc(code).get();
      if (!snap.exists) return code;
    }
    return generateRoomCode();
  }

  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random.secure();
    return List.generate(5, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random().nextInt(999999);
    return '${prefix}_${timestamp}_$random';
  }
}
