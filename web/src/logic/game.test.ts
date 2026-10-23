import { describe, expect, it } from 'vitest';
import {
  accuse,
  assassinsHaveWon,
  checkVictory,
  dealRoles,
  MAX_PLAYERS,
  maxAssassinsFor,
  MIN_PLAYERS,
  type Player,
  validateNames,
} from './game';

/** [citizens] citoyens et [assassins] assassins vivants. */
const team = (citizens: number, assassins: number): Player[] => [
  ...Array.from({ length: citizens }, (_, i) => ({ name: `C${i}`, colorIndex: i, role: 'citizen' as const, alive: true })),
  ...Array.from({ length: assassins }, (_, i) => ({ name: `A${i}`, colorIndex: i, role: 'assassin' as const, alive: true })),
];

describe('checkVictory', () => {
  it('la partie continue au départ', () => {
    expect(checkVictory(team(3, 1))).toBeNull();
    expect(checkVictory(team(4, 2))).toBeNull();
  });
  it('les citoyens gagnent sans assassin vivant', () => {
    const players = team(3, 1);
    players[3].alive = false;
    expect(checkVictory(players)).toBe('citizen');
  });
  it('1 assassin gagne quand il reste 2 citoyens', () => {
    expect(checkVictory(team(2, 1))).toBe('assassin');
  });
  it('2 assassins gagnent quand il reste 3 citoyens', () => {
    expect(checkVictory(team(3, 2))).toBe('assassin');
  });
});

describe('maxAssassinsFor', () => {
  it('jamais de victoire immédiate des assassins', () => {
    for (let n = MIN_PLAYERS; n <= MAX_PLAYERS; n++) {
      const a = maxAssassinsFor(n);
      expect(a).toBeGreaterThanOrEqual(1);
      expect(a * 2).toBeLessThan(n);
      expect(assassinsHaveWon(n - a, a)).toBe(false);
    }
    expect(maxAssassinsFor(4)).toBe(1);
    expect(maxAssassinsFor(5)).toBe(1);
    expect(maxAssassinsFor(6)).toBe(2);
    expect(maxAssassinsFor(20)).toBe(9);
  });
});

describe('partie', () => {
  it('distribue le bon nombre d\'assassins dans l\'ordre de saisie', () => {
    const players = dealRoles(['Léa', 'Tom', 'Zoé', 'Noé', 'Ali', 'Max'], 2);
    expect(players.map((p) => p.name)).toEqual(['Léa', 'Tom', 'Zoé', 'Noé', 'Ali', 'Max']);
    expect(players.filter((p) => p.role === 'assassin')).toHaveLength(2);
  });

  it('accusation ratée : accusateur et accusé meurent', () => {
    const r = accuse(team(4, 1), 0, 1);
    expect(r.guessed).toBe(false);
    expect(r.players[0].alive || r.players[1].alive).toBe(false);
  });

  it('accusation réussie : seul l\'assassin meurt', () => {
    const r = accuse(team(4, 1), 0, 4);
    expect(r.guessed).toBe(true);
    expect(r.players[0].alive).toBe(true);
    expect(r.players[4].alive).toBe(false);
  });

  it('valide les prénoms vides et en double', () => {
    expect(validateNames(['Léa', ' ', 'léa', 'Tom'])).toEqual([
      'Ce prénom est déjà pris',
      'Entre un prénom',
      'Ce prénom est déjà pris',
      null,
    ]);
  });
});
