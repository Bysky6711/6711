import 'dart:ui';
import 'package:flutter/material.dart';
import '../chat/mafia_chat_screen.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../data/card.dart';
import '../data/roles.dart';
import '../models/game_phase.dart';
import '../models/game_room.dart';
import '../services/local_room_service.dart';
import '../services/room_service.dart';
import '../ui_system/mafia_ios_system.dart';
import '../widgets/shared_widgets.dart';

class StartedGameScreen extends StatefulWidget {
  const StartedGameScreen({super.key, required this.room});
  final GameRoom room;

  @override
  State<StartedGameScreen> createState() => _StartedGameScreenState();
}

class _StartedGameScreenState extends State<StartedGameScreen> {
  late GameRoom room;
  final RoomService roomService = const LocalRoomService();

  @override
  void initState() {
    super.initState();
    room = widget.room;
  }

  void changePhase(GamePhase phase) {
    setState(() => room = roomService.changePhase(room: room, phase: phase));
  }

  void openApp(String title, IconData icon, Widget child) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 360),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => _IOSAppPage(title: title, icon: icon, child: child),
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(scale: Tween<double>(begin: .92, end: 1).animate(curved), child: child),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final playerNames = room.players.map((player) => player.name).toList();
    return MafiaIOSScaffold(
      child: PageView(
        physics: const BouncingScrollPhysics(),
        children: [
          _Home(
            room: room,
            onSettings: () => openApp('Ustawienia', Icons.settings_rounded, _PhaseApp(room: room, onChangePhase: changePhase)),
            onRules: () => openApp('Zasady', Icons.description_outlined, const _TextApp(title: 'Zasady', text: 'Gospodarz prowadzi rozgrywkę, zmienia fazy dnia i nocy oraz kontroluje zadania.')),
            onNotes: () => openApp('Notatki', Icons.edit_rounded, const _NotesApp()),
            onAvatar: () => openApp('Avatar', Icons.person_rounded, _PlayersApp(room: room)),
            onPower: () => openApp('Karty mocy', Icons.festival_rounded, const _PowerCardsApp()),
            onMyCard: () => openApp('Moja karta', Icons.festival_rounded, _RolesApp(room: room)),
            onMessages: () => openApp('Wiadomości', Icons.send_rounded, MafiaChatScreen(currentPlayerName: room.hostName, players: playerNames)),
            onTasks: () => openApp('Zadania', Icons.extension_rounded, const _TextApp(title: 'Zadania', text: 'Tutaj pojawią się misje, uczestnicy, zwycięzcy i nagrody w kartach mocy.')),
            onPremium: () => openApp('Premium', Icons.workspace_premium_rounded, const _TextApp(title: 'Premium', text: 'Tutaj pojawią się funkcje premium.')),
          ),
          _PhaseApp(room: room, onChangePhase: changePhase),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.room, required this.onSettings, required this.onRules, required this.onNotes, required this.onAvatar, required this.onPower, required this.onMyCard, required this.onMessages, required this.onTasks, required this.onPremium});
  final GameRoom room;
  final VoidCallback onSettings, onRules, onNotes, onAvatar, onPower, onMyCard, onMessages, onTasks, onPremium;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 22, Responsive.horizontalPadding(context), 22),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
          child: Column(children: [
            IOSGlass(
              radius: 28,
              opacity: .14,
              borderOpacity: .12,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const MafiaClockText(fontSize: 62, align: TextAlign.left),
                  const SizedBox(height: 8),
                  Text(phaseLabel(room.phase), style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                ])),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                  child: Icon(phaseIcon(room.phase), key: ValueKey(room.phase), color: AppColors.white, size: 72),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Wrap(spacing: 16, runSpacing: 20, alignment: WrapAlignment.center, children: [
              IOSAppIcon(label: 'ustawienia', icon: Icons.settings_rounded, onTap: onSettings),
              IOSAppIcon(label: 'zasady', icon: Icons.description_outlined, onTap: onRules),
              IOSCardIcon(label: 'karty mocy', assetPath: MafiaAssets.blueCard, color: MafiaPlayingCardColor.blue, onTap: onPower),
              IOSAppIcon(label: 'notatki', icon: Icons.edit_rounded, onTap: onNotes),
              IOSAppIcon(label: 'avatar', icon: Icons.person_rounded, onTap: onAvatar),
              IOSCardIcon(label: 'moja karta', assetPath: MafiaAssets.redCard, color: MafiaPlayingCardColor.red, onTap: onMyCard),
              IOSAppIcon(label: 'wiadomości', icon: Icons.send_rounded, badge: 1, onTap: onMessages),
              IOSAppIcon(label: 'zadania', icon: Icons.extension_rounded, onTap: onTasks),
              IOSAppIcon(label: 'premium', icon: Icons.workspace_premium_rounded, isPremium: true, onTap: onPremium),
              IOSAppIcon(label: 'menu', icon: Icons.home_rounded, onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _IOSAppPage extends StatelessWidget {
  const _IOSAppPage({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(title),
      direction: DismissDirection.down,
      resizeDuration: null,
      onDismissed: (_) => Navigator.of(context).maybePop(),
      child: MafiaIOSScaffold(
        darkOverlay: .10,
        child: Padding(
          padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 12, Responsive.horizontalPadding(context), 14),
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
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: .12)),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Container(width: 118, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(99))),
          ]),
        ),
      ),
    );
  }
}

