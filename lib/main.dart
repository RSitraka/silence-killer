import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/sound_service.dart';
import 'state/game_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait uniquement.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final sounds = SoundService();
  await sounds.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()),
        ChangeNotifierProvider.value(value: sounds),
      ],
      child: const ClinDOeilApp(),
    ),
  );
}

class ClinDOeilApp extends StatelessWidget {
  const ClinDOeilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Clin d'Œil Assassin",
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const HomeScreen(),
    );
  }
}
