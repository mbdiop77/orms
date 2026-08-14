//import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Génère un bip via l'API Web Audio du navigateur — pas besoin de fichier
/// audio. Fonctionne uniquement sur Flutter Web.
class BeepService {
  static void jouer({
    double frequence = 880,
    int dureeMs = 180,
    double volume = 0.8,
  }) {
    try {
      final ctx = web.AudioContext();
      final oscillator = ctx.createOscillator();
      final gain = ctx.createGain();

      oscillator.type = 'sine';
      oscillator.frequency.setValueAtTime(frequence, ctx.currentTime);

      gain.gain.setValueAtTime(0.001, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(
        volume,
        ctx.currentTime + 0.02,
      );
      gain.gain.exponentialRampToValueAtTime(
        0.001,
        ctx.currentTime + dureeMs / 1000,
      );

      oscillator.connect(gain);
      gain.connect(ctx.destination);

      oscillator.start();

      Future.delayed(Duration(milliseconds: dureeMs + 50), () {
        oscillator.stop();
        ctx.close();
      });
    } catch (_) {}
  }

  /// Quatre bips pour les événements importants.
static void jouerQuadruple() {
  for (int i = 0; i < 4; i++) {
    Future.delayed(Duration(milliseconds: i * 200), () {
      jouer(
        frequence: 740,
        dureeMs: 140,
        volume: 0.8,
      );
    });
  }
}
}