import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/features/processing/data/cooking_recipe_catalog.dart';
import 'package:realm_idle_game/models/game_state.dart';

void main() {
  group('GameState combat health integration', () {
    test(
      'defense mitigates incoming damage and reward uses the same value',
      () {
        final encounter = CombatEncounter.byId('rune_lord')!;
        final unarmored = GameState();
        final defended = GameState();
        unarmored.skills['attack']!.level = encounter.requiredAttackLevel;
        defended.skills['attack']!.level = encounter.requiredAttackLevel;
        defended.skills['defense']!.level = 100;

        final baseDamage = unarmored.effectiveDamageFor(encounter);
        final mitigatedDamage = defended.effectiveDamageFor(encounter);

        expect(baseDamage, encounter.damagePerVictory);
        expect(mitigatedDamage, greaterThan(0));
        expect(mitigatedDamage, lessThan(baseDamage));

        final healthBefore = defended.currentHealth;
        final reward = defended.completeCombatVictories(encounter.id, 1);

        expect(reward?.victories, 1);
        expect(reward?.damageTaken, mitigatedDamage);
        expect(defended.currentHealth, healthBefore - mitigatedDamage);
        expect(reward?.wasDefeated, isFalse);
      },
    );

    test(
      'requested batch is limited to victories survivable by current HP',
      () {
        final state = GameState()..currentHealth = 5;

        final reward = state.completeCombatVictories('grave_rat', 100);

        expect(reward, isNotNull);
        expect(reward!.victories, 5);
        expect(reward.damageTaken, 5);
        expect(reward.gold, 10);
        expect(reward.experience, 15);
        expect(reward.wasDefeated, isTrue);
        expect(state.currentHealth, 0);
        expect(state.victoriesForClass(state.activeHeroClass), 5);
      },
    );

    test('defeat clears an active combat session', () {
      final state = GameState()..currentHealth = 2;

      expect(state.startCombat('grave_rat'), isTrue);
      expect(state.activeCombatSession, isNotNull);

      final reward = state.completeCombatVictories('grave_rat', 10);

      expect(reward?.victories, 2);
      expect(reward?.wasDefeated, isTrue);
      expect(state.isDefeated, isTrue);
      expect(state.activeCombatSession, isNull);
    });

    test('zero HP blocks a new combat session', () {
      final state = GameState()..currentHealth = 0;

      expect(state.isDefeated, isTrue);
      expect(state.startCombat('grave_rat'), isFalse);
      expect(state.activeCombatSession, isNull);
      expect(state.completeCombatVictories('grave_rat', 1), isNull);
    });

    test('cooked fish revives the hero and allows combat again', () {
      final food = CookingRecipeCatalog.byFoodId('roasted_shrimp')!;
      final state = GameState()..currentHealth = 0;
      state.contentInventory.addConsumable(food.foodId);

      expect(state.startCombat('grave_rat'), isFalse);
      expect(state.consumeCookedFish(food.foodId), FoodUseResult.success);
      expect(state.currentHealth, food.healAmount);
      expect(state.isDefeated, isFalse);
      expect(state.contentInventory.quantityOfConsumable(food.foodId), 0);
      expect(state.startCombat('grave_rat'), isTrue);
    });

    test('round-trip preserves current health', () {
      final state = GameState()..currentHealth = 37;

      final restored = GameState.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(state.toJson())) as Map,
        ),
      );

      expect(restored.currentHealth, 37);
      expect(restored.maxHealth, state.maxHealth);
      expect(restored.isDefeated, isFalse);
    });

    test('legacy save without health starts at its derived maximum', () {
      final state = GameState();
      state.skills['knight_mastery']!.level = 10;
      final legacyJson = Map<String, dynamic>.from(state.toJson())
        ..['schemaVersion'] = 6
        ..remove('currentHealth');

      final restored = GameState.fromJson(legacyJson);

      expect(restored.maxHealth, 118);
      expect(restored.currentHealth, restored.maxHealth);
      expect(restored.isDefeated, isFalse);
    });
  });
}
