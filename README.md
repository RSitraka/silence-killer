# Clin d'Œil Assassin 😉🥷

Jeu de société en groupe pour Android, **100 % hors ligne**, entièrement en français.
Les joueurs se passent un seul téléphone pour découvrir leur rôle en secret, puis le posent
au centre : pendant la partie, personne ne parle… on se regarde seulement.

## Structure du projet

```
.
├── pubspec.yaml                 # dépendances, polices, sons, config de l'icône
├── analysis_options.yaml
├── assets/
│   ├── fonts/Fredoka-*.ttf      # police ronde Fredoka (licence SIL OFL, voir OFL.txt)
│   ├── icon/icon.png            # icône de l'application (1024×1024)
│   ├── icon/icon_foreground.png # premier plan de l'icône adaptative Android
│   └── sounds/*.wav             # petits sons synthétisés (tap, révélation, tambour…)
├── tool/generate_assets.py      # script qui (re)génère sons, icône et polices
├── lib/
│   ├── main.dart                # point d'entrée : portrait, Provider, thème
│   ├── theme.dart               # palette pastel + thème Material
│   ├── models/player.dart       # Player + enum Role
│   ├── logic/victory.dart       # ★ RÈGLES DE VICTOIRE (fonctions séparées, faciles à modifier)
│   ├── state/game_state.dart    # état de la partie (ChangeNotifier)
│   ├── services/sound_service.dart  # sons + bouton « couper le son » (mémorisé)
│   ├── widgets/
│   │   ├── role_icons.dart      # icônes Citoyen / Assassin / fantôme / avatars (CustomPainter)
│   │   └── common.dart          # gros boutons, rebonds, confettis, sélecteur −/+
│   └── screens/
│       ├── home_screen.dart         # accueil : « Comment jouer ? » / « Jouer »
│       ├── tutorial_screen.dart     # tutoriel en 7 pages (PageView + points)
│       ├── setup_screen.dart        # étape A : joueurs, prénoms, assassins
│       ├── distribution_screen.dart # étape B : distribution secrète des rôles
│       ├── game_screen.dart         # étape C : partie (cartes, Mort/Vivant, victoire)
│       ├── accuse_screen.dart       # « J'accuse ! » : accusateur, accusé, tambour, révélation
│       └── end_screen.dart          # étape D : confettis + rôles de tous
├── test/victory_test.dart       # tests des règles de victoire et de l'état
└── android/                     # projet Android généré par Flutter (portrait, nom de l'appli)
```

## Points importants

- **Icônes très distinctes** (forme ET couleur, lisibles pour les daltoniens) :
  Citoyen = **rond** bleu ciel/vert, souriant avec un cœur ;
  Assassin = **étoile pointue** violet/rouge, ninja qui fait un clin d'œil.
  Tout est dessiné avec `CustomPainter` — aucune image sous droits d'auteur.
- **Secret des rôles** : bouton retour bloqué pendant la distribution, rôle caché dès
  qu'on appuie sur « J'ai retenu, cacher » ou si l'application passe en arrière-plan,
  écran neutre entre deux joueurs. Pendant la partie, les rôles ne sont jamais affichés.
- **Victoire** (`lib/logic/victory.dart`) :
  citoyens = plus aucun assassin vivant ; assassins = citoyens vivants ≤ assassins vivants + 1.
  Le nombre maximal d'assassins se calcule à partir de cette même règle : strictement moins
  de la moitié des joueurs **et** pas de victoire immédiate des assassins au départ
  (ex. 5 joueurs → 1 assassin maximum, sinon 3 citoyens contre 2 assassins = victoire immédiate).
- **Police** : la demande mentionnait `google_fonts`, mais ce paquet télécharge les polices
  sur Internet au premier lancement. Pour un jeu **hors ligne**, Fredoka est donc embarquée
  directement dans l'APK (même police, même rendu, aucun réseau nécessaire).
- Écran maintenu allumé pendant la distribution et la partie (`wakelock_plus`),
  orientation portrait uniquement, confirmation avant de quitter une partie en cours.

## Générer l'APK pas à pas

### 1. Installer les outils (une seule fois)

1. **Flutter** (version stable) : <https://docs.flutter.dev/get-started/install>
   puis vérifier avec `flutter --version`.
2. **Android Studio** (ou seulement les « command-line tools » Android) :
   <https://developer.android.com/studio>. Dans le SDK Manager, installer
   *Android SDK Platform*, *Build-Tools* et *Platform-Tools*.
3. Un **JDK 17** (fourni avec Android Studio).
4. Accepter les licences Android :
   ```bash
   flutter doctor --android-licenses
   ```
5. Vérifier que tout est vert pour Android :
   ```bash
   flutter doctor
   ```

### 2. Récupérer les dépendances

Dans le dossier du projet :

```bash
flutter pub get
```

### 3. (Facultatif) Regénérer les ressources

Les sons, l'icône et les polices sont déjà fournis dans `assets/`. Pour les regénérer :

```bash
pip install pillow fonttools
python tool/generate_assets.py
dart run flutter_launcher_icons     # recopie l'icône dans android/app/src/main/res
```

### 4. Lancer les tests (facultatif)

```bash
flutter test
```

### 5. Compiler l'APK

```bash
flutter build apk --release
```

L'APK se trouve ici (compatible Android 7.0 et plus récent) :

```
build/app/outputs/flutter-apk/app-release.apk
```

Astuce : `flutter build apk --release --split-per-abi` produit des APK plus légers,
un par type de processeur (`app-arm64-v8a-release.apk` convient à la quasi-totalité
des téléphones récents).

### 6. Installer sur le téléphone

- Par câble USB (débogage USB activé) : `flutter install` ou
  `adb install build/app/outputs/flutter-apk/app-release.apk`
- Ou copier le fichier `.apk` sur le téléphone et l'ouvrir
  (autoriser « Installer des applications inconnues »).

### 7. (Pour publier sur le Play Store) Signer avec votre propre clé

Par défaut, l'APK de release est signé avec la clé de débogage : parfait pour jouer
entre amis, mais pas pour le Play Store. Suivez alors
<https://docs.flutter.dev/deployment/android#signing-the-app>.

## Modifier les règles

Ouvrez `lib/logic/victory.dart` et changez `assassinsHaveWon` (ou `citizensHaveWon`).
Le nombre maximal d'assassins proposé à la configuration s'adapte automatiquement.
Relancez `flutter test` pour vérifier (adaptez les tests si vous changez la règle).
