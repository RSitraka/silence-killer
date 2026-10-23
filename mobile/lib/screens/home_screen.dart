import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_icons.dart';
import 'setup_screen.dart';
import 'tutorial_screen.dart';

/// Écran d'accueil : « Comment jouer ? » et « Jouer ».
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE8F1), AppColors.background, Color(0xFFE6F6FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Align(alignment: Alignment.topRight, child: MuteButton()),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        // Les deux personnages qui se dandinent.
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BounceIn(child: Wiggle(child: RoleIcon(role: Role.citizen, size: 120))),
                            SizedBox(width: 12),
                            BounceIn(
                              delay: Duration(milliseconds: 200),
                              child: Wiggle(phase: 2, child: RoleIcon(role: Role.assassin, size: 130)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const BounceIn(
                          delay: Duration(milliseconds: 300),
                          child: Text(
                            "Clin d'Œil\nAssassin",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 48,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                              color: AppColors.assassinPurple,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Le jeu du silence et des regards 👀',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 44),
                        SizedBox(
                          width: double.infinity,
                          child: BigButton(
                            label: 'Comment jouer ?',
                            emoji: '📖',
                            color: AppColors.citizenBlue,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TutorialScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: BigButton(
                            label: 'Jouer',
                            emoji: '🎲',
                            fontSize: 30,
                            color: AppColors.pink,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SetupScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
