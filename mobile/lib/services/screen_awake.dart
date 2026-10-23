import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Garde l'écran allumé (ou non). Une erreur ici ne doit jamais bloquer le jeu.
Future<void> keepScreenOn(bool on) async {
  try {
    await WakelockPlus.toggle(enable: on);
  } catch (e) {
    debugPrint('Wakelock indisponible : $e');
  }
}
