import { useCallback, useState } from 'react';
import { useBack } from '../App';
import { PlayerAvatar, RoleIcon } from '../components/Icons';
import { BigButton, Card, NumberStepper, Toast, TopBar } from '../components/ui';
import { MAX_PLAYERS, maxAssassinsFor, MIN_PLAYERS, validateNames } from '../logic/game';

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));

/** Étape A — Configuration : nombre de joueurs, prénoms, nombre d'assassins. */
export function SetupScreen({
  initialNames,
  initialAssassins,
  onStart,
  onBack,
}: {
  initialNames: string[];
  initialAssassins: number;
  onStart: (names: string[], assassins: number) => void;
  onBack: () => void;
}) {
  const startCount = clamp(initialNames.length, MIN_PLAYERS, MAX_PLAYERS);
  // On garde tous les prénoms saisis, même si on baisse puis remonte le nombre de joueurs.
  const [names, setNames] = useState<string[]>(() =>
    Array.from({ length: MAX_PLAYERS }, (_, i) => initialNames[i] ?? ''),
  );
  const [count, setCount] = useState(startCount);
  const [assassins, setAssassins] = useState(clamp(initialAssassins, 1, maxAssassinsFor(startCount)));
  const [errors, setErrors] = useState<(string | null)[]>([]);
  const [toast, setToast] = useState<string | null>(null);

  useBack(onBack);
  const clearToast = useCallback(() => setToast(null), []);

  const maxAssassins = maxAssassinsFor(count);
  const citizens = count - assassins;

  const changeCount = (n: number) => {
    setCount(n);
    setAssassins((a) => clamp(a, 1, maxAssassinsFor(n)));
    setErrors([]);
  };

  const distribute = () => {
    const list = names.slice(0, count).map((n) => n.trim());
    const errs = validateNames(list);
    setErrors(errs);
    const firstError = errs.findIndex((e) => e);
    if (firstError >= 0) {
      setToast('Oups ! Vérifie les prénoms 🙂');
      document.getElementById(`name-${firstError}`)?.focus();
      return;
    }
    onStart(list, assassins);
  };

  return (
    <section className="screen">
      <TopBar
        title="Préparation"
        left={
          <button type="button" className="round-btn" onClick={onBack} aria-label="Retour à l'accueil">
            ←
          </button>
        }
      />
      <div className="scroll">
        <Card className="center">
          <h2 className="card-title">👥 Combien de joueurs ?</h2>
          <NumberStepper
            label="Nombre de joueurs"
            value={count}
            min={MIN_PLAYERS}
            max={MAX_PLAYERS}
            onChange={changeCount}
            color="var(--sky)"
          />
          <p className="hint">de 4 à 20 joueurs</p>
        </Card>

        <Card>
          <h2 className="card-title center">✏️ Les prénoms</h2>
          <form
            className="names"
            onSubmit={(e) => {
              e.preventDefault();
              distribute();
            }}
          >
            {Array.from({ length: count }, (_, i) => (
              <div key={i} className="name-row">
                <PlayerAvatar colorIndex={i} size={46} />
                <div className="name-field">
                  <input
                    id={`name-${i}`}
                    value={names[i]}
                    maxLength={16}
                    autoComplete="off"
                    autoCapitalize="words"
                    enterKeyHint={i === count - 1 ? 'done' : 'next'}
                    placeholder={`Joueur ${i + 1}`}
                    aria-label={`Prénom du joueur ${i + 1}`}
                    aria-invalid={!!errors[i]}
                    className={errors[i] ? 'invalid' : ''}
                    onChange={(e) => {
                      const v = e.target.value;
                      setNames((prev) => prev.map((n, j) => (j === i ? v : n)));
                      if (errors[i]) setErrors((prev) => prev.map((er, j) => (j === i ? null : er)));
                    }}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && i < count - 1) {
                        e.preventDefault();
                        document.getElementById(`name-${i + 1}`)?.focus();
                      }
                    }}
                  />
                  {errors[i] && <span className="field-error">{errors[i]}</span>}
                </div>
              </div>
            ))}
          </form>
        </Card>

        <Card className="center">
          <h2 className="card-title">🥷 Combien d'assassins ?</h2>
          <NumberStepper
            label="Nombre d'assassins"
            value={assassins}
            min={1}
            max={maxAssassins}
            onChange={setAssassins}
            color="var(--assassin-purple)"
          />
          <p className="hint">
            maximum {maxAssassins} pour {count} joueurs
          </p>
          <div className="counts">
            <div>
              <RoleIcon role="citizen" size={62} />
              <strong style={{ color: 'var(--citizen-blue)' }}>
                {citizens} citoyen{citizens > 1 ? 's' : ''}
              </strong>
            </div>
            <div>
              <RoleIcon role="assassin" size={62} />
              <strong style={{ color: 'var(--assassin-purple)' }}>
                {assassins} assassin{assassins > 1 ? 's' : ''}
              </strong>
            </div>
          </div>
        </Card>
        <div className="actions">
          <BigButton label="Distribuer les rôles" emoji="🃏" color="var(--pink)" onClick={distribute} />
        </div>
      </div>
      {toast && <Toast message={toast} onDone={clearToast} />}
    </section>
  );
}
