import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';

void main() {
  ProductionSession buildSession({required int lastProcessedAt}) {
    return ProductionSession(
      kind: ProductionKind.smelting,
      recipeId: 'smelt_copper',
      displayName: 'Barra de cobre',
      quantity: 1,
      durationMilliseconds: 4000,
      timeRemainingMilliseconds: 4000,
      lastProcessedAt: lastProcessedAt,
      goldCost: 0,
      resourceCost: const {'copper': 1},
      skillId: 'smithing',
      experience: 5,
    );
  }

  test('clock moving backwards reports no elapsed production time', () {
    final startedAt = DateTime(2026, 1, 1, 12);
    final session = buildSession(
      lastProcessedAt: startedAt.millisecondsSinceEpoch,
    );

    expect(
      session.elapsedMillisecondsAt(
        startedAt.subtract(const Duration(minutes: 10)),
      ),
      0,
    );
  });

  test('clock jumping far forward caps elapsed production time at 24h', () {
    final startedAt = DateTime(2026, 1, 1, 12);
    final session = buildSession(
      lastProcessedAt: startedAt.millisecondsSinceEpoch,
    );

    expect(
      session.elapsedMillisecondsAt(startedAt.add(const Duration(days: 30))),
      const Duration(hours: 24).inMilliseconds,
    );
  });

  test('repeatWhenDone defaults to false and round-trips through JSON', () {
    final defaultSession = buildSession(lastProcessedAt: 0);
    expect(defaultSession.repeatWhenDone, isFalse);

    final repeatingSession = ProductionSession(
      kind: ProductionKind.smelting,
      recipeId: 'smelt_copper',
      displayName: 'Barra de cobre',
      quantity: 1,
      durationMilliseconds: 4000,
      timeRemainingMilliseconds: 4000,
      lastProcessedAt: 0,
      goldCost: 0,
      resourceCost: const {'copper': 1},
      skillId: 'smithing',
      experience: 5,
      repeatWhenDone: true,
    );

    expect(
      ProductionSession.fromJson(repeatingSession.toJson()).repeatWhenDone,
      isTrue,
    );

    final legacyJson = Map<String, dynamic>.from(defaultSession.toJson())
      ..remove('repeatWhenDone');
    expect(ProductionSession.fromJson(legacyJson).repeatWhenDone, isFalse);
  });
}
