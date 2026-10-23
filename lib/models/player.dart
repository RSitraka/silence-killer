/// Les deux rôles possibles du jeu.
enum Role { citizen, assassin }

extension RoleLabel on Role {
  /// Libellé au singulier, en majuscules (« CITOYEN » / « ASSASSIN »).
  String get label => this == Role.citizen ? 'CITOYEN' : 'ASSASSIN';

  /// Nom de l'équipe au pluriel (« Citoyens » / « Assassins »).
  String get teamName => this == Role.citizen ? 'Citoyens' : 'Assassins';
}

/// Un joueur de la partie.
class Player {
  Player({required this.name, required this.colorIndex, this.role = Role.citizen});

  final String name;

  /// Index dans la palette d'avatars, pour qu'un joueur garde sa couleur.
  final int colorIndex;

  Role role;
  bool alive = true;

  bool get isAssassin => role == Role.assassin;
}
