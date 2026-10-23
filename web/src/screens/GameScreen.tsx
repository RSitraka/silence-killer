import { useEffect, useRef, useState } from 'react';
import { useBack } from '../App';
import { PlayerAvatar } from '../components/Icons';
import { BigButton, Modal, TopBar } from '../components/ui';
import { useSound } from '../hooks/sound';
import { checkVictory, setAlive, teamName, type Player, type Role } from '../logic/game';
import { AccuseScreen } from './AccuseScreen';

/**
 * Étape C — Partie en cours. Le téléphone est posé au centre.
 * Les rôles ne sont JAMAIS affichés sur cet écran.
 */
export function GameScreen({
  players,
  onChange,
  onQuit,
  onEnd,
}: {
  players: Player[];
  onChange: (players: Player[]) => void;
  onQuit: () => void;
  onEnd: (winner: Role) => void;
}) {
  const [editing, setEditing] = useState<number | null>(null);
  const [accusing, setAccusing] = useState(false);
  const [confirmQuit, setConfirmQuit] = useState(false);
  const [victory, setVictory] = useState<Role | null>(null);
  const { play } = useSound();

  useBack(() => setConfirmQuit((v) => !v));

  const alive = players.filter((p) => p.alive).length;
  const dead = players.length - alive;

  /** Après chaque changement de statut : vérifier les conditions de victoire. */
  const update = (next: Player[]) => {
    onChange(next);
    setVictory(checkVictory(next));
  };

  const applyStatus = (index: number, isAlive: boolean) => {
    setEditing(null);
    if (players[index].alive === isAlive) return;
    play(isAlive ? 'reveal' : 'death');
    update(setAlive(players, index, isAlive));
  };

  if (accusing) {
    return (
      <AccuseScreen
        players={players}
        onResult={(next) => onChange(next)}
        onClose={() => {
          setAccusing(false);
          setVictory(checkVictory(players));
        }}
      />
    );
  }

  return (
    <section className="screen">
      <TopBar
        title="🤫 Silence…"
        left={
          <button type="button" className="round-btn" onClick={() => setConfirmQuit(true)} aria-label="Quitter la partie">
            ✕
          </button>
        }
      />
      <div className="pills">
        <span className="pill" style={{ background: 'rgb(126 227 180 / .45)' }}>
          😊 {alive} vivant{alive > 1 ? 's' : ''}
        </span>
        <span className="pill" style={{ background: 'rgb(189 184 199 / .45)' }}>
          👻 {dead} mort{dead > 1 ? 's' : ''}
        </span>
      </div>
      <p className="hint center">Touchez un joueur pour le déclarer mort ou vivant</p>

      <div className="scroll">
        <ul className="player-grid">
          {players.map((p, i) => (
            <li key={p.name}>
              <button
                type="button"
                className={`player-card ${p.alive ? '' : 'player-card--dead'}`}
                onClick={() => setEditing(i)}
                aria-label={`${p.name}, ${p.alive ? 'vivant' : 'mort'}`}
              >
                <span key={String(p.alive)} className="bounce-in">
                  <PlayerAvatar colorIndex={p.colorIndex} alive={p.alive} size={80} />
                </span>
                <span className="player-card__name">{p.name}</span>
                <span className={`player-card__status ${p.alive ? 'is-alive' : ''}`}>
                  {p.alive ? 'Vivant 😊' : 'Mort 💀'}
                </span>
              </button>
            </li>
          ))}
        </ul>
      </div>

      <div className="bottom">
        <BigButton
          label="J'accuse !"
          emoji="✋"
          size="lg"
          color="var(--coral)"
          disabled={alive < 2}
          onClick={() => setAccusing(true)}
        />
      </div>

      {editing !== null && (
        <StatusDialog
          player={players[editing]}
          onCancel={() => setEditing(null)}
          onConfirm={(isAlive) => applyStatus(editing, isAlive)}
        />
      )}

      {victory && (
        <Modal>
          <h2 className="modal__title">Victoire des {teamName(victory)} ! 🎉</h2>
          <div className="big-emoji">🏆</div>
          <p className="text center">
            Tout est correct ?<br />
            Si quelqu'un a été marqué par erreur, corrigez-le avant de révéler les rôles.
          </p>
          <div className="stack">
            <BigButton label="Confirmer" emoji="✅" color="var(--citizen-green)" onClick={() => onEnd(victory)} />
            <BigButton label="Corriger une erreur" emoji="✏️" size="sm" color="var(--peach)" onClick={() => setVictory(null)} />
          </div>
        </Modal>
      )}

      {confirmQuit && (
        <Modal onBackdrop={() => setConfirmQuit(false)}>
          <h2 className="modal__title">Quitter la partie ?</h2>
          <p className="text center">La partie en cours sera perdue.</p>
          <div className="row row--stretch">
            <button type="button" className="text-btn" onClick={() => setConfirmQuit(false)}>
              Rester
            </button>
            <button type="button" className="text-btn text-btn--danger" onClick={onQuit}>
              Quitter
            </button>
          </div>
        </Modal>
      )}
    </section>
  );
}

/**
 * Fenêtre « Mort 💀 / Vivant 😊 ».
 * Pour « Mort », un compte à rebours visuel de 2 secondes précède la validation.
 */
function StatusDialog({
  player,
  onCancel,
  onConfirm,
}: {
  player: Player;
  onCancel: () => void;
  onConfirm: (alive: boolean) => void;
}) {
  const [counting, setCounting] = useState(false);
  const [remaining, setRemaining] = useState(2);
  const confirm = useRef(onConfirm);
  confirm.current = onConfirm;

  useBack(onCancel);

  useEffect(() => {
    if (!counting) return;
    const tick = setTimeout(() => setRemaining(1), 1000);
    const done = setTimeout(() => confirm.current(false), 2000);
    return () => {
      clearTimeout(tick);
      clearTimeout(done);
    };
  }, [counting]);

  return (
    <Modal onBackdrop={onCancel}>
      <div className="center">
        <PlayerAvatar colorIndex={player.colorIndex} alive={player.alive} size={88} />
      </div>
      <h2 className="modal__title">{player.name}</h2>
      {counting ? (
        <>
          <div className="countdown" aria-live="assertive">
            <svg viewBox="0 0 100 100" aria-hidden="true">
              <circle cx="50" cy="50" r="44" className="countdown__track" />
              <circle cx="50" cy="50" r="44" className="countdown__bar" />
            </svg>
            <span key={remaining} className="countdown__num pop">
              {remaining}
            </span>
          </div>
          <p className="lead strong center">Un… deux… 💀</p>
          <button type="button" className="text-btn" onClick={onCancel}>
            Annuler
          </button>
        </>
      ) : (
        <>
          <div className="stack">
            <BigButton label="Mort" emoji="💀" size="lg" color="#8E86A3" onClick={() => setCounting(true)} />
            <BigButton label="Vivant" emoji="😊" size="lg" color="var(--citizen-green)" onClick={() => onConfirm(true)} />
          </div>
          <button type="button" className="text-btn" onClick={onCancel}>
            Annuler
          </button>
        </>
      )}
    </Modal>
  );
}
