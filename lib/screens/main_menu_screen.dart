import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../ui_system/mafia_ios_system.dart';
import 'host_game_screen.dart';
import 'join_game_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MafiaIOSScaffold(
      darkOverlay: .03,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context), vertical: 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LockClock(),
                      SizedBox(height: Responsive.height(context) * .06),
                      LockNotificationTile(
                        title: 'Mafia',
                        subtitle: 'Dołącz do gry',
                        trailingIcon: Icons.sports_esports_rounded,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinGameScreen())),
                      ),
                      const SizedBox(height: 12),
                      LockNotificationTile(
                        title: 'Mafia',
                        subtitle: 'Zostań gospodarzem',
                        trailingIcon: Icons.local_activity_rounded,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HostGameScreen())),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
