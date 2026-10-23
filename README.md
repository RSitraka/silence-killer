# Clin d'Œil Assassin 😉🥷

Jeu de société en groupe, entièrement en français : les joueurs se passent **un seul
téléphone** pour découvrir leur rôle en secret (Citoyen ou Assassin), puis jouent
**sans parler**, à coups de clins d'œil.

Le dépôt contient deux applications indépendantes, avec deux stacks distinctes :

```
.
├── mobile/        # Application Android — Flutter / Dart  → APK
├── web/           # Application web — React + TypeScript + Vite (PWA)  → Netlify
├── netlify.toml   # Déploiement Netlify (ne construit que web/)
└── README.md
```

| | `mobile/` | `web/` |
|---|---|---|
| Langage | Dart | TypeScript |
| Interface | Flutter (CustomPainter) | React + CSS, icônes en SVG |
| Hors ligne | oui (tout est dans l'APK) | oui, après la 1re visite (service worker) |
| Écran allumé | `wakelock_plus` | API Screen Wake Lock |
| Tests | `flutter test` | `npm test` (Vitest) |
| Livrable | `app-release.apk` | site statique `web/dist/` |

Les deux versions ont les mêmes règles, les mêmes écrans, les mêmes icônes, la même
police (Fredoka, embarquée) et les mêmes sons. Les règles de victoire sont isolées
dans un seul fichier par application, facile à modifier :
[`mobile/lib/logic/victory.dart`](mobile/lib/logic/victory.dart) et
[`web/src/logic/game.ts`](web/src/logic/game.ts).

## Application mobile (Android)

Voir [`mobile/README.md`](mobile/README.md). En bref :

```bash
cd mobile
flutter pub get
flutter build apk --release
# → mobile/build/app/outputs/flutter-apk/app-release.apk
```

## Application web

Prérequis : **Node.js 20 ou plus récent**.

```bash
cd web
npm install
npm run dev       # développement : http://localhost:5173
npm test          # tests des règles
npm run build     # version de production dans web/dist/
npm run preview   # tester la version de production : http://localhost:4173
```

Sur téléphone, le site peut être **ajouté à l'écran d'accueil** (« Installer l'application »
dans Chrome, « Sur l'écran d'accueil » dans Safari) : il s'ouvre alors en plein écran,
comme une vraie appli, et fonctionne sans connexion.

### Organisation du code web

```
web/
├── index.html
├── vite.config.ts            # Vite + PWA (manifeste, service worker hors ligne)
├── public/
│   ├── fonts/                # Fredoka (licence SIL OFL)
│   ├── sounds/               # petits sons .wav
│   └── icons/                # icônes PWA + favicon
└── src/
    ├── main.tsx              # point d'entrée
    ├── App.tsx               # enchaînement des écrans + bouton « retour » du navigateur
    ├── styles.css            # thème pastel, gros boutons, animations
    ├── logic/game.ts         # ★ règles du jeu (fonctions pures) + game.test.ts
    ├── hooks/
    │   ├── sound.tsx         # sons + bouton « couper le son » (mémorisé)
    │   └── browser.ts        # écran allumé, retour bloqué, confirmation de sortie
    ├── components/
    │   ├── Icons.tsx         # Citoyen / Assassin / fantôme / avatars en SVG
    │   └── ui.tsx            # boutons, sélecteur −/+, fenêtres, confettis
    └── screens/              # Accueil, Tutoriel, Préparation, Distribution,
                              # Partie, Accusation, Fin de partie
```

Spécificités du navigateur :
- le bouton / geste **retour** du navigateur est intercepté : bloqué pendant la
  distribution des rôles, confirmation pour quitter pendant la partie ;
- fermer ou recharger l'onglet pendant une partie demande confirmation ;
- un rôle affiché est caché immédiatement si l'onglet passe en arrière-plan.

## Déployer la version web sur Netlify

Le fichier [`netlify.toml`](netlify.toml) contient déjà tout le réglage
(dossier `web/`, commande `npm run build`, dossier publié `dist/`, Node 20,
redirection d'application monopage). Deux façons de faire :

**A. Depuis GitHub (recommandé — chaque `git push` redéploie le site)**

1. Pousser le dépôt sur GitHub.
2. Sur <https://app.netlify.com> : **Add new site → Import an existing project → GitHub**,
   puis choisir ce dépôt.
3. Netlify lit `netlify.toml` : ne rien changer, cliquer sur **Deploy**.
4. (Facultatif) **Site configuration → Change site name** pour une adresse comme
   `clin-doeil-assassin.netlify.app`.

**B. En ligne de commande**

```bash
npm install -g netlify-cli
netlify login                 # ouvre le navigateur une seule fois
netlify init                  # crée / relie le site (depuis la racine du dépôt)
netlify deploy --build --prod
```
