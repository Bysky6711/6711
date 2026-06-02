import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/responsive.dart';
import '../widgets/shared_widgets.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  final TextEditingController playerNameController = TextEditingController();
  final TextEditingController roomCodeController = TextEditingController();

  String? errorMessage;

  @override
  void dispose() {
    playerNameController.dispose();
    roomCodeController.dispose();
    super.dispose();
  }

  void joinGame() {
    final playerName = playerNameController.text.trim();
    final roomCode = roomCodeController.text.trim().toUpperCase();

    if (playerName.isEmpty) {
      setState(() {
        errorMessage = 'Podaj nazwę gracza.';
      });
      return;
    }

    if (roomCode.isEmpty) {
      setState(() {
        errorMessage = 'Podaj kod pokoju.';
      });
      return;
    }

    setState(() {
      errorMessage =
          'Dołączanie po kodzie dodamy przy prawdziwym lobby online. Na razie testuj lobby przez hostowanie.';
    });
  }

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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ScreenHeader(
                            title: 'Dołącz',
                            icon: Icons.login_rounded,
                            onBack: () => Navigator.pop(context),
                            showTitle: false,
                            showIcon: true,
                            largeIcon: true,
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 34 : 52,
                          ),

                          Text(
                            'Wejdź do miasta',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white,
                              fontSize: Responsive.isSmall(context) ? 36 : 46,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.2,
                              shadows: const [
                                Shadow(color: Colors.white, blurRadius: 5),
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 12,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Dołącz do pokoju gry',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cormorantGaramond(
                              color: Colors.white70,
                              fontSize: Responsive.isSmall(context) ? 22 : 26,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 0.8,
                            ),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 34 : 48,
                          ),

                          MafiaPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(
                                  title: 'Dane gracza',
                                  icon: Icons.person_outline_rounded,
                                  showIcon: false,
                                ),

                                const SizedBox(height: 22),

                                MafiaTextField(
                                  controller: playerNameController,
                                  label: 'Nazwa gracza',
                                  hint: 'np. Wiktor',
                                  mutedText: true,
                                ),

                                const SizedBox(height: 18),

                                MafiaTextField(
                                  controller: roomCodeController,
                                  label: 'Kod pokoju',
                                  hint: 'np. A7K9Q',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  mutedText: true,
                                ),

                                if (errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    errorMessage!,
                                    style: GoogleFonts.cormorantGaramond(
                                      color: Colors.redAccent,
                                      fontSize: 18,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                const HelpHint(
                                  text:
                                      'Na razie lokalne lobby testujemy z poziomu gospodarza.',
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: Responsive.isSmall(context) ? 28 : 40,
                          ),

                          MafiaButton(
                            text: 'Dołącz',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: joinGame,
                          ),
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
