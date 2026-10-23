import '../models/player.dart';

/// ============================================================
///  RÈGLES DE VICTOIRE — modifiez ce fichier pour changer le jeu.
/// ============================================================

/// Règle de victoire des assassins.
///
/// Par défaut : les assassins gagnent quand le nombre de citoyens vivants
/// devient inférieur ou égal au nombre d'assassins vivants + 1.
///   • 1 assassin  → il gagne quand il reste 2 citoyens ;
///   • 2 assassins → ils gagnent quand il reste 3 citoyens.
bool assassinsHaveWon({required int aliveCitizens, required int aliveAssassins}) {
  return aliveAssassins > 0 && aliveCitizens <= aliveAssassins + 1;
}

/// Règle de victoire des citoyens : plus aucun assassin vivant.
bool citizensHaveWon({required int aliveCitizens, required int aliveAssassins}) {
  return aliveAssassins == 0;
}

/// Renvoie l'équipe gagnante, ou `null` si la partie continue.
/// La victoire des citoyens est vérifiée en premier.
Role? checkVictory(List<Player> players) {
  final aliveCitizens = players.where((p) => p.alive && !p.isAssassin).length;
  final aliveAssassins = players.where((p) => p.alive && p.isAssassin).length;

  if (citizensHaveWon(aliveCitizens: aliveCitizens, aliveAssassins: aliveAssassins)) {
    return Role.citizen;
  }
  if (assassinsHaveWon(aliveCitizens: aliveCitizens, aliveAssassins: aliveAssassins)) {
    return Role.assassin;
  }
  return null;
}

/// Nombre maximal d'assassins pour [playerCount] joueurs.
///
/// Deux contraintes : strictement moins de la moitié des joueurs, ET la partie
/// ne doit pas être gagnée par les assassins dès le départ (sinon, avec
/// 5 joueurs et 2 assassins, il resterait 3 citoyens = 2 + 1 → victoire immédiate).
int maxAssassinsFor(int playerCount) {
  var max = 1;
  for (var a = 2; a * 2 < playerCount; a++) {
    if (assassinsHaveWon(aliveCitizens: playerCount - a, aliveAssassins: a)) break;
    max = a;
  }
  return max;
}
