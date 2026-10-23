import { useEffect } from 'react';
import { useBack } from '../App';
import { RoleIcon } from '../components/Icons';
import { BigButton, Card, Confetti, MuteButton } from '../components/ui';
import { useSound } from '../hooks/sound';
import { roleLabel, type Player, type Role } from '../logic/game';

/** Étape D — Fin de partie : victoire, confettis et révélation des rôles. */
export function EndScreen({
  players,
  winner,
  onReplay,
  onHome,
}: {
  players: Player[];
  winner: Role;
  onReplay: () => void;
  onHome: () => void;
}) {
  const { play } = useSound();
  useEffect(() => play('victory'), [play]);
  useBack(onHome);

  const citizensWon = winner === 'citizen';
  // Les gagnants d'abord.
  const sorted = [...players].sort((a, b) => Number(a.role !== winner) - Number(b.role !== winner));

  return (
    <section className={`screen ${citizensWon ? 'end--citizens' : 'end--assassins'}`}>
      <Confetti />
      <div className="topbar topbar--end">
        <MuteButton />
      </div>
      <div className="center">
        <span className="bounce-in wiggle">
          <RoleIcon role={winner} size={140} />
        </span>
        <h1 className="end-title bounce-in" style={{ animationDelay: '0.2s' }}>
          Les{' '}
          <span style={{ color: citizensWon ? 'var(--citizen-blue)' : 'var(--assassin-purple)' }}>
            {citizensWon ? 'CITOYENS' : 'ASSASSINS'}
          </span>
          <br />
          ont gagné ! 🎉
        </h1>
        <p className="hint strong">Voici les rôles de chacun :</p>
      </div>
      <div className="scroll">
        <ul className="role-list">
          {sorted.map((p) => (
            <li key={p.name}>
              <Card className="role-tile">
                <RoleIcon role={p.role} size={54} />
                <div className="role-tile__text">
                  <strong>{p.name}</strong>
                  <span style={{ color: p.role === 'assassin' ? 'var(--assassin-purple)' : 'var(--citizen-blue)' }}>
                    {roleLabel(p.role)}
                  </span>
                </div>
                <span className="role-tile__status" aria-label={p.alive ? 'vivant' : 'mort'}>
                  {p.alive ? '😊' : '👻'}
                </span>
              </Card>
            </li>
          ))}
        </ul>
      </div>
      <div className="bottom stack">
        <BigButton label="Rejouer avec les mêmes joueurs" emoji="🔄" size="sm" color="var(--pink)" onClick={onReplay} />
        <BigButton label="Retour à l'accueil" emoji="🏠" size="sm" color="var(--sky)" onClick={onHome} />
      </div>
    </section>
  );
}
