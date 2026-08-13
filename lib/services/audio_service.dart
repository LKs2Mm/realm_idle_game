import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:realm_idle_game/models/audio_settings.dart';

/// Serviço estático de áudio (música de fundo em loop + efeitos sonoros
/// avulsos). Todas as chamadas são silenciosamente descartadas em caso de
/// erro — asset ainda não gerado, ou canal de plataforma indisponível
/// (testes de widget não têm o plugin `audioplayers` mockado) — para que
/// áudio nunca derrube o app ou quebre um teste.
abstract final class AudioService {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static double _musicVolume = AudioSettings.defaultMusicVolume;
  static double _sfxVolume = AudioSettings.defaultSfxVolume;
  static bool _muted = false;
  static String? _currentMusicAsset;

  static Future<void> initialize(AudioSettings settings) async {
    await _safe(() => _musicPlayer.setReleaseMode(ReleaseMode.loop));
    await applySettings(settings);
  }

  static Future<void> applySettings(AudioSettings settings) async {
    _musicVolume = settings.musicVolume;
    _sfxVolume = settings.sfxVolume;
    _muted = settings.muted;
    await _safe(() => _musicPlayer.setVolume(_muted ? 0 : _musicVolume));
  }

  static Future<void> playMusic(String assetPath) async {
    if (_currentMusicAsset == assetPath) return;
    await _safe(() async {
      await _musicPlayer.stop();
      await _musicPlayer.play(
        AssetSource(assetPath),
        volume: _muted ? 0 : _musicVolume,
      );
      // Só marca como "tocando" depois que .play() não lança exceção. Se
      // isso rodar antes do primeiro gesto do usuário, o navegador pode
      // bloquear o autoplay e lançar aqui — nesse caso _currentMusicAsset
      // continua null, permitindo que uma tentativa futura (após um gesto
      // real) tente de novo em vez de ficar presa achando que já tocou.
      _currentMusicAsset = assetPath;
    });
  }

  static Future<void> stopMusic() async {
    _currentMusicAsset = null;
    await _safe(() => _musicPlayer.stop());
  }

  static Future<void> pauseMusic() async {
    await _safe(() => _musicPlayer.pause());
  }

  static Future<void> resumeMusic() async {
    if (_currentMusicAsset == null) return;
    await _safe(() => _musicPlayer.resume());
  }

  static Future<void> playSfx(String assetPath) async {
    if (_muted || _sfxVolume <= 0) return;
    final player = AudioPlayer();
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 6),
      ).then((_) => _safe(player.dispose)),
    );
    await _safe(() => player.play(AssetSource(assetPath), volume: _sfxVolume));
  }

  static Future<void> _safe(FutureOr<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Sem plugin de áudio disponível (testes) ou asset ainda não
      // gerado — falha silenciosa, nunca deve interromper o app.
    }
  }
}
