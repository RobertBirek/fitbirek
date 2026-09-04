import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Serwis odtwarzający sygnał końca przerwy (gong).
///
/// Jeśli plik `assets/sounds/gong.mp3` nie jest jeszcze dostarczony
/// (starter pack aplikacji na razie go nie zawiera), automatycznie
/// używamy systemowego dźwięku alertu jako funkcjonalnego fallbacku -
/// użytkownik i tak usłyszy sygnał końca przerwy.
///
/// TODO: wygenerować/dodać prawdziwy plik gong.mp3 do assets/sounds/
/// (patrz README.md - sekcja "Dźwięki").
class GongService {
  GongService._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playGong() async {
    try {
      await _player.play(AssetSource('sounds/gong.mp3'));
    } catch (_) {
      // Fallback - brak pliku audio, ale użytkownik musi usłyszeć koniec przerwy.
      SystemSound.play(SystemSoundType.alert);
    }
  }
}
