import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/screen_awake.dart';
import '../services/sound_service.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_icons.dart';
import 'distribution_screen.dart';

/// Étape D — Fin de partie : victoire, confettis et révélation des rôles.
class EndScreen extends StatefulWidget {
  const EndScreen({super.key});

  @override
  State<EndScreen> createState() => _EndScreenState();
}

class _EndScreenState extends State<EndScreen> {
  // Figé à l'ouverture : « Rejouer » redistribue les rôles avant la fin de la transition.
  late final Role _winner = context.read<GameState>().winner ?? Role.citizen;
  late final List<Player> _players = [...context.read<GameState>().players];

  @override
  void initState() {
    super.initState();
    keepScreenOn(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SoundService>().play(Sfx.victory);
    });
  }

  void _replay() {
    context.read<GameState>().replay();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DistributionScreen()));
  }

  void _home() => Navigator.popUntil(context, (route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final winner = _winner;
    final citizensWon = winner == Role.citizen;
    // Les gagnants d'abord, puis les autres.
    final players = [..._players]..sort((a, b) {
        final wa = a.role == winner ? 0 : 1;
        final wb = b.role == winner ? 0 : 1;
        return wa.compareTo(wb);
      });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _home();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: citizensWon
                  ? const [Color(0xFFCDEEFF), Color(0xFFDDF8EA), AppColors.background]
                  : const [Color(0xFFE9DDFF), Color(0xFFFFDDE5), AppColors.background],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: Confetti()),
              SafeArea(
                child: Column(
                  children: [
                    const Align(alignment: Alignment.topRight, child: MuteButton()),
                    BounceIn(child: Wiggle(child: RoleIcon(role: winner, size: 150))),
                    const SizedBox(height: 12),
                    BounceIn(
                      delay: const Duration(milliseconds: 200),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: 'Les '),
                            TextSpan(
                              text: winner.teamName.toUpperCase(),
                              style: TextStyle(
                                color: citizensWon ? AppColors.citizenBlue : AppColors.assassinPurple,
                              ),
                            ),
                            const TextSpan(text: '\nont gagné ! 🎉'),
                          ]),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 38, height: 1.1, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Voici les rôles de chacun :',
                        style: TextStyle(fontSize: 18, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        itemCount: players.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _RoleTile(player: players[i]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: BigButton(
                          label: 'Rejouer avec les mêmes joueurs',
                          emoji: '🔄',
                          fontSize: 20,
                          color: AppColors.pink,
                          onPressed: _replay,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: BigButton(
                          label: "Retour à l'accueil",
                          emoji: '🏠',
                          fontSize: 20,
                          color: AppColors.sky,
                          onPressed: _home,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final assassin = player.isAssassin;
    return RoundCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          RoleIcon(role: player.role, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                Text(
                  player.role.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: assassin ? AppColors.assassinPurple : AppColors.citizenBlue,
                  ),
                ),
              ],
            ),
          ),
          Text(player.alive ? '😊' : '👻', style: const TextStyle(fontSize: 30)),
        ],
      ),
    );
  }
}
