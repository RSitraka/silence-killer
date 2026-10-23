import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/victory.dart';
import '../models/player.dart';
import '../state/game_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/role_icons.dart';
import 'distribution_screen.dart';

/// Étape A — Configuration : nombre de joueurs, prénoms, nombre d'assassins.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final List<TextEditingController> _controllers = [];
  int _playerCount = GameState.minPlayers;
  int _assassins = 1;

  /// Erreur affichée sous chaque champ (null = pas d'erreur).
  List<String?> _errors = [];

  @override
  void initState() {
    super.initState();
    // On pré-remplit avec les noms de la partie précédente, s'il y en a.
    final game = context.read<GameState>();
    final previous = game.names;
    _playerCount = previous.length.clamp(GameState.minPlayers, GameState.maxPlayers);
    _assassins = game.assassinCount.clamp(1, maxAssassinsFor(_playerCount));
    _resizeControllers();
    for (var i = 0; i < previous.length && i < _controllers.length; i++) {
      _controllers[i].text = previous[i];
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Ajuste le nombre de champs de saisie au nombre de joueurs.
  void _resizeControllers() {
    while (_controllers.length < _playerCount) {
      _controllers.add(TextEditingController());
    }
    while (_controllers.length > _playerCount) {
      _controllers.removeLast().dispose();
    }
    _errors = List.filled(_playerCount, null);
  }

  void _setPlayerCount(int n) {
    setState(() {
      _playerCount = n;
      _resizeControllers();
      _assassins = _assassins.clamp(1, maxAssassinsFor(n));
    });
  }

  /// Vérifie que les noms sont non vides et tous différents.
  bool _validate() {
    final names = _controllers.map((c) => c.text.trim()).toList();
    final errors = List<String?>.filled(names.length, null);
    final seen = <String, int>{};
    for (var i = 0; i < names.length; i++) {
      if (names[i].isEmpty) {
        errors[i] = 'Entre un prénom';
        continue;
      }
      final key = names[i].toLowerCase();
      if (seen.containsKey(key)) {
        errors[i] = 'Ce prénom est déjà pris';
        errors[seen[key]!] ??= 'Ce prénom est déjà pris';
      } else {
        seen[key] = i;
      }
    }
    setState(() => _errors = errors);
    return errors.every((e) => e == null);
  }

  void _distribute() {
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Oups ! Vérifie les prénoms 🙂', style: TextStyle(fontSize: 18)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    context.read<GameState>().startGame(
          _controllers.map((c) => c.text.trim()).toList(),
          _assassins,
        );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DistributionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final maxAssassins = maxAssassinsFor(_playerCount);
    final citizens = _playerCount - _assassins;

    return Scaffold(
      appBar: AppBar(title: const Text('Préparation'), actions: const [MuteButton()]),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // ---- Nombre de joueurs ----
                  RoundCard(
                    child: Column(
                      children: [
                        const Text('👥 Combien de joueurs ?',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        NumberStepper(
                          value: _playerCount,
                          min: GameState.minPlayers,
                          max: GameState.maxPlayers,
                          onChanged: _setPlayerCount,
                          color: AppColors.sky,
                        ),
                        const Text('de 4 à 20 joueurs', style: TextStyle(color: AppColors.inkSoft, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Prénoms ----
                  RoundCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('✏️ Les prénoms',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _playerCount; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: PlayerAvatar(colorIndex: i, size: 48),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _controllers[i],
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction:
                                        i == _playerCount - 1 ? TextInputAction.done : TextInputAction.next,
                                    maxLength: 16,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                                    onChanged: (_) {
                                      if (_errors[i] != null) setState(() => _errors[i] = null);
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Joueur ${i + 1}',
                                      counterText: '',
                                      errorText: _errors[i],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---- Nombre d'assassins ----
                  RoundCard(
                    child: Column(
                      children: [
                        const Text("🥷 Combien d'assassins ?",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        NumberStepper(
                          value: _assassins,
                          min: 1,
                          max: maxAssassins,
                          onChanged: (v) => setState(() => _assassins = v),
                          color: AppColors.assassinPurple,
                        ),
                        Text(
                          'maximum $maxAssassins pour $_playerCount joueurs',
                          style: const TextStyle(color: AppColors.inkSoft, fontSize: 16),
                        ),
                        const SizedBox(height: 14),
                        // Récapitulatif calculé automatiquement.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CountChip(role: Role.citizen, count: citizens),
                            _CountChip(role: Role.assassin, count: _assassins),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: BigButton(
                  label: 'Distribuer les rôles',
                  emoji: '🃏',
                  color: AppColors.pink,
                  onPressed: _distribute,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.role, required this.count});

  final Role role;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isCitizen = role == Role.citizen;
    final name = isCitizen ? 'citoyen' : 'assassin';
    return Column(
      children: [
        RoleIcon(role: role, size: 64),
        const SizedBox(height: 4),
        Text(
          '$count $name${count > 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isCitizen ? AppColors.citizenBlue : AppColors.assassinPurple,
          ),
        ),
      ],
    );
  }
}
