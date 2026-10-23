import { useId } from 'react';
import type { Role } from '../logic/game';

/*
 * Illustrations dessinées en SVG (aucune image externe, aucun droit d'auteur),
 * identiques à celles de l'application mobile.
 *
 * Les deux icônes de rôle diffèrent par la FORME et la COULEUR :
 *   • CITOYEN  : rond, bleu ciel / vert, visage souriant + cœur ;
 *   • ASSASSIN : étoile pointue, violet / rouge, ninja qui fait un clin d'œil.
 */

const INK = '#3D2C5C';

export const AVATAR_PALETTE = [
  '#FF9CC2', '#8FD3FF', '#FFD66B', '#9BEBC4', '#C6B3FF',
  '#FFB38A', '#7EDFE6', '#F7A8F0', '#B8E986', '#FFC4A3',
];
export const avatarColor = (i: number) => AVATAR_PALETTE[i % AVATAR_PALETTE.length];

export function RoleIcon({ role, size = 120 }: { role: Role; size?: number }) {
  return role === 'citizen' ? <CitizenIcon size={size} /> : <AssassinIcon size={size} />;
}

export function CitizenIcon({ size = 120 }: { size?: number }) {
  const id = useId();
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" role="img" aria-label="Icône citoyen">
      <defs>
        <linearGradient id={id} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#4FB8F5" />
          <stop offset="1" stopColor="#3FCF8E" />
        </linearGradient>
      </defs>
      <circle cx="50" cy="50" r="47" fill={`url(#${id})`} stroke="#fff" strokeWidth="3.5" />
      <circle cx="50" cy="52" r="29" fill="#FFE8C4" />
      <path d="M42 26 Q50 17 56 25 Q50 22 47 28 Z" fill="#8B5A2B" />
      {[40, 60].map((x) => (
        <g key={x}>
          <circle cx={x} cy="48" r="3.8" fill={INK} />
          <circle cx={x + 1.2} cy="46.8" r="1.2" fill="#fff" />
        </g>
      ))}
      <ellipse cx="33" cy="58" rx="4.5" ry="2.75" fill="#FF9CB5" opacity="0.8" />
      <ellipse cx="67" cy="58" rx="4.5" ry="2.75" fill="#FF9CB5" opacity="0.8" />
      <path d="M59.8 60.1 A11 9 0 0 1 40.2 60.1" fill="none" stroke={INK} strokeWidth="3.5" strokeLinecap="round" />
      <circle cx="78" cy="78" r="15" fill="#fff" />
      <circle cx="78" cy="78" r="12" fill="#3FCF8E" />
      <path d="M78 83.94 C65.65 76.4 72.8 67.95 78 75.36 C83.2 67.95 90.35 76.4 78 83.94 Z" fill="#fff" />
    </svg>
  );
}

/** Étoile à 8 branches pointues. */
const STAR = Array.from({ length: 16 }, (_, i) => {
  const r = i % 2 === 0 ? 49 : 36;
  const a = -Math.PI / 2 + (i * Math.PI) / 8;
  return `${(50 + Math.cos(a) * r).toFixed(2)},${(50 + Math.sin(a) * r).toFixed(2)}`;
}).join(' ');

export function AssassinIcon({ size = 120 }: { size?: number }) {
  const id = useId();
  return (
    <svg width={size} height={size} viewBox="0 0 100 100" role="img" aria-label="Icône assassin">
      <defs>
        <linearGradient id={`${id}g`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#A78BFA" />
          <stop offset="0.5" stopColor="#7C3AED" />
          <stop offset="1" stopColor="#E11D48" />
        </linearGradient>
        <clipPath id={`${id}c`}>
          <circle cx="50" cy="52" r="25" />
        </clipPath>
      </defs>
      <polygon points={STAR} fill={`url(#${id}g)`} stroke="#fff" strokeWidth="3" strokeLinejoin="round" />
      {/* Rubans du bandeau qui flottent */}
      <path d="M70 38 Q82 30 90 24 Q86 34 74 44 Z" fill="#F43F5E" />
      <path d="M72 42 Q86 42 93 38 Q86 48 72 47 Z" fill="#F43F5E" />
      {/* Cagoule + bandeau */}
      <circle cx="50" cy="52" r="25" fill="#2E1A55" />
      <rect x="0" y="36" width="100" height="5" fill="#F43F5E" clipPath={`url(#${id}c)`} />
      <rect x="30" y="43.5" width="40" height="13" rx="6.5" fill="#FFE1C2" />
      {/* Œil ouvert + CLIN D'ŒIL */}
      <circle cx="42" cy="50" r="3.4" fill={INK} />
      <circle cx="43" cy="49" r="1.1" fill="#fff" />
      <path d="M54 49.5 Q58.5 53.5 63 49.5" fill="none" stroke={INK} strokeWidth="3" strokeLinecap="round" />
      <path d="M58.66 63.24 A7 4 0 0 1 45.34 63.24" fill="none" stroke="#FFB3C7" strokeWidth="3" strokeLinecap="round" />
    </svg>
  );
}

export function Ghost({ size = 40 }: { size?: number }) {
  return (
    <svg width={size} height={size * 1.08} viewBox="0 0 100 108" aria-hidden="true">
      <path
        d="M12 92 L12 45 A38 38 0 0 1 88 45 L88 92 Q81.67 78 75.33 92 Q69 104 62.67 92 Q56.33 78 50 92 Q43.67 104 37.33 92 Q31 78 24.67 92 Q18.33 104 12 92 Z"
        fill="#fff"
        stroke="#D9D3E6"
        strokeWidth="5"
        strokeLinejoin="round"
      />
      <ellipse cx="38" cy="45" rx="6" ry="8.5" fill={INK} />
      <ellipse cx="62" cy="45" rx="6" ry="8.5" fill={INK} />
      <circle cx="50" cy="64" r="5" fill={INK} />
    </svg>
  );
}

/**
 * Avatar NEUTRE d'un joueur (ne révèle jamais le rôle).
 * Vivant : rond coloré et souriant. Mort : grisé, yeux en croix + fantôme.
 */
export function PlayerAvatar({ colorIndex, alive = true, size = 72 }: { colorIndex: number; alive?: boolean; size?: number }) {
  const ink = alive ? INK : '#6F6880';
  return (
    <span className="avatar" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden="true">
        <circle cx="50" cy="50" r="46" fill={alive ? avatarColor(colorIndex) : '#BDB8C7'} stroke="#fff" strokeWidth="4" />
        {alive ? (
          <>
            <circle cx="36" cy="44" r="5.5" fill={ink} />
            <circle cx="64" cy="44" r="5.5" fill={ink} />
            <circle cx="25" cy="58" r="6" fill="#fff" opacity="0.45" />
            <circle cx="75" cy="58" r="6" fill="#fff" opacity="0.45" />
            <path d="M66.17 60.02 A17 13 0 0 1 33.83 60.02" fill="none" stroke={ink} strokeWidth="5.5" strokeLinecap="round" />
          </>
        ) : (
          <g stroke={ink} strokeWidth="5.5" strokeLinecap="round" fill="none">
            <path d="M30 38 L42 50 M42 38 L30 50 M58 38 L70 50 M70 38 L58 50" />
            <path d="M34 68 Q42 62 50 68 Q58 74 66 68" />
          </g>
        )}
      </svg>
      {!alive && (
        <span className="avatar-ghost" style={{ right: -size * 0.12, top: -size * 0.14 }}>
          <Ghost size={size * 0.48} />
        </span>
      )}
    </span>
  );
}
