import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/screen_awake.dart';
import '../services/sound_service.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_icons.dart';
import 'accuse_screen.dart';
import 'end_screen.dart';

/// Étape C — Partie en cours. Le téléphone est posé au centre.
/// Les rôles ne sont JAMAIS affichés sur cet écran.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _victoryDialogOpen = false;

  @override
  void initState() {
    super.initState();
    keepScreenOn(true);
  }

  Future<void> _quit() async {
    if (!await confirmQuit(context)) return;
    keepScreenOn(false);
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  /// Fenêtre « Mort / Vivant » pour un joueur.
  Future<void> _editStatus(Player player) async {
    final alive = await showDialog<bool>(
      context: context,
      builder: (_) => _StatusDialog(player: player),
    );
    if (alive == null || !mounted) return;
    final game = context.read<GameState>();
    if (player.alive == alive) return;
    game.setAlive(player, alive);
    final sounds = context.read<SoundService>();
    sounds.play(alive ? Sfx.reveal : Sfx.death);
    _checkVictory();
  }

  Future<void> _accuse() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AccuseScreen()));
    if (mounted) _checkVictory();
  }

  /// Vérifie les conditions de victoire après chaque changement de statut.
  Future<void> _checkVictory() async {
    final winner = context.read<GameState>().winner;
    if (winner == null || _victoryDialogOpen) return;
    _victoryDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Victoire des ${winner.teamName} ! 🎉',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 8),
            const Text(
              'Tout est correct ?\nSi quelqu\'un a été marqué par erreur, corrigez-le avant de révéler les rôles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: BigButton(
                label: 'Confirmer',
                emoji: '✅',
                color: AppColors.citizenGreen,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: BigButton(
                label: 'Corriger une erreur',
                emoji: '✏️',
                fontSize: 20,
                color: AppColors.peach,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ],
        ),
      ),
    );
    _victoryDialogOpen = false;
    if (confirmed == true && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EndScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final players = game.players;
    final alive = game.alivePlayers.length;

    return PopScope(
      // Retour Android : on demande confirmation avant de quitter.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quitter la partie',
            icon: const Icon(Icons.close_rounded, size: 30),
            onPressed: _quit,
          ),
          title: const Text('🤫 Silence…'),
          actions: const [MuteButton()],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Pill(text: '😊 $alive vivant${alive > 1 ? 's' : ''}', color: AppColors.mint),
                    const SizedBox(width: 10),
                    _Pill(
                      text: '👻 ${players.length - alive} mort${players.length - alive > 1 ? 's' : ''}',
                      color: AppColors.dead,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Touchez un joueur pour le déclarer mort ou vivant',
                style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: players.length,
                  itemBuilder: (context, i) => _PlayerCard(
                    player: players[i],
                    onTap: () => _editStatus(players[i]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: BigButton(
                    label: "J'accuse !",
                    emoji: '✋',
                    fontSize: 28,
                    color: AppColors.coral,
                    onPressed: alive >= 2 ? _accuse : null,
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
    );
  }
}

/// Grande carte arrondie d'un joueur : nom + statut (jamais le rôle).
class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.onTap});

  final Player player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final alive = player.alive;
    return Semantics(
      button: true,
      label: '${player.name}, ${alive ? 'vivant' : 'mort'}',
      child: Material(
        color: alive ? Colors.white : const Color(0xFFEDEAF1),
        borderRadius: BorderRadius.circular(32),
        elevation: alive ? 3 : 0,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                    child: child,
                  ),
                  child: PlayerAvatar(
                    key: ValueKey(alive),
                    colorIndex: player.colorIndex,
                    alive: alive,
                    size: 84,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: alive ? AppColors.ink : AppColors.inkSoft,
                  ),
                ),
                Text(
                  alive ? 'Vivant 😊' : 'Mort 💀',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: alive ? AppColors.citizenGreen : AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fenêtre « Mort 💀 / Vivant 😊 ».
/// Renvoie `true` (vivant), `false` (mort) ou `null` (annulé).
/// Pour « Mort », un compte à rebours de 2 secondes précède la validation.
class _StatusDialog extends StatefulWidget {
  const _StatusDialog({required this.player});

  final Player player;

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _countdown = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) Navigator.pop(context, false);
    });

  bool get _counting => _countdown.isAnimating || _countdown.isCompleted;

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(colorIndex: player.colorIndex, alive: player.alive, size: 90),
              const SizedBox(height: 10),
              Text(
                player.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              if (_counting) ..._buildCountdown() else ..._buildChoices(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChoices() => [
        SizedBox(
          width: double.infinity,
          child: BigButton(
            label: 'Mort',
            emoji: '💀',
            fontSize: 28,
            color: const Color(0xFF8E86A3),
            onPressed: () => setState(() {
              _countdown.forward();
            }),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: BigButton(
            label: 'Vivant',
            emoji: '😊',
            fontSize: 28,
            color: AppColors.citizenGreen,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
        ),
      ];

  /// Compte à rebours visuel de 2 secondes (cercle qui se vide + chiffre).
  List<Widget> _buildCountdown() => [
        SizedBox.square(
          dimension: 130,
          child: AnimatedBuilder(
            animation: _countdown,
            builder: (context, _) {
              final remaining = (2 - _countdown.value * 2).ceil().clamp(1, 2);
              return Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: 1 - _countdown.value,
                    strokeWidth: 12,
                    strokeCap: StrokeCap.round,
                    color: AppColors.assassinPurple,
                    backgroundColor: const Color(0xFFEDE3F7),
                  ),
                  Center(
                    child: Text(
                      '$remaining',
                      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        const Text('Un… deux… 💀', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(fontSize: 18, color: AppColors.inkSoft)),
        ),
      ];
}
