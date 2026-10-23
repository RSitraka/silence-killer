import { useEffect, useRef, useState } from 'react';
import { useBack } from '../App';
import { PlayerAvatar, RoleIcon } from '../components/Icons';
import { BigButton, Card, Confetti } from '../components/ui';
import { useSound } from '../hooks/sound';
import { accuse, type Player } from '../logic/game';

type Step = 'accuser' | 'accused' | 'suspense' | 'reveal';

/**
 * « J'accuse ! ✋ » : accusateur → accusé → tambour (2 s) → révélation.
 * Le vote lui-même se fait oralement entre les joueurs.
 */
export function AccuseScreen({
  players,
  onResult,
  onClose,
}: {
  players: Player[];
  onResult: (players: Player[]) => void;
  onClose: () => void;
}) {
  const [step, setStep] = useState<Step>('accuser');
  const [accuser, setAccuser] = useState<number | null>(null);
  const [accused, setAccused] = useState<number | null>(null);
  const [guessed, setGuessed] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout>>();
  const { play } = useSound();

  useEffect(() => () => clearTimeout(timer.current), []);

  // Retour : étape précédente (bloqué pendant le suspense).
  const back = () => {
    if (step === 'accused') setStep('accuser');
    else if (step !== 'suspense') onClose();
  };
  useBack(back);

  const pickAccused = (i: number) => {
    if (step !== 'accused' || accuser === null) return;
    setAccused(i);
    setStep('suspense');
    play('drumroll');
    timer.current = setTimeout(() => {
      const result = accuse(players, accuser, i);
      onResult(result.players);
      setGuessed(result.guessed);
      play(result.guessed ? 'success' : 'fail');
      setStep('reveal');
    }, 2000);
  };

  const alive = players.map((p, i) => ({ p, i })).filter(({ p }) => p.alive);

  const background =
    step === 'reveal' ? (guessed ? '#E5FAF0' : '#FFE9E9') : step === 'suspense' ? '#2E1A55' : '#FFEDE3';

  return (
    <section className="screen" style={{ background }}>
      {(step === 'accuser' || step === 'accused') && (
        <>
          <header className="topbar">
            <div className="topbar__side">
              <button type="button" className="round-btn" onClick={back} aria-label="Retour">
                ←
              </button>
            </div>
            <h1 className="topbar__title">J'accuse !</h1>
            <div className="topbar__side" />
          </header>
          <div key={step} className="fade-in center">
            <h2 className="title">{step === 'accuser' ? 'Qui accuse ? ✋' : `${players[accuser!].name} accuse…`}</h2>
            <p className="hint">
              {step === 'accuser' ? 'Choisis le joueur qui a levé la main' : 'Choisis le joueur soupçonné 🔍'}
            </p>
          </div>
          <div className="scroll">
            <ul key={step} className="pick-list fade-in">
              {alive
                .filter(({ i }) => step === 'accuser' || i !== accuser)
                .map(({ p, i }) => (
                  <li key={p.name}>
                    <button
                      type="button"
                      className="pick"
                      onClick={() => {
                        play('tap');
                        if (step === 'accuser') {
                          setAccuser(i);
                          setStep('accused');
                        } else {
                          pickAccused(i);
                        }
                      }}
                    >
                      <PlayerAvatar colorIndex={p.colorIndex} size={54} />
                      <span className="pick__name">{p.name}</span>
                      <span aria-hidden="true">›</span>
                    </button>
                  </li>
                ))}
            </ul>
          </div>
        </>
      )}

      {step === 'suspense' && accused !== null && (
        <div className="frame fade-in">
          <div className="frame__body">
            <span className="drum" aria-hidden="true">
              🥁
            </span>
            <p className="title" style={{ color: '#fff' }}>
              Roulement de tambour…
            </p>
            <p className="lead strong" style={{ color: 'var(--lavender)' }}>
              {players[accused].name} est-il un assassin ?
            </p>
          </div>
        </div>
      )}

      {step === 'reveal' && accused !== null && accuser !== null && (
        <>
          {guessed && <Confetti count={50} />}
          <div className="frame fade-in">
            <div className="frame__body">
              <span className="bounce-in">
                <RoleIcon role={players[accused].role} size={180} />
              </span>
              <p className="reveal-title" style={{ color: guessed ? 'var(--citizen-green)' : 'var(--coral)' }}>
                {guessed ? 'Bien vu !' : 'Raté !'}
              </p>
              <p className="lead strong center">
                {guessed
                  ? `${players[accused].name} était un assassin !`
                  : `${players[accused].name} était innocent…`}
              </p>
              <Card className="eliminated">
                {(guessed ? [accused] : [accuser, accused]).map((i) => (
                  <div key={i}>
                    <PlayerAvatar colorIndex={players[i].colorIndex} alive={false} size={62} />
                    <span>{players[i].name}</span>
                  </div>
                ))}
              </Card>
              <p className="hint center">
                {guessed ? "L'assassin est éliminé 🎉" : "L'accusateur ET l'accusé sont éliminés 💀"}
              </p>
            </div>
            <BigButton
              label="Continuer"
              emoji="👉"
              color={guessed ? 'var(--citizen-green)' : 'var(--lavender)'}
              onClick={onClose}
            />
          </div>
        </>
      )}
    </section>
  );
}
