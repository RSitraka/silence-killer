import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useBackButton, useConfirmLeave, useWakeLock } from './hooks/browser';
import { dealRoles, type Player, type Role } from './logic/game';
import { DistributionScreen } from './screens/DistributionScreen';
import { EndScreen } from './screens/EndScreen';
import { GameScreen } from './screens/GameScreen';
import { HomeScreen } from './screens/HomeScreen';
import { SetupScreen } from './screens/SetupScreen';
import { TutorialScreen } from './screens/TutorialScreen';

type Screen = 'home' | 'tutorial' | 'setup' | 'distribution' | 'game' | 'end';

const SETUP_KEY = 'clin-doeil:setup';

/** Derniers prénoms saisis (pratique pour rejouer après avoir fermé l'onglet). */
function loadSetup(): { names: string[]; assassins: number } {
  try {
    const raw = JSON.parse(localStorage.getItem(SETUP_KEY) ?? 'null');
    if (Array.isArray(raw?.names) && typeof raw?.assassins === 'number') return raw;
  } catch {
    /* rien de mémorisé */
  }
  return { names: [], assassins: 1 };
}

// ---------------------------------------------------------------------------
// Bouton « retour » du navigateur : chaque écran (ou fenêtre) déclare ce qu'il
// doit faire. Le dernier déclaré est prioritaire (pile).
// ---------------------------------------------------------------------------
type Register = (fn: () => void) => () => void;
const BackContext = createContext<Register>(() => () => {});

export function useBack(fn: () => void) {
  const register = useContext(BackContext);
  const ref = useRef(fn);
  ref.current = fn;
  useEffect(() => register(() => ref.current()), [register]);
}

export default function App() {
  const [screen, setScreen] = useState<Screen>('home');
  const [setup, setSetup] = useState(loadSetup);
  const [players, setPlayers] = useState<Player[]>([]);
  const [winner, setWinner] = useState<Role>('citizen');

  const backStack = useRef<(() => void)[]>([]);
  const register = useCallback<Register>((fn) => {
    backStack.current.push(fn);
    return () => {
      backStack.current = backStack.current.filter((f) => f !== fn);
    };
  }, []);
  useBackButton(() => backStack.current.at(-1)?.());

  // Écran allumé + confirmation avant de fermer l'onglet pendant une partie.
  const playing = screen === 'distribution' || screen === 'game';
  useWakeLock(playing);
  useConfirmLeave(playing);

  // Chaque changement d'écran repart en haut de la page.
  useEffect(() => window.scrollTo(0, 0), [screen]);

  const startGame = (names: string[], assassins: number) => {
    const next = { names, assassins };
    setSetup(next);
    try {
      localStorage.setItem(SETUP_KEY, JSON.stringify(next));
    } catch {
      /* stockage indisponible */
    }
    setPlayers(dealRoles(names, assassins));
    setScreen('distribution');
  };

  const home = () => setScreen('home');

  return (
    <BackContext.Provider value={register}>
      <main className="app">
        {screen === 'home' && <HomeScreen onTutorial={() => setScreen('tutorial')} onPlay={() => setScreen('setup')} />}
        {screen === 'tutorial' && <TutorialScreen onDone={() => setScreen('setup')} onBack={home} />}
        {screen === 'setup' && (
          <SetupScreen initialNames={setup.names} initialAssassins={setup.assassins} onStart={startGame} onBack={home} />
        )}
        {screen === 'distribution' && <DistributionScreen players={players} onDone={() => setScreen('game')} />}
        {screen === 'game' && (
          <GameScreen
            players={players}
            onChange={setPlayers}
            onQuit={home}
            onEnd={(w) => {
              setWinner(w);
              setScreen('end');
            }}
          />
        )}
        {screen === 'end' && (
          <EndScreen
            players={players}
            winner={winner}
            onHome={home}
            onReplay={() => {
              setPlayers(dealRoles(setup.names, setup.assassins));
              setScreen('distribution');
            }}
          />
        )}
      </main>
    </BackContext.Provider>
  );
}
