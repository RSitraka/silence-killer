import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';

/** Effets sonores disponibles (fichiers dans public/sounds/). */
export type Sfx = 'tap' | 'reveal' | 'death' | 'drumroll' | 'success' | 'fail' | 'victory';

const STORAGE_KEY = 'clin-doeil:muted';

interface SoundApi {
  muted: boolean;
  toggleMute: () => void;
  play: (sfx: Sfx) => void;
}

const SoundContext = createContext<SoundApi | null>(null);

function readMuted(): boolean {
  try {
    return localStorage.getItem(STORAGE_KEY) === '1';
  } catch {
    return false;
  }
}

/** Fournit les sons à toute l'application. Le réglage « son coupé » est mémorisé. */
export function SoundProvider({ children }: { children: ReactNode }) {
  const [muted, setMuted] = useState(readMuted);
  const mutedRef = useRef(muted);
  const cache = useRef(new Map<Sfx, HTMLAudioElement>());

  const play = useCallback((sfx: Sfx) => {
    if (mutedRef.current) return;
    let audio = cache.current.get(sfx);
    if (!audio) {
      audio = new Audio(`/sounds/${sfx}.wav`);
      cache.current.set(sfx, audio);
    }
    audio.currentTime = 0;
    // Un son bloqué par le navigateur ne doit jamais gêner le jeu.
    audio.play().catch(() => {});
  }, []);

  const toggleMute = useCallback(() => {
    const next = !mutedRef.current;
    mutedRef.current = next;
    setMuted(next);
    if (next) cache.current.forEach((a) => a.pause());
    try {
      localStorage.setItem(STORAGE_KEY, next ? '1' : '0');
    } catch {
      /* stockage indisponible : le réglage vaut pour cette visite */
    }
  }, []);

  const api = useMemo(() => ({ muted, toggleMute, play }), [muted, toggleMute, play]);
  return <SoundContext.Provider value={api}>{children}</SoundContext.Provider>;
}

export function useSound(): SoundApi {
  const api = useContext(SoundContext);
  if (!api) throw new Error('useSound doit être utilisé dans <SoundProvider>');
  return api;
}
