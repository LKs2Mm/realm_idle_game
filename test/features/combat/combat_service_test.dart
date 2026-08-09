import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/features/combat/services/combat_service.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';

void main() {
  late DateTime currentTime;
  late GameState state;
  late CombatService service;
  late List<bool> saveRequests;

  setUp(() {
    currentTime = DateTime(2026, 1, 1, 12);
    state = GameState();
    saveRequests = [];
    service = CombatService(
      onUpdate: (_, shouldSave) => saveRequests.add(shouldSave),
      now: () => currentTime,
      enableTimer: false,
    );
    service.initialize(state);
  });

  tearDown(() => service.dispose());

  test('selection starts continuous combat without click rewards', () {
    service.selectEncounter('grave_rat');

    expect(state.activeCombatSession?.encounterId, 'grave_rat');
    expect(state.gold, 0);
    expect(state.skills['attack']?.experience, 0);
    expect(saveRequests, [true]);
  });

  test('partial progress grants nothing and one full cycle grants once', () {
    service.selectEncounter('grave_rat');
    currentTime = currentTime.add(const Duration(milliseconds: 3999));

    final partial = service.advanceTo(currentTime);

    expect(partial.hasRewards, isFalse);
    expect(state.gold, 0);
    expect(state.activeCombatSession?.timeRemainingMilliseconds, 1);

    currentTime = currentTime.add(const Duration(milliseconds: 1));
    final completed = service.advanceTo(currentTime);

    expect(completed.completedVictories, 1);
    expect(completed.victoriesByEncounter, {'grave_rat': 1});
    expect(completed.goldEarned, 2);
    expect(completed.experienceEarned, 3);
    expect(completed.damageTaken, 1);
    expect(completed.wasDefeated, isFalse);
    expect(state.gold, 2);
    expect(state.currentHealth, state.maxHealth - 1);
    expect(state.skills['attack']?.experience, 3);
    expect(state.activeCombatSession?.timeRemainingMilliseconds, 4000);
  });

  test(
    'offline progress stops at the real victories survivable by the hero',
    () {
      service.selectEncounter('grave_rat');
      currentTime = currentTime.add(const Duration(hours: 12));

      final result = service.advanceTo(currentTime);

      expect(result.completedVictories, 100);
      expect(result.goldEarned, 200);
      expect(result.experienceEarned, 300);
      expect(result.damageTaken, 100);
      expect(result.wasDefeated, isTrue);
      expect(result.sessionEnded, isTrue);
      expect(result.victoriesByEncounter, {'grave_rat': 100});
      expect(state.gold, 200);
      expect(state.currentHealth, 0);
      expect(state.activeCombatSession, isNull);
    },
  );

  test('a new target is queued and switches only after current cycle', () {
    final attack = state.skills['attack']!;
    attack.level = 10;
    attack.experienceToNextLevel = Skill.experienceRequiredForLevel(10);
    service.selectEncounter('grave_rat');

    currentTime = currentTime.add(const Duration(seconds: 1));
    service.selectEncounter('rune_cultist');

    expect(state.activeCombatSession?.encounterId, 'grave_rat');
    expect(state.activeCombatSession?.queuedEncounterId, 'rune_cultist');

    currentTime = currentTime.add(const Duration(seconds: 15));
    final result = service.advanceTo(currentTime);

    expect(result.completedVictories, 3);
    expect(result.victoriesByEncounter, {'grave_rat': 1, 'rune_cultist': 2});
    expect(result.goldEarned, 22);
    expect(result.experienceEarned, 19);
    expect(result.damageTaken, 5);
    expect(result.wasDefeated, isFalse);
    expect(state.currentHealth, 95);
    expect(state.activeCombatSession?.encounterId, 'rune_cultist');
    expect(state.activeCombatSession?.queuedEncounterId, isNull);
    expect(state.activeCombatSession?.timeRemainingMilliseconds, 6000);
  });

  test('selecting the active target again never restarts its cycle', () {
    service.selectEncounter('grave_rat');
    currentTime = currentTime.add(const Duration(seconds: 1));
    service.advanceTo(currentTime);
    final remaining = state.activeCombatSession!.timeRemainingMilliseconds;

    service.selectEncounter('grave_rat');

    expect(state.activeCombatSession?.timeRemainingMilliseconds, remaining);
    expect(state.gold, 0);
  });

  test('locked and unknown targets cannot start or replace combat', () {
    service.selectEncounter('rune_lord');
    service.selectEncounter('unknown');

    expect(state.activeCombatSession, isNull);
    expect(state.gold, 0);

    service.selectEncounter('grave_rat');
    service.selectEncounter('rune_lord');

    expect(state.activeCombatSession?.encounterId, 'grave_rat');
    expect(state.activeCombatSession?.queuedEncounterId, isNull);
  });

  test('combat and gathering are mutually exclusive activities', () {
    expect(state.startGathering('copper', at: currentTime), isTrue);

    service.selectEncounter('grave_rat');

    expect(state.activeGatheringSession, isNull);
    expect(state.activeCombatSession?.encounterId, 'grave_rat');

    expect(state.startGathering('copper', at: currentTime), isTrue);
    currentTime = currentTime.add(const Duration(seconds: 8));
    final result = service.advanceTo(currentTime);

    expect(state.activeCombatSession, isNull);
    expect(result.hasRewards, isFalse);
    expect(state.gold, 0);
  });

  test('clock moving backwards never generates rewards', () {
    service.selectEncounter('grave_rat');
    currentTime = currentTime.subtract(const Duration(minutes: 10));

    final result = service.advanceTo(currentTime);

    expect(result.hasRewards, isFalse);
    expect(state.gold, 0);
    expect(state.skills['attack']?.experience, 0);
  });

  test('stop settles elapsed combat and clears the session', () {
    service.selectEncounter('grave_rat');
    currentTime = currentTime.add(const Duration(seconds: 8));

    service.stop();

    expect(state.gold, 4);
    expect(state.currentHealth, 98);
    expect(state.skills['attack']?.experience, 6);
    expect(state.activeCombatSession, isNull);
    expect(saveRequests.last, isTrue);
  });

  test(
    'a fatal short batch reports defeat and never creates another cycle',
    () {
      state.currentHealth = 3;
      service.selectEncounter('grave_rat');
      currentTime = currentTime.add(const Duration(minutes: 10));

      final result = service.advanceTo(currentTime);

      expect(result.completedVictories, 3);
      expect(result.damageTaken, 3);
      expect(result.wasDefeated, isTrue);
      expect(result.sessionEnded, isTrue);
      expect(state.currentHealth, 0);
      expect(state.activeCombatSession, isNull);
    },
  );

  test(
    'auto-eat heals the hero mid-combat when HP drops below the threshold',
    () {
      state.currentHealth = 20;
      state.contentInventory.addConsumable('roasted_shrimp', 3);
      state.setAutoEatEnabled(true);
      state.setAutoEatThreshold(50);
      service.selectEncounter('grave_rat');

      currentTime = currentTime.add(const Duration(milliseconds: 4000));
      service.advanceTo(currentTime);

      // 20 HP - 1 damage = 19 (19% < 50% threshold) -> auto-eats a
      // roasted_shrimp (+8 HP) -> 27.
      expect(state.currentHealth, 27);
      expect(
        state.contentInventory.quantityOfConsumable('roasted_shrimp'),
        2,
      );
    },
  );

  test('auto-eat does nothing while disabled', () {
    state.currentHealth = 20;
    state.contentInventory.addConsumable('roasted_shrimp', 3);
    service.selectEncounter('grave_rat');

    currentTime = currentTime.add(const Duration(milliseconds: 4000));
    service.advanceTo(currentTime);

    expect(state.currentHealth, 19);
    expect(state.contentInventory.quantityOfConsumable('roasted_shrimp'), 3);
  });

  test('auto-eat does nothing once HP is already above the threshold', () {
    state.currentHealth = 90;
    state.contentInventory.addConsumable('roasted_shrimp', 3);
    state.setAutoEatEnabled(true);
    state.setAutoEatThreshold(50);
    service.selectEncounter('grave_rat');

    currentTime = currentTime.add(const Duration(milliseconds: 4000));
    service.advanceTo(currentTime);

    expect(state.currentHealth, 89);
    expect(state.contentInventory.quantityOfConsumable('roasted_shrimp'), 3);
  });

  test('auto-eat does nothing when no food is owned', () {
    state.currentHealth = 20;
    state.setAutoEatEnabled(true);
    state.setAutoEatThreshold(50);
    service.selectEncounter('grave_rat');

    currentTime = currentTime.add(const Duration(milliseconds: 4000));
    service.advanceTo(currentTime);

    expect(state.currentHealth, 19);
  });

  test('advance result aggregates damage even when no victory is returned', () {
    final result = CombatAdvanceResult();

    result.addReward(
      const CombatReward(
        encounterId: 'grave_rat',
        victories: 0,
        gold: 0,
        experience: 0,
        damageTaken: 2,
        wasDefeated: true,
      ),
    );

    expect(result.completedVictories, 0);
    expect(result.damageTaken, 2);
    expect(result.wasDefeated, isTrue);
    expect(result.hasRewards, isTrue);
  });
}
