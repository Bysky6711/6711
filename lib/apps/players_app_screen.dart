import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/game_room.dart';
import '../widgets/shared_widgets.dart';

class PlayersAppScreen extends StatelessWidget {
  const PlayersAppScreen({super.key, required this.room});
  final GameRoom room;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(title: 'Gracze ${room.players.length}/${room.maxPlayers}', icon: Icons.people_alt_rounded),
        const SizedBox(height: 14),
        LobbyPlayerTile(name: room.hostName, isHost: true),
        ...List.generate(room.players.length, (index) {
          final player = room.players[index];
          return PremiumFadeSlide(
            delay: Duration(milliseconds: 35 * index),
            child: LobbyPlayerTile(name: player.name, isHost: false),
          );
        }),
        if (room.players.isEmpty)
          Text('Brak graczy w pokoju.', style: TextStyle(color: AppColors.white.withValues(alpha: 0.70), fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
