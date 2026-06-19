import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../ui_system/mafia_ios_system.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

enum _JoinStep { name, code }

class _JoinGameScreenState extends State<JoinGameScreen> {
  static const int codeLength = 6;
  final TextEditingController nameController = TextEditingController();
  _JoinStep step = _JoinStep.name;
  String code = '';

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void submitName() {
    if (nameController.text.trim().isEmpty) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wpisz nazwę gracza.')));
      return;
    }
    setState(() => step = _JoinStep.code);
    HapticFeedback.mediumImpact();
  }

  void addDigit(String digit) {
    if (code.length >= codeLength) return;
    setState(() => code += digit);
    HapticFeedback.selectionClick();
    if (code.length == codeLength) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dołączanie online będzie aktywne po podpięciu lobby.')));
    }
  }

  void removeDigit() {
    if (code.isEmpty) return;
    setState(() => code = code.substring(0, code.length - 1));
    HapticFeedback.selectionClick();
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
            : _CodeStep(key: const ValueKey('pin'), playerName: nameController.text.trim(), code: code, onDigit: addDigit, onBackspace: removeDigit, onBack: () => setState(() => step = _JoinStep.name)),
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
  const _CodeStep({super.key, required this.playerName, required this.code, required this.onDigit, required this.onBackspace, required this.onBack});
  static const int codeLength = 6;
  final String playerName;
  final String code;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
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
                LockClock(subtitle: playerName),
                const SizedBox(height: 24),
                LockGlassPanel(
                  child: Column(children: [
                    Text('KOD AUTORYZACJI', style: TextStyle(color: AppColors.white.withValues(alpha: .92), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(codeLength, (index) {
                        final filled = index < code.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 7),
                          width: filled ? 17 : 15,
                          height: filled ? 17 : 15,
                          decoration: BoxDecoration(color: filled ? AppColors.white : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: AppColors.white.withValues(alpha: filled ? 1 : .20), width: 2), boxShadow: filled ? [BoxShadow(color: AppColors.white.withValues(alpha: .42), blurRadius: 12)] : null),
                        );
                      }),
                    ),
                    const SizedBox(height: 30),
                    NumericPinPad(onDigit: onDigit, onBackspace: onBackspace),
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
