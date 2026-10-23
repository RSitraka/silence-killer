import 'dart:math';

import 'package:flutter/foundation.dart';

import '../logic/victory.dart';
import '../models/player.dart';

/// État global de la partie (configuration, rôles, vivants / morts).
class GameState extends ChangeNotifier {
  static const int minPlayers = 4;
  static const int maxPlayers = 20;

  final Random _random = Random();

  /// Noms saisis à la configuration (conservés pour « Rejouer »).
  List<String> _names = [];
  int _assassinCount = 1;
  List<Player> _players = [];

  List<String> get names => List.unmodifiable(_names);
  int get assassinCount => _assassinCount;
  List<Player> get players => List.unmodifiable(_players);
  List<Player> get alivePlayers => _players.where((p) => p.alive).toList();

  /// Les assassins (utile pour qu'un assassin connaisse ses complices).
  List<Player> get assassins => _players.where((p) => p.isAssassin).toList();

  /// Démarre une nouvelle partie avec ces noms et ce nombre d'assassins.
  void startGame(List<String> names, int assassinCount) {
    _names = List.of(names);
    _assassinCount = assassinCount;
    _dealRoles();
  }

  /// « Rejouer avec les mêmes joueurs » : nouvelle distribution des rôles.
  void replay() => _dealRoles();

  /// Crée les joueurs (dans l'ordre de saisie) et tire les assassins au hasard.
  void _dealRoles() {
    _players = [
      for (var i = 0; i < _names.length; i++) Player(name: _names[i], colorIndex: i),
    ];
    final indexes = List.generate(_players.length, (i) => i)..shuffle(_random);
    for (final i in indexes.take(_assassinCount)) {
      _players[i].role = Role.assassin;
    }
    notifyListeners();
  }

  /// Marque un joueur vivant ou mort (sert aussi à corriger une erreur).
  void setAlive(Player player, bool alive) {
    if (player.alive == alive) return;
    player.alive = alive;
    notifyListeners();
  }

  /// Applique le résultat d'une accusation et renvoie `true` si l'accusé
  /// était un assassin.
  ///   • Accusé assassin → seul l'accusé est éliminé.
  ///   • Accusé innocent → l'accusateur ET l'accusé sont éliminés.
  bool accuse(Player accuser, Player accused) {
    final guessed = accused.isAssassin;
    accused.alive = false;
    if (!guessed) accuser.alive = false;
    notifyListeners();
    return guessed;
  }

  /// Équipe gagnante, ou `null` si la partie continue.
  Role? get winner => _players.isEmpty ? null : checkVictory(_players);
}
