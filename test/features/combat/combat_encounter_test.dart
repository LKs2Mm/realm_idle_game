import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/models/skill.dart';

void main() {
  test('catalog has six ordered dark runic encounters', () {
    expect(CombatEncounter.all, hasLength(6));
    expect(CombatEncounter.all.map((encounter) => encounter.id), [
      'grave_rat',
      'rune_cultist',
      'crypt_wolf',
      'hollow_knight',
      'abyss_wyrm',
      'rune_lord',
    ]);
    expect(
      CombatEncounter.all.map((encounter) => encounter.requiredAttackLevel),
      [1, 10, 20, 40, 60, 80],
    );
    expect(
      CombatEncounter.all.every((encounter) => encounter.sigil.isNotEmpty),
      isTrue,
    );
    expect(CombatEncounter.all.map((encounter) => encounter.damagePerVictory), [
      1,
      2,
      4,
      7,
      11,
      16,
    ]);
    expect(
      CombatEncounter.all.every((encounter) => encounter.damagePerMinute > 0),
      isTrue,
    );
  });

  test('gold and experience rates follow the intended balance', () {
    expect(CombatEncounter.all.map((encounter) => encounter.goldPerMinute), [
      30,
      100,
      300,
      800,
      2000,
      5000,
    ]);
    expect(
      CombatEncounter.all.map((encounter) => encounter.experiencePerMinute),
      [45, 80, 150, 250, 400, 600],
    );
  });

  test(
    'best available encounters take about 150 hours from level 1 to 100',
    () {
      var totalMinutes = 0.0;
      const milestones = [10, 20, 40, 60, 80, 100];
      var startLevel = 1;

      for (final targetLevel in milestones) {
        final encounter = CombatEncounter.all.lastWhere(
          (candidate) => candidate.requiredAttackLevel <= startLevel,
        );
        var experience = 0;
        for (var level = startLevel; level < targetLevel; level++) {
          experience += Skill.experienceRequiredForLevel(level);
        }
        totalMinutes += experience / encounter.experiencePerMinute;
        startLevel = targetLevel;
      }

      final totalHours = totalMinutes / 60;
      expect(totalHours, inInclusiveRange(148, 153));
    },
  );

  test('lookup returns only catalogued encounters', () {
    expect(CombatEncounter.byId('hollow_knight')?.name, 'Cavaleiro Oco');
    expect(CombatEncounter.byId('unknown'), isNull);
  });

  test('combat rewards carry authoritative damage and defeat state', () {
    const reward = CombatReward(
      encounterId: 'grave_rat',
      victories: 3,
      gold: 6,
      experience: 9,
      damageTaken: 3,
      wasDefeated: true,
    );

    expect(reward.damageTaken, 3);
    expect(reward.wasDefeated, isTrue);

    const backwardsCompatible = CombatReward(
      encounterId: 'grave_rat',
      victories: 1,
      gold: 2,
      experience: 3,
    );
    expect(backwardsCompatible.damageTaken, 0);
    expect(backwardsCompatible.wasDefeated, isFalse);
  });
}
