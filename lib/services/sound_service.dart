import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les effets sonores disponibles (fichiers dans assets/sounds/).
enum Sfx { tap, reveal, death, drumroll, success, fail, victory }

/// Joue de courts sons embarqués. Le son peut être coupé (réglage mémorisé).
class SoundService extends ChangeNotifier {
  static const _prefKey = 'muted';

  bool _muted = false;
  bool get muted => _muted;

  // Un lecteur par son : évite de recréer des lecteurs à chaque appui.
  final Map<Sfx, AudioPlayer> _players = {};

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_prefKey) ?? false;
    } catch (_) {
      // Pas de préférences disponibles : on garde le son activé.
    }
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    notifyListeners();
    if (_muted) {
      for (final p in _players.values) {
        p.stop();
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, _muted);
    } catch (_) {}
  }

  Future<void> play(Sfx sfx) async {
    if (_muted) return;
    try {
      final player = _players.putIfAbsent(sfx, () {
        final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        // Ne coupe pas la musique éventuelle des autres applications.
        p.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/${sfx.name}.wav'));
    } catch (e) {
      // Un son raté ne doit jamais bloquer le jeu.
      debugPrint('Son indisponible ($sfx) : $e');
    }
  }

  void stop(Sfx sfx) => _players[sfx]?.stop();

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}
