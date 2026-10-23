import { useCallback, useEffect, useRef, useState } from 'react';
import { useBack } from '../App';
import { PlayerAvatar, RoleIcon } from '../components/Icons';
import { BigButton, Card, Toast } from '../components/ui';
import { useOnHidden } from '../hooks/browser';
import { useSound } from '../hooks/sound';
import { roleLabel, type Player } from '../logic/game';

/** Étapes de la distribution, pour chaque joueur. */
type Phase = 'pass' | 'reveal' | 'hidden' | 'ready';

/**
 * Étape B — Distribution secrète des rôles (dans l'ordre de saisie).
 *
 * Sécurité : le retour navigateur est bloqué, le rôle n'existe qu'en phase
 * « reveal », et il est caché dès que l'onglet passe en arrière-plan.
 */
export function DistributionScreen({ players, onDone }: { players: Player[]; onDone: () => void }) {
  const [index, setIndex] = useState(0);
  const [phase, setPhase] = useState<Phase>('pass');
  const [toast, setToast] = useState<string | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout>>();
  const { play } = useSound();

  useBack(() => setToast('Pas de retour en arrière pendant la distribution 🤫'));
  useOnHidden(() => setPhase((p) => (p === 'reveal' ? 'pass' : p)));
  useEffect(() => () => clearTimeout(timer.current), []);

  const player = players[index];
  const accomplices = players.filter((p) => p.role === 'assassin' && p !== player).map((p) => p.name);

  const showRole = () => {
    if (phase !== 'pass') return; // évite les doubles appuis
    play('reveal');
    setPhase('reveal');
  };

  const hideRole = () => {
    if (phase !== 'reveal') return; // un double appui ne doit pas sauter un joueur
    setPhase('hidden');
    // Court écran neutre, puis joueur suivant (ou fin de la distribution).
    timer.current = setTimeout(() => {
      if (index + 1 < players.length) {
        setIndex(index + 1);
        setPhase('pass');
      } else {
        setPhase('ready');
      }
    }, 1400);
  };

  const clearToast = useCallback(() => setToast(null), []);

  const background = {
    pass: '#FFF0D9',
    reveal: player.role === 'assassin' ? '#F3E8FF' : '#E3F6FF',
    hidden: 'var(--background)',
    ready: '#E5FAF0',
  }[phase];

  return (
    <section className="screen" style={{ background }}>
      <div key={`${phase}-${index}`} className="frame fade-in">
        {phase === 'pass' && (
          <>
            <div className="frame__body">
              <p className="hint strong">
                Joueur {index + 1} / {players.length}
              </p>
              <span className="wiggle big-emoji">📱</span>
              <p className="lead">Passe le téléphone à</p>
              <span className="bounce-in">
                <PlayerAvatar colorIndex={player.colorIndex} size={110} />
              </span>
              <p className="player-name">{player.name}</p>
              <p className="hint">Les autres, ne regardez pas ! 🙈</p>
            </div>
            <BigButton label="C'est moi, voir mon rôle" emoji="👀" color="var(--lavender)" sound={false} onClick={showRole} />
          </>
        )}

        {phase === 'reveal' && (
          <>
            <div className="frame__body">
              <p className="lead strong">{player.name}</p>
              <span className="bounce-in wiggle">
                <RoleIcon role={player.role} size={190} />
              </span>
              <p className="lead">Tu es</p>
              <p
                className="role-label"
                style={{ color: player.role === 'assassin' ? 'var(--assassin-purple)' : 'var(--citizen-blue)' }}
              >
                {roleLabel(player.role)}
              </p>
              <Card className="center text">
                {player.role === 'assassin' ? (
                  <>
                    Tue en silence avec un clin d'œil 😉
                    <br />
                    {accomplices.length === 0 ? (
                      'Tu es le seul assassin !'
                    ) : (
                      <>
                        <br />
                        Tes complices : <strong>{accomplices.join(', ')}</strong>
                      </>
                    )}
                  </>
                ) : (
                  <>
                    Ouvre grand les yeux 👀
                    <br />
                    et démasque les assassins !
                  </>
                )}
              </Card>
            </div>
            <BigButton
              label="J'ai retenu, cacher"
              emoji="🙈"
              color={player.role === 'assassin' ? 'var(--assassin-purple)' : 'var(--citizen-blue)'}
              onClick={hideRole}
            />
          </>
        )}

        {phase === 'hidden' && (
          <div className="frame__body">
            <span className="bounce-in big-emoji big-emoji--xl">🙈</span>
            <p className="title">Rôle caché !</p>
            <p className="hint">Chut… garde-le pour toi 🤫</p>
          </div>
        )}

        {phase === 'ready' && (
          <>
            <div className="frame__body">
              <span className="bounce-in wiggle big-emoji big-emoji--xl">🤫</span>
              <p className="title">Tout le monde est prêt ?</p>
              <p className="lead strong" style={{ color: 'var(--assassin-purple)' }}>
                Silence… la partie commence !
              </p>
              <Card className="center text">
                Posez le téléphone au centre.
                <br />
                On ne parle plus, on se regarde 👀
              </Card>
            </div>
            <BigButton label="C'est parti !" emoji="🤫" color="var(--citizen-green)" onClick={onDone} />
          </>
        )}
      </div>
      {toast && <Toast message={toast} onDone={clearToast} />}
    </section>
  );
}
