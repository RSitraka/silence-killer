import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { registerSW } from 'virtual:pwa-register';
import App from './App';
import { SoundProvider } from './hooks/sound';
import './styles.css';

// Service worker : met le jeu en cache pour qu'il marche hors ligne.
registerSW({ immediate: true });

/**
 * L'hébergeur (Netlify) peut ajouter un badge flottant en bas de l'écran, par-dessus
 * les gros boutons du jeu. On mesure la place qu'il occupe et on la réserve
 * (variable CSS --host-badge) pour qu'il ne masque jamais un bouton.
 */
function reserveSpaceForHostBadge() {
  const update = () => {
    const badge = document.getElementById('nl-badge-frame');
    const rect = badge?.getBoundingClientRect();
    const space = rect && rect.height > 0 ? Math.max(0, window.innerHeight - rect.top) : 0;
    document.documentElement.style.setProperty('--host-badge', `${Math.ceil(space)}px`);
  };
  // Le badge est ajouté directement dans <body>, après le chargement de la page.
  new MutationObserver(update).observe(document.body, { childList: true });
  window.addEventListener('resize', update);
  update();
  [1000, 3000, 6000].forEach((ms) => setTimeout(update, ms));
}
reserveSpaceForHostBadge();

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <SoundProvider>
      <App />
    </SoundProvider>
  </StrictMode>,
);
