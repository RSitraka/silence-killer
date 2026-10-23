/**
 * Modèle et règles du jeu (fonctions pures, sans interface).
 * Les règles de victoire sont en haut du fichier : modifiez-les ici.
 */

export type Role = 'citizen' | 'assassin';

export interface Player {
  name: string;
  /** Index dans la palette d'avatars : un joueur garde sa couleur. */
  colorIndex: number;
  role: Role;
  alive: boolean;
}

export const MIN_PLAYERS = 4;
export const MAX_PLAYERS = 20;

export const roleLabel = (r: Role) => (r === 'citizen' ? 'CITOYEN' : 'ASSASSIN');
export const teamName = (r: Role) => (r === 'citizen' ? 'Citoyens' : 'Assassins');

// ============================================================
//  RÈGLES DE VICTOIRE — modifiez ces deux fonctions pour changer le jeu.
// ============================================================

/**
 * Les assassins gagnent quand le nombre de citoyens vivants devient inférieur
 * ou égal au nombre d'assassins vivants + 1.
 *   • 1 assassin  → il gagne quand il reste 2 citoyens ;
 *   • 2 assassins → ils gagnent quand il reste 3 citoyens.
 */
export function assassinsHaveWon(aliveCitizens: number, aliveAssassins: number): boolean {
  return aliveAssassins > 0 && aliveCitizens <= aliveAssassins + 1;
}

/** Les citoyens gagnent quand plus aucun assassin n'est vivant. */
export function citizensHaveWon(_aliveCitizens: number, aliveAssassins: number): boolean {
  return aliveAssassins === 0;
}

/** Équipe gagnante, ou `null` si la partie continue (citoyens vérifiés en premier). */
export function checkVictory(players: Player[]): Role | null {
  if (players.length === 0) return null;
  const aliveCitizens = players.filter((p) => p.alive && p.role === 'citizen').length;
  const aliveAssassins = players.filter((p) => p.alive && p.role === 'assassin').length;
  if (citizensHaveWon(aliveCitizens, aliveAssassins)) return 'citizen';
  if (assassinsHaveWon(aliveCitizens, aliveAssassins)) return 'assassin';
  return null;
}

/**
 * Nombre maximal d'assassins : strictement moins de la moitié des joueurs, ET pas
 * de victoire immédiate des assassins au départ (5 joueurs → 1 seul assassin).
 */
export function maxAssassinsFor(playerCount: number): number {
  let max = 1;
  for (let a = 2; a * 2 < playerCount; a++) {
    if (assassinsHaveWon(playerCount - a, a)) break;
    max = a;
  }
  return max;
}

// ============================================================
//  Actions de la partie (renvoient toujours une nouvelle liste)
// ============================================================

/** Crée les joueurs dans l'ordre de saisie et tire les assassins au hasard. */
export function dealRoles(names: string[], assassinCount: number, random: () => number = Math.random): Player[] {
  const indexes = names.map((_, i) => i);
  // Mélange de Fisher-Yates.
  for (let i = indexes.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [indexes[i], indexes[j]] = [indexes[j], indexes[i]];
  }
  const assassins = new Set(indexes.slice(0, assassinCount));
  return names.map((name, i) => ({
    name,
    colorIndex: i,
    role: assassins.has(i) ? 'assassin' : 'citizen',
    alive: true,
  }));
}

export function setAlive(players: Player[], index: number, alive: boolean): Player[] {
  return players.map((p, i) => (i === index ? { ...p, alive } : p));
}

/**
 * Accusation :
 *   • accusé assassin → seul l'accusé est éliminé ;
 *   • accusé innocent → l'accusateur ET l'accusé sont éliminés.
 */
export function accuse(players: Player[], accuser: number, accused: number): { players: Player[]; guessed: boolean } {
  const guessed = players[accused].role === 'assassin';
  return {
    guessed,
    players: players.map((p, i) => (i === accused || (!guessed && i === accuser) ? { ...p, alive: false } : p)),
  };
}

/** Vérifie les prénoms : renvoie un message d'erreur par champ (ou null). */
export function validateNames(names: string[]): (string | null)[] {
  const errors: (string | null)[] = names.map(() => null);
  const seen = new Map<string, number>();
  names.forEach((raw, i) => {
    const name = raw.trim();
    if (!name) {
      errors[i] = 'Entre un prénom';
      return;
    }
    const key = name.toLocaleLowerCase('fr');
    const first = seen.get(key);
    if (first !== undefined) {
      errors[i] = 'Ce prénom est déjà pris';
      errors[first] ??= 'Ce prénom est déjà pris';
    } else {
      seen.set(key, i);
    }
  });
  return errors;
}
