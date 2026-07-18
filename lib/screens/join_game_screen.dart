import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/edition_state.dart';
import '../core/responsive.dart';
import '../services/online_room_service.dart';
import '../ui_system/mafia_ios_system.dart';
import 'lobby_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

enum _JoinStep { name, code }

class _JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final OnlineRoomService roomService = OnlineRoomService();
  _JoinStep step = _JoinStep.name;
  bool joining = false;

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void submitName() {
    if (nameController.text.trim().isEmpty) {
      HapticFeedback.selectionClick();
      showMessage('Wpisz nazwę gracza.');
      return;
    }
    setState(() => step = _JoinStep.code);
    HapticFeedback.mediumImpact();
  }

  Future<void> submitCode() async {
    if (joining) return;
    final code = codeController.text.trim().toUpperCase();
    final name = nameController.text.trim();
    if (code.length < 5) {
      showMessage('Kod pokoju ma 5 znaków.');
      return;
    }
    setState(() => joining = true);
    try {
      final player = await roomService.joinRoom(code: code, playerName: name);
      // Theme the lobby by the room's edition BEFORE navigating, so a player
      // joining a medieval room sees the medieval background right away (even on
      // the initial loading frame) instead of a flash of the default red theme.
      final joinedRoom = await roomService.getRoom(code);
      if (!mounted) return;
      if (joinedRoom != null) activeEdition = joinedRoom.edition;
      HapticFeedback.mediumImpact();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LobbyScreen(roomCode: code, myPlayerId: player.id, isHost: false),
        ),
      );
    } catch (error) {
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MafiaIOSScaffold(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: step == _JoinStep.name
            ? _NameStep(key: const ValueKey('name'), controller: nameController, onSubmit: submitName)
            : _CodeStep(
                key: const ValueKey('code'),
                playerName: nameController.text.trim(),
                controller: codeController,
                joining: joining,
                onSubmit: submitCode,
                onBack: () => setState(() => step = _JoinStep.name),
              ),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({super.key, required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 18, Responsive.horizontalPadding(context), 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Align(alignment: Alignment.centerLeft, child: IOSBackButton(onTap: () => Navigator.pop(context))),
                const LockClock(subtitle: 'Dołącz do gry'),
                const SizedBox(height: 26),
                LockNotificationTile(title: 'Mafia', subtitle: 'Wpisz nazwę gracza', trailingIcon: Icons.arrow_upward_rounded, onTap: onSubmit),
                const SizedBox(height: 12),
                LockGlassPanel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nazwa gracza', style: TextStyle(color: AppColors.white.withValues(alpha: .76), fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    LockTextField(controller: controller, hint: 'Twój nick', onSubmitted: (_) => onSubmit()),
                    const SizedBox(height: 14),
                    LockButton(text: 'Dalej', icon: Icons.arrow_forward_rounded, light: true, onTap: onSubmit),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({super.key, required this.playerName, required this.controller, required this.joining, required this.onSubmit, required this.onBack});
  final String playerName;
  final TextEditingController controller;
  final bool joining;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 18, Responsive.horizontalPadding(context), 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Align(alignment: Alignment.centerLeft, child: IOSBackButton(onTap: onBack)),
                LockClock(subtitle: playerName.isEmpty ? 'Dołącz do gry' : playerName),
                const SizedBox(height: 24),
                LockGlassPanel(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('KOD POKOJU', style: TextStyle(color: AppColors.white.withValues(alpha: .92), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text('Poproś gospodarza o 5-znakowy kod pokoju.', style: TextStyle(color: AppColors.white.withValues(alpha: .60), fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 5,
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => onSubmit(),
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                        FilteringTextInputFormatter.allow(RegExp('[A-Z0-9]')),
                      ],
                      style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 10),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'ABCDE',
                        hintStyle: TextStyle(color: AppColors.white.withValues(alpha: .28), letterSpacing: 10),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Colors.white.withValues(alpha: .14))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    LockButton(text: joining ? 'Dołączanie…' : 'Dołącz', icon: Icons.login_rounded, light: true, onTap: onSubmit),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
    });
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}
