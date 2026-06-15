import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/game_phase.dart';
import '../widgets/shared_widgets.dart';

class PhasesAppScreen extends StatelessWidget {
  const PhasesAppScreen({super.key, required this.phase, required this.onChangePhase});
  final GamePhase phase;
  final ValueChanged<GamePhase> onChangePhase;

  String name(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup: return 'Przygotowanie';
      case GamePhase.day: return 'Dzień';
      case GamePhase.night: return 'Noc';
      case GamePhase.voting: return 'Głosowanie';
      case GamePhase.finished: return 'Koniec gry';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Sterowanie grą', icon: Icons.settings_rounded),
        const SizedBox(height: 18),
        MafiaPanel(
          child: Column(
            children: [
              Text(name(phase).toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Przesuń w dół, aby zamknąć aplikację.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.white.withValues(alpha: 0.62), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        MafiaButton(text: 'Rozpocznij dzień', icon: Icons.wb_sunny_rounded, onPressed: () => onChangePhase(GamePhase.day)),
        const SizedBox(height: 12),
        MafiaButton(text: 'Rozpocznij noc', icon: Icons.nightlight_round, onPressed: () => onChangePhase(GamePhase.night)),
        const SizedBox(height: 12),
        MafiaButton(text: 'Głosowanie', icon: Icons.how_to_vote_rounded, onPressed: () => onChangePhase(GamePhase.voting)),
        const SizedBox(height: 12),
        MafiaButton(text: 'Zakończ grę', icon: Icons.flag_rounded, onPressed: () => onChangePhase(GamePhase.finished)),
      ],
    );
  }
}
