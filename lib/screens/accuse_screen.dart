import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../services/sound_service.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_icons.dart';

enum _Step { accuser, accused, suspense, reveal }

/// « J'accuse ! ✋ » : choix de l'accusateur, de l'accusé, suspense, révélation.
/// Le vote lui-même se fait oralement entre les joueurs.
class AccuseScreen extends StatefulWidget {
  const AccuseScreen({super.key});

  @override
  State<AccuseScreen> createState() => _AccuseScreenState();
}

class _AccuseScreenState extends State<AccuseScreen> {
  _Step _step = _Step.accuser;
  Player? _accuser;
  Player? _accused;
  bool _guessed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pickAccuser(Player p) => setState(() {
        _accuser = p;
        _step = _Step.accused;
      });

  void _pickAccused(Player p) {
    if (_step != _Step.accused) return;
    final sounds = context.read<SoundService>();
    setState(() {
      _accused = p;
      _step = _Step.suspense;
    });
    // Roulement de tambour pendant 2 secondes, puis révélation.
    sounds.play(Sfx.drumroll);
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _guessed = context.read<GameState>().accuse(_accuser!, _accused!);
      sounds.play(_guessed ? Sfx.success : Sfx.fail);
      setState(() => _step = _Step.reveal);
    });
  }

  /// Retour Android : revient à l'étape précédente (bloqué pendant le suspense).
  void _onBack() {
    switch (_step) {
      case _Step.accuser:
      case _Step.reveal:
        Navigator.pop(context);
      case _Step.accused:
        setState(() => _step = _Step.accuser);
      case _Step.suspense:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alive = context.watch<GameState>().alivePlayers;

    final Widget body = switch (_step) {
      _Step.accuser => _PickList(
          title: 'Qui accuse ? ✋',
          subtitle: 'Choisis le joueur qui a levé la main',
          players: alive,
          onPick: _pickAccuser,
        ),
      _Step.accused => _PickList(
          title: '${_accuser!.name} accuse…',
          subtitle: 'Choisis le joueur soupçonné 🔍',
          players: alive.where((p) => p != _accuser).toList(),
          onPick: _pickAccused,
        ),
      _Step.suspense => _SuspenseView(accused: _accused!),
      _Step.reveal => _RevealView(
          accuser: _accuser!,
          accused: _accused!,
          guessed: _guessed,
          onContinue: () => Navigator.pop(context),
        ),
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: switch (_step) {
          _Step.reveal => _guessed ? const Color(0xFFE5FAF0) : const Color(0xFFFFE9E9),
          _Step.suspense => const Color(0xFF2E1A55),
          _ => const Color(0xFFFFEDE3),
        },
        appBar: _step == _Step.accuser || _step == _Step.accused
            ? AppBar(
                title: const Text("J'accuse !"),
                leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _onBack),
              )
            : null,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: KeyedSubtree(key: ValueKey(_step), child: body),
          ),
        ),
      ),
    );
  }
}

/// Liste de gros boutons « joueur » à choisir.
class _PickList extends StatelessWidget {
  const _PickList({required this.title, required this.subtitle, required this.players, required this.onPick});

  final String title;
  final String subtitle;
  final List<Player> players;
  final ValueChanged<Player> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 18, color: AppColors.inkSoft)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = players[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                elevation: 2,
                shadowColor: Colors.black26,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    context.read<SoundService>().play(Sfx.tap);
                    onPick(p);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        PlayerAvatar(colorIndex: p.colorIndex, size: 56),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                        ),
                        const Icon(Icons.chevron_right_rounded, size: 32, color: AppColors.inkSoft),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Animation de suspense : tambour qui tremble pendant 2 secondes.
class _SuspenseView extends StatefulWidget {
  const _SuspenseView({required this.accused});

  final Player accused;

  @override
  State<_SuspenseView> createState() => _SuspenseViewState();
}

class _SuspenseViewState extends State<_SuspenseView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.rotate(
              angle: (_c.value - 0.5) * 0.25,
              child: Transform.scale(scale: 1 + _c.value * 0.08, child: child),
            ),
            child: const Text('🥁', style: TextStyle(fontSize: 130)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Roulement de tambour…',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.accused.name} est-il un assassin ?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, color: AppColors.lavender, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Révélation du résultat de l'accusation.
class _RevealView extends StatelessWidget {
  const _RevealView({
    required this.accuser,
    required this.accused,
    required this.guessed,
    required this.onContinue,
  });

  final Player accuser;
  final Player accused;
  final bool guessed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (guessed) const Positioned.fill(child: Confetti(count: 50)),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BounceIn(child: RoleIcon(role: accused.role, size: 190)),
                        const SizedBox(height: 24),
                        Text(
                          guessed ? 'Bien vu !' : 'Raté !',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: guessed ? AppColors.citizenGreen : AppColors.coral,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          guessed ? '${accused.name} était un assassin !' : '${accused.name} était innocent…',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                        RoundCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!guessed) ...[
                                _Eliminated(player: accuser),
                                const SizedBox(width: 20),
                              ],
                              _Eliminated(player: accused),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          guessed
                              ? "L'assassin est éliminé 🎉"
                              : "L'accusateur ET l'accusé sont éliminés 💀",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 19, color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: BigButton(
                  label: 'Continuer',
                  emoji: '👉',
                  color: guessed ? AppColors.citizenGreen : AppColors.lavender,
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Eliminated extends StatelessWidget {
  const _Eliminated({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlayerAvatar(colorIndex: player.colorIndex, alive: false, size: 64),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: min(130, MediaQuery.sizeOf(context).width / 3)),
          child: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
