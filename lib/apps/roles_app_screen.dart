import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/card.dart';
import '../data/roles.dart';
import '../models/game_room.dart';
import '../widgets/shared_widgets.dart';

class RolesAppScreen extends StatelessWidget {
  const RolesAppScreen({super.key, required this.room});
  final GameRoom room;

  void openCard(BuildContext context, MafiaRoleCardType role) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RoleRevealScreen(roleType: role)));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Karty i role', icon: Icons.style_rounded),
        const SizedBox(height: 14),
        MafiaButton(text: 'Karta gospodarza', icon: Icons.local_activity_rounded, onPressed: () => openCard(context, MafiaRoleCardType.host)),
        const SizedBox(height: 14),
        ...List.generate(room.players.length, (index) {
          final player = room.players[index];
          final role = player.role;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MafiaPanel(
              child: Row(
                children: [
                  Expanded(child: Text(player.name, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w900))),
                  Text(role == null ? 'Brak' : GameRoles.nameOf(role), style: TextStyle(color: AppColors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  IconButton(onPressed: role == null ? null : () => openCard(context, role), icon: const Icon(Icons.visibility_rounded, color: AppColors.white)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
