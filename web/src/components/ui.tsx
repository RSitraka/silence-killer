import { useEffect, useRef, type CSSProperties, type ReactNode } from 'react';
import { useSound } from '../hooks/sound';

/** Gros bouton arrondi façon « bonbon », qui s'enfonce quand on appuie. */
export function BigButton({
  label,
  emoji,
  color = 'var(--pink)',
  onClick,
  disabled,
  size = 'md',
  sound = true,
}: {
  label: string;
  emoji?: string;
  color?: string;
  onClick: () => void;
  disabled?: boolean;
  size?: 'sm' | 'md' | 'lg';
  sound?: boolean;
}) {
  const { play } = useSound();
  return (
    <button
      type="button"
      className={`big-btn big-btn--${size}`}
      style={{ '--c': color } as CSSProperties}
      disabled={disabled}
      onClick={() => {
        if (sound) play('tap');
        onClick();
      }}
    >
      {emoji && (
        <span className="big-btn__emoji" aria-hidden="true">
          {emoji}
        </span>
      )}
      <span>{label}</span>
    </button>
  );
}

/** Bouton rond pour couper / remettre le son. */
export function MuteButton() {
  const { muted, toggleMute } = useSound();
  return (
    <button
      type="button"
      className="round-btn"
      onClick={toggleMute}
      aria-label={muted ? 'Activer le son' : 'Couper le son'}
      title={muted ? 'Activer le son' : 'Couper le son'}
    >
      {muted ? '🔇' : '🔊'}
    </button>
  );
}

/** Barre du haut : bouton à gauche, titre, son à droite. */
export function TopBar({ title, left }: { title?: ReactNode; left?: ReactNode }) {
  return (
    <header className="topbar">
      <div className="topbar__side">{left}</div>
      <h1 className="topbar__title">{title}</h1>
      <div className="topbar__side topbar__side--right">
        <MuteButton />
      </div>
    </header>
  );
}

export function Card({ children, className = '', style }: { children: ReactNode; className?: string; style?: CSSProperties }) {
  return (
    <div className={`card ${className}`} style={style}>
      {children}
    </div>
  );
}

/** Sélecteur « − nombre + » avec gros boutons ronds. */
export function NumberStepper({
  value,
  min,
  max,
  onChange,
  color = 'var(--lavender)',
  label,
}: {
  value: number;
  min: number;
  max: number;
  onChange: (v: number) => void;
  color?: string;
  label: string;
}) {
  const { play } = useSound();
  const step = (d: number) => {
    play('tap');
    onChange(value + d);
  };
  return (
    <div className="stepper" role="group" aria-label={label}>
      <button type="button" style={{ background: color }} disabled={value <= min} onClick={() => step(-1)} aria-label="Moins">
        −
      </button>
      <output key={value} className="stepper__value pop" aria-live="polite">
        {value}
      </output>
      <button type="button" style={{ background: color }} disabled={value >= max} onClick={() => step(1)} aria-label="Plus">
        +
      </button>
    </div>
  );
}

/** Fenêtre modale centrée. */
export function Modal({ children, onBackdrop }: { children: ReactNode; onBackdrop?: () => void }) {
  return (
    <div className="modal" role="dialog" aria-modal="true" onClick={onBackdrop}>
      <div className="modal__box bounce-in" onClick={(e) => e.stopPropagation()}>
        {children}
      </div>
    </div>
  );
}

/** Petit message temporaire en bas de l'écran. */
export function Toast({ message, onDone }: { message: string; onDone: () => void }) {
  useEffect(() => {
    const t = setTimeout(onDone, 2500);
    return () => clearTimeout(t);
  }, [message, onDone]);
  return (
    <div className="toast" role="status">
      {message}
    </div>
  );
}

/** Pluie de confettis infinie, dessinée sur un canvas. */
export function Confetti({ count = 90 }: { count?: number }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

    const colors = ['#FF8FB8', '#FFD66B', '#7EE3B4', '#7CC8FF', '#B9A2FF', '#FFB38A', '#FF7B7B'];
    const parts = Array.from({ length: count }, () => ({
      x: Math.random(),
      phase: Math.random(),
      speed: 0.6 + Math.random() * 0.8,
      sway: 10 + Math.random() * 25,
      spin: (Math.random() - 0.5) * 12,
      size: 7 + Math.random() * 8,
      color: colors[Math.floor(Math.random() * colors.length)],
      round: Math.random() < 0.5,
    }));

    let frame = 0;
    const start = performance.now();
    const draw = (now: number) => {
      const dpr = window.devicePixelRatio || 1;
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      if (canvas.width !== w * dpr || canvas.height !== h * dpr) {
        canvas.width = w * dpr;
        canvas.height = h * dpr;
      }
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      ctx.clearRect(0, 0, w, h);
      const t = (now - start) / 5000;
      for (const p of parts) {
        const progress = (t * p.speed + p.phase) % 1;
        const y = progress * (h + 40) - 20;
        const x = p.x * w + Math.sin((progress + p.phase) * Math.PI * 4) * p.sway;
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(progress * p.spin);
        ctx.fillStyle = p.color;
        if (p.round) {
          ctx.beginPath();
          ctx.arc(0, 0, p.size / 2.4, 0, Math.PI * 2);
          ctx.fill();
        } else {
          ctx.fillRect(-p.size / 2, -p.size * 0.275, p.size, p.size * 0.55);
        }
        ctx.restore();
      }
      frame = requestAnimationFrame(draw);
    };
    frame = requestAnimationFrame(draw);
    return () => cancelAnimationFrame(frame);
  }, [count]);

  return <canvas ref={ref} className="confetti" aria-hidden="true" />;
}
