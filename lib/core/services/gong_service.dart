import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Serwis odtwarzający sygnał końca przerwy (gong).
///
/// Odtwarza plik `assets/sounds/gong.mp3`. Jeśli z jakiegoś powodu
/// odtworzenie się nie powiedzie (np. problem z audio na danym
/// urządzeniu), automatycznie używamy systemowego dźwięku alertu
/// jako funkcjonalnego fallbacku - użytkownik i tak usłyszy sygnał
/// końca przerwy.
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
