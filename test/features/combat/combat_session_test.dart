import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/combat/models/combat_session.dart';

void main() {
  test('progress and elapsed time use milliseconds', () {
    final startedAt = DateTime(2026, 1, 1, 12);
    final session = CombatSession(
      encounterId: 'grave_rat',
      cycleDurationMilliseconds: 4000,
      timeRemainingMilliseconds: 3000,
      lastProcessedAt: startedAt.millisecondsSinceEpoch,
    );

    expect(session.progress, 0.25);
    expect(
      session.elapsedMillisecondsAt(
        startedAt.add(const Duration(milliseconds: 1250)),
      ),
      1250,
    );
  });

  test('session round-trips with its queued encounter', () {
    final session = CombatSession(
      encounterId: 'grave_rat',
      cycleDurationMilliseconds: 4000,
      timeRemainingMilliseconds: 1750,
      lastProcessedAt: 1767268800000,
      queuedEncounterId: 'rune_cultist',
    );

    final restored = CombatSession.fromJson(session.toJson());

    expect(restored.encounterId, session.encounterId);
    expect(
      restored.cycleDurationMilliseconds,
      session.cycleDurationMilliseconds,
    );
    expect(
      restored.timeRemainingMilliseconds,
      session.timeRemainingMilliseconds,
    );
    expect(restored.lastProcessedAt, session.lastProcessedAt);
    expect(restored.queuedEncounterId, session.queuedEncounterId);
  });

  test('legacy second fields are safely migrated to milliseconds', () {
    final restored = CombatSession.fromJson({
      'encounterId': 'grave_rat',
      'cycleDurationSeconds': 4,
      'timeRemainingSeconds': 2,
      'lastProcessedAt': 1767268800000,
    });

    expect(restored.cycleDurationMilliseconds, 4000);
    expect(restored.timeRemainingMilliseconds, 2000);
  });

  test('unsafe persisted durations are clamped', () {
    final restored = CombatSession.fromJson({
      'encounterId': 'grave_rat',
      'cycleDurationMilliseconds': 999999999,
      'timeRemainingMilliseconds': -50,
      'lastProcessedAt': -1,
    });

    expect(restored.cycleDurationMilliseconds, 86400000);
    expect(restored.timeRemainingMilliseconds, 1);
    expect(restored.lastProcessedAt, 0);
  });

  test('clock moving backwards reports no elapsed combat time', () {
    final startedAt = DateTime(2026, 1, 1, 12);
    final session = CombatSession(
      encounterId: 'grave_rat',
      cycleDurationMilliseconds: 4000,
      timeRemainingMilliseconds: 4000,
      lastProcessedAt: startedAt.millisecondsSinceEpoch,
    );

    expect(
      session.elapsedMillisecondsAt(
        startedAt.subtract(const Duration(minutes: 10)),
      ),
      0,
    );
  });

  test('malformed persisted sessions are rejected', () {
    expect(
      () => CombatSession.fromJson({'encounterId': 'grave_rat'}),
      throwsFormatException,
    );
    expect(() => CombatSession.fromJson('invalid'), throwsFormatException);
  });
}
