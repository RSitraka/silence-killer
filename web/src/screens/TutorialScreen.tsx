import { useRef, useState, type ReactNode } from 'react';
import { useBack } from '../App';
import { AssassinIcon, CitizenIcon, PlayerAvatar } from '../components/Icons';
import { BigButton, Card, TopBar } from '../components/ui';

interface Page {
  title: string;
  color: string;
  illustration: ReactNode;
  text: ReactNode;
}

const Emoji = ({ e, size = 90 }: { e: string; size?: number }) => (
  <span style={{ fontSize: size, lineHeight: 1 }} aria-hidden="true">
    {e}
  </span>
);

const PAGES: Page[] = [
  {
    title: '1. Préparation',
    color: '#FFE8F1',
    illustration: (
      <div className="row">
        {[0, 1, 2, 3].map((i) => (
          <span key={i} className="wiggle" style={{ animationDelay: `${-i * 0.5}s` }}>
            <PlayerAvatar colorIndex={i} size={62} />
          </span>
        ))}
      </div>
    ),
    text: (
      <>
        Choisissez le nombre de joueurs, entrez leurs prénoms, puis le nombre d'assassins.
        <br />
        <br />
        Le nombre de citoyens est calculé tout seul !
      </>
    ),
  },
  {
    title: '2. Les rôles secrets',
    color: '#E6F6FF',
    illustration: (
      <div className="row">
        <CitizenIcon size={96} />
        <Emoji e="📱" size={56} />
        <AssassinIcon size={106} />
      </div>
    ),
    text: (
      <>
        On se passe le téléphone. Chaque joueur voit son prénom, appuie pour découvrir son rôle (Citoyen ou
        Assassin), le mémorise, puis valide.
        <br />
        <br />
        L'écran affiche alors le prénom du joueur suivant : personne ne voit le rôle des autres !
      </>
    ),
  },
  {
    title: '3. Chut… silence !',
    color: '#FFF4D6',
    illustration: (
      <span className="wiggle">
        <Emoji e="🤫" size={110} />
      </span>
    ),
    text: (
      <>
        Pendant la partie, <strong>PERSONNE NE PARLE</strong>.
        <br />
        <br />
        Les joueurs se regardent seulement… dans les yeux 👀 Posez le téléphone au centre de la table.
      </>
    ),
  },
  {
    title: "4. Le clin d'œil qui tue",
    color: '#F1EAFF',
    illustration: (
      <div className="row">
        <span className="wiggle">
          <AssassinIcon size={106} />
        </span>
        <Emoji e="😉" size={48} />
        <PlayerAvatar colorIndex={2} alive={false} size={78} />
      </div>
    ),
    text: (
      <>
        Un assassin tue quelqu'un en lui faisant un clin d'œil.
        <br />
        <br />
        La victime doit attendre 2 secondes avant d'annoncer qu'elle est morte, pour ne pas trahir l'assassin trop
        vite. On la marque ensuite « Mort 💀 » dans l'appli.
      </>
    ),
  },
  {
    title: "5. J'ai un soupçon !",
    color: '#E5FAF0',
    illustration: (
      <span className="wiggle wiggle--big">
        <Emoji e="✋" size={110} />
      </span>
    ),
    text: (
      <>
        Si un joueur soupçonne quelqu'un, il lève la main.
        <br />
        <br />
        Les autres joueurs doivent valider qu'on peut passer au vote. On appuie alors sur « J'accuse ! ✋ ».
      </>
    ),
  },
  {
    title: "6. L'accusation",
    color: '#FFEDE3',
    illustration: (
      <div className="row">
        <div className="bubble" style={{ background: 'rgb(126 227 180 / .35)' }}>
          <AssassinIcon size={66} />
          <span>
            Assassin ?<br />
            Il est éliminé
          </span>
        </div>
        <div className="bubble" style={{ background: 'rgb(255 123 123 / .35)' }}>
          <CitizenIcon size={66} />
          <span>
            Innocent ?<br />
            Les 2 meurent
          </span>
        </div>
      </div>
    ),
    text: (
      <>
        L'accusateur désigne un joueur.
        <br />
        <br />
        Si c'est un assassin, l'assassin est éliminé. Si ce n'est PAS un assassin, l'accusateur ET l'accusé meurent
        tous les deux. Réfléchis bien !
      </>
    ),
  },
  {
    title: '7. Qui gagne ?',
    color: '#FFF4D6',
    illustration: (
      <span className="wiggle">
        <Emoji e="🏆" size={110} />
      </span>
    ),
    text: (
      <>
        Les <strong>CITOYENS</strong> gagnent quand tous les assassins sont éliminés.
        <br />
        <br />
        Les <strong>ASSASSINS</strong> gagnent quand il ne reste que 2 citoyens pour 1 assassin vivant (3 citoyens
        pour 2 assassins, 4 pour 3, etc.).
      </>
    ),
  },
];

/** Tutoriel en 7 pages : on glisse du doigt (scroll-snap) ou on appuie sur « Suivant ». */
export function TutorialScreen({ onDone, onBack }: { onDone: () => void; onBack: () => void }) {
  const [page, setPage] = useState(0);
  const track = useRef<HTMLDivElement>(null);

  useBack(onBack);

  const goTo = (i: number) => {
    const el = track.current;
    el?.scrollTo({ left: i * el.clientWidth, behavior: 'smooth' });
  };

  return (
    <section className="screen" style={{ background: PAGES[page].color }}>
      <TopBar
        title="Comment jouer ?"
        left={
          <button type="button" className="round-btn" onClick={onBack} aria-label="Retour à l'accueil">
            ←
          </button>
        }
      />
      <div className="dots" role="tablist" aria-label="Pages du tutoriel">
        {PAGES.map((p, i) => (
          <button
            key={p.title}
            type="button"
            role="tab"
            aria-selected={i === page}
            aria-label={`Page ${i + 1}`}
            className={`dot ${i === page ? 'dot--on' : ''}`}
            onClick={() => goTo(i)}
          />
        ))}
      </div>
      <div
        ref={track}
        className="pager"
        onScroll={(e) => {
          const el = e.currentTarget;
          const i = Math.round(el.scrollLeft / el.clientWidth);
          if (i !== page) setPage(i);
        }}
      >
        {PAGES.map((p, i) => {
          const last = i === PAGES.length - 1;
          return (
            <article key={p.title} className="pager__page">
              <div className="tuto-illustration">{p.illustration}</div>
              <h2 className="tuto-title">{p.title}</h2>
              <Card className="tuto-text">{p.text}</Card>
              {/* Le bouton suit directement le texte : il reste au milieu de l'écran. */}
              <div className="actions">
                <BigButton
                  label={last ? "J'ai compris, on joue !" : 'Suivant'}
                  emoji={last ? '🎉' : '👉'}
                  color={last ? 'var(--pink)' : 'var(--lavender)'}
                  onClick={() => (last ? onDone() : goTo(i + 1))}
                />
              </div>
            </article>
          );
        })}
      </div>
    </section>
  );
}
