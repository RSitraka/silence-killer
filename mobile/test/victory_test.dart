import 'package:clin_doeil_assassin/logic/victory.dart';
import 'package:clin_doeil_assassin/models/player.dart';
import 'package:clin_doeil_assassin/state/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Crée [citizens] citoyens et [assassins] assassins vivants.
List<Player> _team(int citizens, int assassins) => [
      for (var i = 0; i < citizens; i++) Player(name: 'C$i', colorIndex: i),
      for (var i = 0; i < assassins; i++) Player(name: 'A$i', colorIndex: i, role: Role.assassin),
    ];

void main() {
  group('checkVictory', () {
    test('la partie continue au départ', () {
      expect(checkVictory(_team(3, 1)), isNull);
      expect(checkVictory(_team(4, 2)), isNull);
    });

    test('les citoyens gagnent sans assassin vivant', () {
      final players = _team(3, 1)..last.alive = false;
      expect(checkVictory(players), Role.citizen);
    });

    test('1 assassin gagne quand il reste 2 citoyens', () {
      expect(checkVictory(_team(2, 1)), Role.assassin);
    });

    test('2 assassins gagnent quand il reste 3 citoyens', () {
      expect(checkVictory(_team(3, 2)), Role.assassin);
      expect(checkVictory(_team(4, 2)), isNull);
    });
  });

  group('maxAssassinsFor', () {
    test('jamais de victoire immédiate des assassins', () {
      for (var n = GameState.minPlayers; n <= GameState.maxPlayers; n++) {
        final a = maxAssassinsFor(n);
        expect(a, greaterThanOrEqualTo(1));
        expect(a * 2, lessThan(n));
        expect(assassinsHaveWon(aliveCitizens: n - a, aliveAssassins: a), isFalse, reason: '$n joueurs');
      }
      expect(maxAssassinsFor(4), 1);
      expect(maxAssassinsFor(5), 1);
      expect(maxAssassinsFor(6), 2);
      expect(maxAssassinsFor(20), 9);
    });
  });

  group('GameState', () {
    test('distribue le bon nombre d\'assassins et gère les accusations', () {
      final game = GameState()..startGame(['Léa', 'Tom', 'Zoé', 'Noé', 'Ali', 'Max'], 2);
      expect(game.assassins.length, 2);

      final assassin = game.assassins.first;
      final citizen = game.players.firstWhere((p) => !p.isAssassin);
      final other = game.players.firstWhere((p) => !p.isAssassin && p != citizen);

      // Accusation ratée : l'accusateur et l'accusé meurent.
      expect(game.accuse(citizen, other), isFalse);
      expect(citizen.alive || other.alive, isFalse);

      // Accusation réussie : seul l'assassin meurt.
      final accuser = game.alivePlayers.firstWhere((p) => !p.isAssassin);
      expect(game.accuse(accuser, assassin), isTrue);
      expect(accuser.alive, isTrue);
      expect(assassin.alive, isFalse);
    });

    test('rejouer redistribue avec les mêmes noms', () {
      final game = GameState()..startGame(['A', 'B', 'C', 'D'], 1);
      game.players.first.alive = false;
      game.replay();
      expect(game.players.map((p) => p.name), ['A', 'B', 'C', 'D']);
      expect(game.players.every((p) => p.alive), isTrue);
      expect(game.assassins.length, 1);
    });
  });
}