class _PhaseApp extends StatelessWidget {
  const _PhaseApp({required this.room, required this.onChangePhase});
  final GameRoom room;
  final ValueChanged<GamePhase> onChangePhase;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), physics: const BouncingScrollPhysics(), children: [
      IOSGlass(opacity: .14, child: Column(children: [
        AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: Icon(phaseIcon(room.phase), key: ValueKey(room.phase), color: AppColors.white, size: 72)),
        const SizedBox(height: 8),
        Text(phaseLabel(room.phase).toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ])),
      const SizedBox(height: 16),
      MafiaButton(text: 'Rozpocznij dzień', icon: Icons.wb_sunny_rounded, onPressed: () => onChangePhase(GamePhase.day)),
      const SizedBox(height: 12),
      MafiaButton(text: 'Rozpocznij noc', icon: Icons.nightlight_round, onPressed: () => onChangePhase(GamePhase.night)),
      const SizedBox(height: 12),
      MafiaButton(text: 'Głosowanie', icon: Icons.how_to_vote_rounded, onPressed: () => onChangePhase(GamePhase.voting)),
      const SizedBox(height: 12),
      MafiaButton(text: 'Zakończ grę', icon: Icons.flag_rounded, onPressed: () => onChangePhase(GamePhase.finished)),
    ]);
  }
}

class _PlayersApp extends StatelessWidget {
  const _PlayersApp({required this.room});
  final GameRoom room;
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          SectionHeader(title: 'Gracze ${room.players.length}/${room.maxPlayers}', icon: Icons.people_alt_rounded),
          const SizedBox(height: 14),
          LobbyPlayerTile(name: room.hostName, isHost: true),
          ...room.players.map((p) => LobbyPlayerTile(name: p.name, isHost: false)),
        ],
      );
}

class _RolesApp extends StatelessWidget {
  const _RolesApp({required this.room});
  final GameRoom room;
  void openCard(BuildContext c, MafiaRoleCardType r) => Navigator.push(c, MaterialPageRoute(builder: (_) => RoleRevealScreen(roleType: r)));
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          IOSCardIcon(label: 'karta gospodarza', assetPath: MafiaAssets.blueCard, color: MafiaPlayingCardColor.blue, onTap: () => openCard(context, MafiaRoleCardType.host)),
          const SizedBox(height: 16),
          ...room.players.map((p) {
            final r = p.role;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MafiaPanel(
                child: Row(children: [
                  Expanded(child: Text(p.name, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900))),
                  Text(r == null ? 'Brak' : GameRoles.nameOf(r), style: TextStyle(color: AppColors.white.withValues(alpha: .72), fontWeight: FontWeight.w800)),
                  IconButton(onPressed: r == null ? null : () => openCard(context, r), icon: const Icon(Icons.visibility_rounded, color: AppColors.white)),
                ]),
              ),
            );
          }),
        ],
      );
}

class _PowerCardsApp extends StatelessWidget {
  const _PowerCardsApp();
  @override
  Widget build(BuildContext context) => GridView.builder(
        padding: const EdgeInsets.all(18),
        physics: const BouncingScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .72),
        itemBuilder: (_, __) => CardAsset(assetPath: MafiaAssets.blueCard, fallbackColor: MafiaPlayingCardColor.blue),
      );
}

class _TextApp extends StatelessWidget {
  const _TextApp({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          SectionHeader(title: title, icon: Icons.info_outline_rounded),
          const SizedBox(height: 14),
          MafiaPanel(child: Text(text, style: TextStyle(color: AppColors.white.withValues(alpha: .78), fontSize: 18, fontWeight: FontWeight.w700))),
        ],
      );
}

class _NotesApp extends StatelessWidget {
  const _NotesApp();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          maxLines: null,
          expands: true,
          style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Notatki gospodarza...',
            hintStyle: TextStyle(color: AppColors.white.withValues(alpha: .42)),
            filled: true,
            fillColor: Colors.black.withValues(alpha: .22),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          ),
        ),
      );
}
