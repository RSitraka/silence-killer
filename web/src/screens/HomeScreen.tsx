import { AssassinIcon, CitizenIcon } from '../components/Icons';
import { BigButton, MuteButton } from '../components/ui';

/** Écran d'accueil : « Comment jouer ? » et « Jouer ». */
export function HomeScreen({ onTutorial, onPlay }: { onTutorial: () => void; onPlay: () => void }) {
  return (
    <section className="screen screen--home">
      <div className="topbar topbar--end">
        <MuteButton />
      </div>
      <div className="screen__center">
        <div className="home-icons">
          <span className="bounce-in wiggle">
            <CitizenIcon size={120} />
          </span>
          <span className="bounce-in wiggle wiggle--late">
            <AssassinIcon size={130} />
          </span>
        </div>
        <h1 className="home-title bounce-in" style={{ animationDelay: '0.3s' }}>
          Clin d'Œil
          <br />
          Assassin
        </h1>
        <p className="subtitle">Le jeu du silence et des regards 👀</p>
        <div className="stack">
          <BigButton label="Comment jouer ?" emoji="📖" color="var(--citizen-blue)" onClick={onTutorial} />
          <BigButton label="Jouer" emoji="🎲" size="lg" color="var(--pink)" onClick={onPlay} />
        </div>
      </div>
    </section>
  );
}
