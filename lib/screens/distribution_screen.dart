import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/screen_awake.dart';
import '../services/sound_service.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_icons.dart';
import 'game_screen.dart';

/// Les étapes de la distribution secrète, pour chaque joueur.
enum _Phase {
  /// « Passe le téléphone à [NOM] ».
  pass,

  /// Le rôle est visible.
  reveal,

  /// Écran neutre de transition (rôle caché).
  hidden,

  /// Tout le monde a vu son rôle.
  ready,
}

/// Étape B — Distribution secrète des rôles (dans l'ordre de saisie).
///
/// Sécurité : le bouton retour est bloqué, et le rôle n'existe qu'à l'écran
/// « reveal ». Si l'application passe en arrière-plan pendant qu'un rôle est
/// affiché, il est immédiatement caché.
class DistributionScreen extends StatefulWidget {
  const DistributionScreen({super.key});

  @override
  State<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen> with WidgetsBindingObserver {
  int _index = 0;
  _Phase _phase = _Phase.pass;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    keepScreenOn(true);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // L'appli quitte le premier plan : on cache le rôle affiché.
    if (state != AppLifecycleState.resumed && _phase == _Phase.reveal) {
      setState(() => _phase = _Phase.pass);
    }
  }

  void _showRole() {
    if (_phase != _Phase.pass) return; // évite les doubles appuis
    context.read<SoundService>().play(Sfx.reveal);
    setState(() => _phase = _Phase.reveal);
  }

  void _hideRole() {
    if (_phase != _Phase.reveal) return; // un double appui ne doit pas sauter un joueur
    final count = context.read<GameState>().players.length;
    setState(() => _phase = _Phase.hidden);
    // Court écran neutre, puis joueur suivant (ou fin de la distribution).
    _transitionTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        if (_index + 1 < count) {
          _index++;
          _phase = _Phase.pass;
        } else {
          _phase = _Phase.ready;
        }
      });
    });
  }

  void _startGame() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const GameScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final players = game.players;
    final player = players[_index];

    final Widget content;
    final Color background;
    switch (_phase) {
      case _Phase.pass:
        background = const Color(0xFFFFF0D9);
        content = _PassView(
          player: player,
          index: _index,
          total: players.length,
          onConfirm: _showRole,
        );
      case _Phase.reveal:
        background = player.isAssassin ? const Color(0xFFF3E8FF) : const Color(0xFFE3F6FF);
        content = _RoleView(
          player: player,
          accomplices: game.assassins.where((a) => a != player).map((a) => a.name).toList(),
          onHide: _hideRole,
        );
      case _Phase.hidden:
        background = AppColors.background;
        content = const _HiddenView();
      case _Phase.ready:
        background = const Color(0xFFE5FAF0);
        content = _ReadyView(onStart: _startGame);
    }

    return PopScope(
      // Bouton retour Android bloqué pendant la distribution.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Pas de retour en arrière pendant la distribution 🤫', style: TextStyle(fontSize: 17)),
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: background,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(anim), child: child),
              ),
              child: KeyedSubtree(key: ValueKey('$_phase-$_index'), child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mise en page commune : contenu centré + bouton en bas.
class _Frame extends StatelessWidget {
  const _Frame({required this.children, this.button});

  final List<Widget> children;
  final Widget? button;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: children),
              ),
            ),
          ),
          if (button != null) SizedBox(width: double.infinity, child: button),
        ],
      ),
    );
  }
}

class _PassView extends StatelessWidget {
  const _PassView({required this.player, required this.index, required this.total, required this.onConfirm});

  final Player player;
  final int index;
  final int total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      button: BigButton(
        label: "C'est moi, voir mon rôle",
        emoji: '👀',
        color: AppColors.lavender,
        onPressed: onConfirm,
        sound: false,
      ),
      children: [
        Text('Joueur ${index + 1} / $total',
            style: const TextStyle(fontSize: 18, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        const Wiggle(child: Text('📱', style: TextStyle(fontSize: 80))),
        const SizedBox(height: 12),
        const Text('Passe le téléphone à', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        BounceIn(child: PlayerAvatar(colorIndex: player.colorIndex, size: 110)),
        const SizedBox(height: 12),
        // Le prénom tient toujours sur une ligne (réduit si besoin).
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            player.name,
            style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: AppColors.assassinPurple),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Les autres, ne regardez pas ! 🙈',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _RoleView extends StatelessWidget {
  const _RoleView({required this.player, required this.accomplices, required this.onHide});

  final Player player;
  final List<String> accomplices;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final assassin = player.isAssassin;
    final color = assassin ? AppColors.assassinPurple : AppColors.citizenBlue;
    return _Frame(
      button: BigButton(label: "J'ai retenu, cacher", emoji: '🙈', color: color, onPressed: onHide),
      children: [
        Text(player.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        BounceIn(child: Wiggle(child: RoleIcon(role: player.role, size: 200))),
        const SizedBox(height: 20),
        const Text('Tu es', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
        Text(
          player.role.label,
          style: TextStyle(fontSize: 52, fontWeight: FontWeight.w700, color: color, letterSpacing: 2),
        ),
        const SizedBox(height: 16),
        RoundCard(
          child: Text(
            assassin
                ? accomplices.isEmpty
                    ? "Tue en silence avec un clin d'œil 😉\nTu es le seul assassin !"
                    : "Tue en silence avec un clin d'œil 😉\n\n"
                        "Tes complices : ${accomplices.join(', ')}"
                : 'Ouvre grand les yeux 👀\net démasque les assassins !',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _HiddenView extends StatelessWidget {
  const _HiddenView();

  @override
  Widget build(BuildContext context) {
    return const _Frame(
      children: [
        BounceIn(child: Text('🙈', style: TextStyle(fontSize: 110))),
        SizedBox(height: 16),
        Text('Rôle caché !', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Chut… garde-le pour toi 🤫', style: TextStyle(fontSize: 20, color: AppColors.inkSoft)),
      ],
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return _Frame(
      button: BigButton(label: "C'est parti !", emoji: '🤫', color: AppColors.citizenGreen, onPressed: onStart),
      children: const [
        BounceIn(child: Wiggle(child: Text('🤫', style: TextStyle(fontSize: 120)))),
        SizedBox(height: 20),
        Text('Tout le monde est prêt ?',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
        SizedBox(height: 12),
        Text(
          'Silence… la partie commence !',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.assassinPurple),
        ),
        SizedBox(height: 20),
        RoundCard(
          child: Text(
            'Posez le téléphone au centre.\nOn ne parle plus, on se regarde 👀',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, height: 1.3),
          ),
        ),
      ],
    );
  }
}
