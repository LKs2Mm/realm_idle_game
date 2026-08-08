import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/models/notification_settings.dart';

void main() {
  group('NotificationSettings', () {
    test('defaults to disabled (opt-in)', () {
      expect(NotificationSettings().enabled, isFalse);
    });

    test('round-trips through JSON', () {
      final settings = NotificationSettings(enabled: true);

      final restored = NotificationSettings.fromJson(settings.toJson());

      expect(restored.enabled, isTrue);
    });

    test('falls back to disabled for missing or invalid JSON', () {
      expect(NotificationSettings.fromJson(null).enabled, isFalse);
      expect(NotificationSettings.fromJson('not a map').enabled, isFalse);
      expect(
        NotificationSettings.fromJson(<String, dynamic>{}).enabled,
        isFalse,
      );
      expect(
        NotificationSettings.fromJson({'enabled': 'yes'}).enabled,
        isFalse,
      );
    });
  });
}
