import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/processing/data/cooking_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/skewer_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/smelting_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';

void main() {
  void addResources(GameState state, Map<String, int> resources) {
    for (final entry in resources.entries) {
      state.gatheringInventory.add(entry.key, entry.value);
    }
  }

  Map<String, int> scaledCost(ProcessingRecipe recipe, int quantity) {
    return Map<String, int>.from(recipe.cost.multipliedBy(quantity));
  }

  group('GameState processing integration', () {
    test('smelts a batch, charging scaled costs and XP only on completion', () {
      final startedAt = DateTime.utc(2026, 8, 1, 12);
      final recipe = SmeltingRecipeCatalog.forOre('copper')!;
      const quantity = 3;
      final cost = scaledCost(recipe, quantity);
      final state = GameState();
      addResources(state, {
        for (final entry in cost.entries) entry.key: entry.value + 2,
      });

      expect(
        state.startProcessing(recipe.id, quantity: quantity, at: startedAt),
        ProductionStartResult.success,
      );

      expect(state.activeProductionSession?.kind, ProductionKind.smelting);
      expect(state.activeProductionSession?.quantity, quantity);
      expect(state.activeProductionSession?.resourceCost, cost);
      expect(
        state.activeProductionSession?.durationMilliseconds,
        recipe.durationMilliseconds * quantity,
      );
      for (final resourceId in cost.keys) {
        expect(state.gatheringInventory.quantityOf(resourceId), 2);
      }
      expect(state.gatheringInventory.quantityOf(recipe.barId), 0);
      expect(state.skills['smithing']!.experience, 0);

      final reward = state.completeProduction(at: startedAt);

      expect(reward?.kind, ProductionKind.smelting);
      expect(reward?.recipeId, recipe.id);
      expect(reward?.quantity, quantity);
      expect(reward?.skillId, 'smithing');
      expect(
        reward?.experience,
        Skill.normalizeExperience(recipe.experience * quantity),
      );
      expect(
        state.gatheringInventory.quantityOf(recipe.barId),
        recipe.output.quantity * quantity,
      );
      expect(
        state.skills['smithing']!.experience,
        Skill.normalizeExperience(recipe.experience * quantity),
      );
      expect(state.profile.totalCrafts, quantity);
      expect(state.activeProductionSession, isNull);
    });

    test('cooks fish in a batch into consumables with cooking XP', () {
      final recipe = CookingRecipeCatalog.byId('cook_roasted_shrimp')!;
      const quantity = 4;
      final cost = scaledCost(recipe, quantity);
      final state = GameState();
      addResources(state, cost);

      expect(
        state.startProcessing(recipe.id, quantity: quantity),
        ProductionStartResult.success,
      );
      expect(state.activeProductionSession?.kind, ProductionKind.cooking);
      expect(state.contentInventory.quantityOfConsumable(recipe.foodId), 0);
      expect(state.skills['cooking']!.experience, 0);
      for (final resourceId in cost.keys) {
        expect(state.gatheringInventory.quantityOf(resourceId), 0);
      }

      final reward = state.completeProduction();

      expect(reward?.kind, ProductionKind.cooking);
      expect(reward?.quantity, quantity);
      expect(reward?.skillId, 'cooking');
      expect(
        state.contentInventory.quantityOfConsumable(recipe.foodId),
        recipe.output.quantity * quantity,
      );
      expect(
        state.skills['cooking']!.experience,
        Skill.normalizeExperience(recipe.experience * quantity),
      );
      expect(state.gatheringInventory.quantityOf(recipe.foodId), 0);
    });

    test('carves reusable skewers in batches through woodworking', () {
      final recipe = SkewerRecipeCatalog.recipe;
      const quantity = 2;
      final state = GameState();
      addResources(state, scaledCost(recipe, quantity));

      expect(
        state.startProcessing(recipe.id, quantity: quantity),
        ProductionStartResult.success,
      );
      expect(state.activeProductionSession?.kind, ProductionKind.woodworking);
      expect(state.gatheringInventory.quantityOf(recipe.woodId), 0);

      final reward = state.completeProduction();

      expect(reward?.kind, ProductionKind.woodworking);
      expect(reward?.skillId, 'crafting');
      expect(
        state.gatheringInventory.quantityOf(recipe.skewerId),
        recipe.output.quantity * quantity,
      );
      expect(
        state.skills['crafting']!.experience,
        Skill.normalizeExperience(recipe.experience * quantity),
      );
    });

    test('shares one production slot and cancellation refunds exact costs', () {
      final smelting = SmeltingRecipeCatalog.forOre('copper')!;
      final cooking = CookingRecipeCatalog.byId('cook_roasted_shrimp')!;
      const smeltingQuantity = 2;
      final smeltingCost = scaledCost(smelting, smeltingQuantity);
      final cookingCost = scaledCost(cooking, 1);
      final initialResources = <String, int>{};
      for (final entry in [...smeltingCost.entries, ...cookingCost.entries]) {
        initialResources.update(
          entry.key,
          (current) => current + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      final state = GameState();
      addResources(state, initialResources);

      expect(
        state.startProcessing(smelting.id, quantity: smeltingQuantity),
        ProductionStartResult.success,
      );
      final inventoryBeforeBusyAttempt = Map<String, int>.from(
        state.gatheringInventory.resources,
      );

      expect(
        state.startProcessing(cooking.id),
        ProductionStartResult.productionBusy,
      );
      expect(state.gatheringInventory.resources, inventoryBeforeBusyAttempt);

      state.cancelProduction();

      expect(state.activeProductionSession, isNull);
      for (final entry in initialResources.entries) {
        expect(
          state.gatheringInventory.quantityOf(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      expect(state.gatheringInventory.quantityOf(smelting.barId), 0);
      expect(state.skills['smithing']!.experience, 0);
      expect(state.profile.totalCrafts, 0);
    });

    test('rejects invalid, locked, and unaffordable processing atomically', () {
      final copper = SmeltingRecipeCatalog.forOre('copper')!;
      final iron = SmeltingRecipeCatalog.forOre('iron')!;
      final state = GameState();
      state.gatheringInventory.add(copper.oreId, 1);

      expect(
        state.startProcessing(copper.id, quantity: 0),
        ProductionStartResult.invalidQuantity,
      );
      expect(
        state.startProcessing(copper.id, quantity: 11),
        ProductionStartResult.invalidQuantity,
      );
      expect(
        state.startProcessing(iron.id),
        ProductionStartResult.levelRequired,
      );
      expect(
        state.startProcessing(copper.id),
        ProductionStartResult.insufficientResources,
      );
      expect(state.gatheringInventory.quantityOf(copper.oreId), 1);
      expect(state.activeProductionSession, isNull);
    });

    test(
      'round-trips a pending processing session without granting output',
      () {
        final startedAt = DateTime.utc(2099, 8, 1, 12);
        final recipe = SkewerRecipeCatalog.recipe;
        const quantity = 3;
        final cost = scaledCost(recipe, quantity);
        final state = GameState();
        addResources(state, cost);

        expect(
          state.startProcessing(recipe.id, quantity: quantity, at: startedAt),
          ProductionStartResult.success,
        );
        state.activeProductionSession!.timeRemainingMilliseconds = 4321;

        final restored = GameState.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(jsonEncode(state.toJson())) as Map,
          ),
        );

        expect(
          restored.activeProductionSession?.kind,
          ProductionKind.woodworking,
        );
        expect(restored.activeProductionSession?.recipeId, recipe.id);
        expect(restored.activeProductionSession?.quantity, quantity);
        expect(
          restored.activeProductionSession?.timeRemainingMilliseconds,
          4321,
        );
        expect(restored.activeProductionSession?.resourceCost, cost);
        expect(restored.activeProductionSession?.skillId, 'crafting');
        expect(
          restored.activeProductionSession?.experience,
          recipe.experience * quantity,
        );
        expect(restored.gatheringInventory.quantityOf(recipe.woodId), 0);
        expect(restored.gatheringInventory.quantityOf(recipe.skewerId), 0);
        expect(restored.skills['crafting']!.experience, 0);
      },
    );

    test(
      'cooked fish heals, clamps, preserves food at full HP, and checks ownership',
      () {
        final recipe = CookingRecipeCatalog.byFoodId('roasted_shrimp')!;

        final wounded = GameState()..currentHealth = 50;
        expect(
          wounded.consumeCookedFish(recipe.foodId),
          FoodUseResult.notOwned,
        );
        wounded.contentInventory.addConsumable(recipe.foodId);
        expect(wounded.consumeCookedFish(recipe.foodId), FoodUseResult.success);
        expect(wounded.currentHealth, 50 + recipe.healAmount);
        expect(wounded.contentInventory.quantityOfConsumable(recipe.foodId), 0);

        final nearlyFull = GameState()
          ..currentHealth = 98
          ..contentInventory.addConsumable(recipe.foodId, 2);
        expect(
          nearlyFull.consumeCookedFish(recipe.foodId),
          FoodUseResult.success,
        );
        expect(nearlyFull.currentHealth, nearlyFull.maxHealth);
        expect(
          nearlyFull.contentInventory.quantityOfConsumable(recipe.foodId),
          1,
        );
        expect(
          nearlyFull.consumeCookedFish(recipe.foodId),
          FoodUseResult.fullHealth,
        );
        expect(
          nearlyFull.contentInventory.quantityOfConsumable(recipe.foodId),
          1,
        );
        expect(
          nearlyFull.consumeCookedFish('unknown_food'),
          FoodUseResult.unknownFood,
        );
      },
    );
  });
}
