import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/responsive.dart';
import '../widgets/shared_widgets.dart';
import 'host_game_screen.dart';
import 'join_game_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MafiaBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: Responsive.contentMaxWidth(context),
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: Responsive.height(context) * 0.24),
                          NeonMafiaTitle(
                            fontSize: Responsive.mainTitleSize(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Work in progress',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: Responsive.isSmall(context) ? 28 : 34,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              shadows: const [
                                Shadow(color: Colors.white, blurRadius: 4),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: Responsive.isSmall(context) ? 48 : 64,
                          ),
                          MafiaButton(
                            text: 'Hostuj',
                            icon: Icons.groups_rounded,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HostGameScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          MafiaButton(
                            text: 'Dołącz do gry',
                            icon: Icons.login_rounded,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const JoinGameScreen(),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: Responsive.height(context) * 0.14),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
