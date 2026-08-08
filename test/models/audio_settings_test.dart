import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/models/audio_settings.dart';

void main() {
  group('AudioSettings', () {
    test('defaults when constructed without arguments', () {
      final settings = AudioSettings();

      expect(settings.musicVolume, AudioSettings.defaultMusicVolume);
      expect(settings.sfxVolume, AudioSettings.defaultSfxVolume);
      expect(settings.muted, isFalse);
    });

    test('round-trips through JSON', () {
      final settings = AudioSettings(
        musicVolume: 0.35,
        sfxVolume: 0.05,
        muted: true,
      );

      final restored = AudioSettings.fromJson(settings.toJson());

      expect(restored.musicVolume, 0.35);
      expect(restored.sfxVolume, 0.05);
      expect(restored.muted, isTrue);
    });

    test('falls back to defaults for missing or invalid JSON', () {
      expect(AudioSettings.fromJson(null).musicVolume, AudioSettings.defaultMusicVolume);
      expect(AudioSettings.fromJson('not a map').sfxVolume, AudioSettings.defaultSfxVolume);
      final fromEmpty = AudioSettings.fromJson(<String, dynamic>{});
      expect(fromEmpty.musicVolume, AudioSettings.defaultMusicVolume);
      expect(fromEmpty.sfxVolume, AudioSettings.defaultSfxVolume);
      expect(fromEmpty.muted, isFalse);
    });

    test('clamps out-of-range volumes from JSON', () {
      final settings = AudioSettings.fromJson({
        'musicVolume': 4.5,
        'sfxVolume': -3,
        'muted': 'yes',
      });

      expect(settings.musicVolume, 1.0);
      expect(settings.sfxVolume, 0.0);
      expect(settings.muted, isFalse);
    });
  });
}
