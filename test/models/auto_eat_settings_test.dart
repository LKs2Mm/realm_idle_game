import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/models/auto_eat_settings.dart';

void main() {
  group('AutoEatSettings', () {
    test('defaults to disabled (opt-in) at 50%', () {
      final settings = AutoEatSettings();
      expect(settings.enabled, isFalse);
      expect(settings.thresholdPercent, 50);
    });

    test('round-trips through JSON', () {
      final settings = AutoEatSettings(enabled: true, thresholdPercent: 30);

      final restored = AutoEatSettings.fromJson(settings.toJson());

      expect(restored.enabled, isTrue);
      expect(restored.thresholdPercent, 30);
    });

    test('falls back to defaults for missing or invalid JSON', () {
      expect(AutoEatSettings.fromJson(null).enabled, isFalse);
      expect(AutoEatSettings.fromJson('not a map').enabled, isFalse);
      expect(
        AutoEatSettings.fromJson(<String, dynamic>{}).thresholdPercent,
        50,
      );
      expect(
        AutoEatSettings.fromJson({'enabled': 'yes'}).enabled,
        isFalse,
      );
      expect(
        AutoEatSettings.fromJson({'thresholdPercent': 'low'}).thresholdPercent,
        50,
      );
    });

    test('clamps an out-of-range threshold read from JSON', () {
      expect(
        AutoEatSettings.fromJson({'thresholdPercent': 5}).thresholdPercent,
        AutoEatSettings.minThresholdPercent,
      );
      expect(
        AutoEatSettings.fromJson({'thresholdPercent': 999}).thresholdPercent,
        AutoEatSettings.maxThresholdPercent,
      );
    });
  });
}
