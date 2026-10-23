import 'package:clin_doeil_assassin/main.dart';
import 'package:clin_doeil_assassin/screens/distribution_screen.dart';
import 'package:clin_doeil_assassin/screens/end_screen.dart';
import 'package:clin_doeil_assassin/screens/game_screen.dart';
import 'package:clin_doeil_assassin/screens/setup_screen.dart';
import 'package:clin_doeil_assassin/services/sound_service.dart';
import 'package:clin_doeil_assassin/state/game_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Parcourt tous les écrans sur un PETIT téléphone (360×690) avec 20 joueurs
/// aux prénoms longs : tout débordement de mise en page fait échouer le test.
///
/// Captures d'écran (facultatif) :
///   flutter test test/screens_test.dart --dart-define=SNAP=true --update-goldens
const _snap = bool.fromEnvironment('SNAP');

final _names = [for (var i = 1; i <= 20; i++) 'Maximilienne${i.toString().padLeft(2, '0')}'];

Future<void> _loadFonts() async {
  final loader = FontLoader('Fredoka');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Fredoka-$w.ttf'));
  }
  await loader.load();
}

/// Avance le temps par petites étapes pour que les animations se déroulent vraiment.
Future<void> wait(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late GameState game;
  late SoundService sounds;

  setUpAll(_loadFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({'muted': true});
    sounds = SoundService();
    await sounds.init();
    game = GameState()..startGame(_names, 9);
  });

  Future<void> pumpApp(WidgetTester tester, [Widget? home]) async {
    tester.view.physicalSize = const Size(360 * 3, 690 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: game),
          ChangeNotifierProvider.value(value: sounds),
        ],
        child: home == null
            ? const ClinDOeilApp()
            : MaterialApp(theme: ThemeData(fontFamily: 'Fredoka'), home: home),
      ),
    );
    await wait(tester, 1000);
  }

  Future<void> snap(WidgetTester tester, String name) async {
    if (!_snap) return;
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('accueil et tutoriel', (tester) async {
    await pumpApp(tester);
    await snap(tester, '01_accueil');
    await tester.tap(find.text('Comment jouer ?'));
    await wait(tester, 1000);
    for (var i = 0; i < 6; i++) {
      await snap(tester, '02_tuto_$i');
      await tester.tap(find.text('Suivant'));
      await wait(tester, 1000);
    }
    expect(find.text("J'ai compris, on joue !"), findsOneWidget);
    await snap(tester, '02_tuto_6');
  });

  testWidgets('configuration avec 20 joueurs', (tester) async {
    await pumpApp(tester, const SetupScreen());
    await snap(tester, '03_config');
    expect(find.text('20'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("🥷 Combien d'assassins ?"),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await wait(tester, 1000);
    expect(find.text('maximum 9 pour 20 joueurs'), findsOneWidget);
    await snap(tester, '04_config_bas');
  });

  testWidgets('distribution secrète des rôles', (tester) async {
    await pumpApp(tester, const DistributionScreen());
    expect(find.text(_names.first), findsOneWidget);
    await snap(tester, '05_passe');
    for (var i = 0; i < _names.length; i++) {
      await tester.tap(find.text("C'est moi, voir mon rôle"));
      await wait(tester, 1000);
      expect(find.text('Tu es'), findsOneWidget);
      if (i < 2) await snap(tester, '06_role_$i');
      await tester.tap(find.text("J'ai retenu, cacher"));
      await wait(tester, 500);
      await wait(tester, 100);
      expect(find.text('Tu es'), findsNothing);
      await wait(tester, 2000);
    }
    expect(find.text('Tout le monde est prêt ?'), findsOneWidget);
    await snap(tester, '07_pret');
  });

  testWidgets('partie : mort avec compte à rebours, accusation, victoire', (tester) async {
    game.startGame(_names, 2); // peu d'assassins : pas de victoire dès le premier mort
    await pumpApp(tester, const GameScreen());
    await snap(tester, '08_partie');

    // Déclarer le premier joueur mort (compte à rebours de 2 s).
    await tester.tap(find.text(_names.first));
    await wait(tester, 500);
    await snap(tester, '09_dialogue');
    await tester.tap(find.text('Mort'));
    await wait(tester, 600);
    await snap(tester, '10_compte_a_rebours');
    expect(game.players.first.alive, isTrue);
    await wait(tester, 2000);
    await wait(tester, 500);
    expect(game.players.first.alive, isFalse);

    // Accusation.
    await tester.tap(find.text("J'accuse !"));
    await wait(tester, 1000);
    await snap(tester, '11_accusateur');
    final alive = game.alivePlayers;
    await tester.tap(find.text(alive[0].name));
    await wait(tester, 1000);
    await tester.tap(find.text(alive[1].name));
    await wait(tester, 800);
    await snap(tester, '12_tambour');
    await wait(tester, 2000);
    await wait(tester, 800);
    await snap(tester, '13_revelation');
    expect(alive[1].alive, isFalse);
    await tester.tap(find.text('Continuer'));
    await wait(tester, 1000);

    // Tous les assassins morts, puis un citoyen déclaré mort → fenêtre de victoire.
    for (final a in game.assassins) {
      game.setAlive(a, false);
    }
    await tester.pump();
    final citizen = game.alivePlayers.first;
    await tester.tap(find.text(citizen.name));
    await wait(tester, 500);
    await tester.tap(find.text('Mort'));
    await wait(tester, 2100);
    await wait(tester, 1000);
    expect(find.text('Victoire des Citoyens ! 🎉'), findsOneWidget);
    await snap(tester, '14_victoire');
    await tester.tap(find.text('Corriger une erreur'));
    await wait(tester, 1000);
    expect(find.text('Victoire des Citoyens ! 🎉'), findsNothing);
  });

  testWidgets('fin de partie', (tester) async {
    for (final a in game.assassins) {
      game.setAlive(a, false);
    }
    await pumpApp(tester, const EndScreen());
    expect(find.text('Voici les rôles de chacun :'), findsOneWidget);
    await snap(tester, '15_fin');
  });
}
