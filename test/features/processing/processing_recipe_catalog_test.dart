import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/processing/data/arcane_refining_catalog.dart';
import 'package:realm_idle_game/features/processing/data/cooking_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/processing_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/shaft_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/skewer_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/smelting_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';

void main() {
  group('ProcessingCost', () {
    test('is immutable and supports batches, affordability, and deficits', () {
      final source = <String, int>{'iron': 2, 'coal': 1, 'ignored': 0};
      final cost = ProcessingCost(source);
      source['iron'] = 99;

      expect(cost.materials, {'iron': 2, 'coal': 1});
      expect(() => cost.materials['iron'] = 3, throwsUnsupportedError);
      expect(cost.multipliedBy(3), {'iron': 6, 'coal': 3});
      expect(() => cost.multipliedBy(3)['iron'] = 7, throwsUnsupportedError);
      expect(cost.canAfford({'iron': 6, 'coal': 3}, batches: 3), isTrue);
      expect(cost.canAfford({'iron': 5, 'coal': 3}, batches: 3), isFalse);
      expect(cost.missingFrom({'iron': 3}, batches: 2), {'iron': 1, 'coal': 2});
      expect(cost.canAfford(const {}, batches: 0), isFalse);
    });
  });

  group('SmeltingRecipeCatalog', () {
    test('maps nine common minerals to stable bar outputs', () {
      expect(EquipmentMaterial.values, hasLength(10));
      expect(SmeltingRecipeCatalog.all, hasLength(9));
      expect(
        SmeltingRecipeCatalog.all.map((recipe) => recipe.id).toSet(),
        hasLength(9),
      );
      expect(
        () => SmeltingRecipeCatalog.all.add(SmeltingRecipeCatalog.all.first),
        throwsUnsupportedError,
      );
      expect(
        SmeltingRecipeCatalog.all.map((recipe) => recipe.material),
        isNot(contains(EquipmentMaterial.arcaneCrystal)),
      );

      for (var index = 0; index < SmeltingRecipeCatalog.all.length; index++) {
        final recipe = SmeltingRecipeCatalog.all[index];
        final material = recipe.material;

        expect(recipe.tier, index + 1);
        expect(material, EquipmentMaterial.values[index]);
        expect(recipe.oreId, material.resourceId);
        expect(recipe.ore, same(GatheringResource.byId(material.resourceId)));
        expect(recipe.ore.discipline, GatheringDiscipline.mining);
        expect(recipe.cost.quantityOf(material.resourceId), 1);
        expect(
          recipe.cost.quantityOf(ProcessingResourceIds.coal),
          greaterThan(0),
        );
        expect(recipe.cost.materials, hasLength(2));
        expect(recipe.barId, '${material.resourceId}_bar');
        expect(recipe.output.quantity, 1);
        expect(recipe.skillId, 'smithing');
        expect(recipe.kind, ProcessingKind.smelting);
        expect(recipe.durationMilliseconds, greaterThan(0));
        expect(recipe.experience, greaterThan(0));
        expect(recipe.requiredLevel, greaterThan(0));
        expect(SmeltingRecipeCatalog.byId(recipe.id), same(recipe));
        expect(SmeltingRecipeCatalog.forMaterial(material), same(recipe));
        expect(SmeltingRecipeCatalog.forOre(recipe.oreId), same(recipe));
      }
      expect(SmeltingRecipeCatalog.byId('smelt_missing'), isNull);
      expect(SmeltingRecipeCatalog.forOre('missing_ore'), isNull);
      expect(
        SmeltingRecipeCatalog.forMaterial(EquipmentMaterial.arcaneCrystal),
        isNull,
      );
    });

    test('increases level, time, experience, and coal across tiers', () {
      SmeltingRecipe? previous;
      for (final recipe in SmeltingRecipeCatalog.all) {
        if (previous != null) {
          expect(recipe.requiredLevel, greaterThan(previous.requiredLevel));
          expect(
            recipe.durationMilliseconds,
            greaterThan(previous.durationMilliseconds),
          );
          expect(recipe.experience, greaterThan(previous.experience));
          expect(
            recipe.cost.quantityOf(ProcessingResourceIds.coal),
            greaterThanOrEqualTo(
              previous.cost.quantityOf(ProcessingResourceIds.coal),
            ),
          );
        }
        previous = recipe;
      }
      expect(SmeltingRecipeCatalog.unlockedAt(1), hasLength(1));
      expect(SmeltingRecipeCatalog.unlockedAt(90), hasLength(9));
    });
  });

  group('ArcaneRefiningCatalog', () {
    test('consecrates the arcane crystal into a stable ingot', () {
      const material = EquipmentMaterial.arcaneCrystal;
      expect(ArcaneRefiningCatalog.all, hasLength(1));
      expect(
        () => ArcaneRefiningCatalog.all.add(ArcaneRefiningCatalog.all.first),
        throwsUnsupportedError,
      );

      final recipe = ArcaneRefiningCatalog.all.single;
      expect(recipe.material, material);
      expect(recipe.oreId, 'arcane_crystal');
      expect(recipe.ore, same(GatheringResource.byId('arcane_crystal')));
      expect(recipe.ore.discipline, GatheringDiscipline.mining);
      expect(recipe.cost.quantityOf('arcane_crystal'), 1);
      expect(recipe.cost.quantityOf('rune_essence'), greaterThan(0));
      expect(recipe.cost.quantityOf(ProcessingResourceIds.coal), 0);
      expect(recipe.ingotId, 'arcane_ingot');
      expect(recipe.output.resourceId, 'arcane_ingot');
      expect(recipe.output.quantity, 1);
      expect(recipe.skillId, 'arcanism');
      expect(recipe.kind, ProcessingKind.arcaneRefining);
      expect(recipe.durationMilliseconds, greaterThan(0));
      expect(recipe.experience, greaterThan(0));
      expect(recipe.requiredLevel, greaterThan(0));

      expect(ArcaneRefiningCatalog.byId(recipe.id), same(recipe));
      expect(ArcaneRefiningCatalog.byId('missing'), isNull);
      expect(ArcaneRefiningCatalog.forMaterial(material), same(recipe));
      expect(
        ArcaneRefiningCatalog.forMaterial(EquipmentMaterial.copper),
        isNull,
      );
      expect(ArcaneRefiningCatalog.forOre('arcane_crystal'), same(recipe));
      expect(ArcaneRefiningCatalog.forOre('missing_ore'), isNull);
      expect(
        ArcaneRefiningCatalog.unlockedAt(recipe.requiredLevel - 1),
        isEmpty,
      );
      expect(
        ArcaneRefiningCatalog.unlockedAt(recipe.requiredLevel),
        hasLength(1),
      );
    });
  });

  group('ShaftRecipeCatalog', () {
    test('carves every woodcutting tier into a matching batch of shafts', () {
      final woods = GatheringResource.forDiscipline(
        GatheringDiscipline.woodcutting,
      );
      expect(ShaftRecipeCatalog.all, hasLength(woods.length));
      expect(
        ShaftRecipeCatalog.all.map((recipe) => recipe.id).toSet(),
        hasLength(woods.length),
      );
      expect(
        () => ShaftRecipeCatalog.all.add(ShaftRecipeCatalog.all.first),
        throwsUnsupportedError,
      );

      ShaftRecipe? previous;
      for (var index = 0; index < ShaftRecipeCatalog.all.length; index++) {
        final recipe = ShaftRecipeCatalog.all[index];
        final wood = woods[index];

        expect(recipe.tier, index + 1);
        expect(recipe.wood, same(wood));
        expect(recipe.woodId, wood.id);
        expect(recipe.cost.materials, {wood.id: 2});
        expect(recipe.shaftId, '${wood.id}_shaft');
        expect(recipe.output.quantity, 3);
        expect(recipe.skillId, 'crafting');
        expect(recipe.kind, ProcessingKind.woodworking);
        expect(recipe.durationMilliseconds, greaterThan(0));
        expect(recipe.experience, greaterThan(0));
        expect(recipe.requiredLevel, greaterThan(0));
        expect(ShaftRecipeCatalog.byId(recipe.id), same(recipe));
        expect(ShaftRecipeCatalog.forWood(wood.id), same(recipe));

        if (previous != null) {
          expect(recipe.requiredLevel, greaterThan(previous.requiredLevel));
          expect(
            recipe.durationMilliseconds,
            greaterThan(previous.durationMilliseconds),
          );
          expect(recipe.experience, greaterThan(previous.experience));
        }
        previous = recipe;
      }
      expect(ShaftRecipeCatalog.byId('missing'), isNull);
      expect(ShaftRecipeCatalog.forWood('missing_wood'), isNull);
      expect(ShaftRecipeCatalog.unlockedAt(1), hasLength(1));
      expect(ShaftRecipeCatalog.unlockedAt(70), hasLength(woods.length));

      expect(ShaftRecipeCatalog.shaftNameFor('normal_log'), 'Haste Comum');
      expect(ShaftRecipeCatalog.shaftNameFor('magic_log'), 'Haste Mágica');
      expect(
        ShaftRecipeCatalog.shaftNameFor('missing_wood'),
        'Haste desconhecida',
      );
    });
  });

  group('CookingRecipeCatalog', () {
    test('contains ten ordered tiers backed by real fishing resources', () {
      expect(CookingRecipeCatalog.all, hasLength(10));
      expect(
        CookingRecipeCatalog.all.map((recipe) => recipe.id).toSet(),
        hasLength(10),
      );
      expect(
        CookingRecipeCatalog.all.map((recipe) => recipe.foodId).toSet(),
        hasLength(10),
      );
      expect(
        () => CookingRecipeCatalog.all.add(CookingRecipeCatalog.all.first),
        throwsUnsupportedError,
      );

      CookingRecipe? previous;
      for (var index = 0; index < CookingRecipeCatalog.all.length; index++) {
        final recipe = CookingRecipeCatalog.all[index];
        expect(recipe.tier, index + 1);
        expect(recipe.rawFish, same(GatheringResource.byId(recipe.rawFishId)));
        expect(recipe.rawFish.discipline, GatheringDiscipline.fishing);
        expect(recipe.cost.quantityOf(recipe.rawFishId), greaterThan(0));
        expect(
          recipe.cost.quantityOf(ProcessingResourceIds.coal),
          greaterThan(0),
        );
        expect(recipe.cost.quantityOf(ProcessingResourceIds.woodenSkewer), 1);
        expect(recipe.cost.materials, hasLength(3));
        expect(recipe.output.quantity, 1);
        expect(recipe.skillId, 'cooking');
        expect(recipe.kind, ProcessingKind.cooking);
        expect(recipe.healAmount, greaterThan(0));
        expect(CookingRecipeCatalog.byId(recipe.id), same(recipe));
        expect(CookingRecipeCatalog.byFoodId(recipe.foodId), same(recipe));

        if (previous != null) {
          expect(recipe.healAmount, greaterThan(previous.healAmount));
          expect(recipe.requiredLevel, greaterThan(previous.requiredLevel));
          expect(
            recipe.durationMilliseconds,
            greaterThan(previous.durationMilliseconds),
          );
          expect(recipe.experience, greaterThan(previous.experience));
        }
        previous = recipe;
      }
      expect(CookingRecipeCatalog.byId('cook_missing'), isNull);
      expect(CookingRecipeCatalog.byFoodId('missing_food'), isNull);
    });

    test('uses each of the ten real fish exactly once', () {
      expect(CookingRecipeCatalog.forRawFish('shrimp'), hasLength(1));
      expect(CookingRecipeCatalog.forRawFish('swordfish'), hasLength(1));
      expect(CookingRecipeCatalog.forRawFish('shark'), hasLength(1));
      expect(CookingRecipeCatalog.forRawFish('abyssal_eel'), hasLength(1));
      expect(CookingRecipeCatalog.forRawFish('runic_leviathan'), hasLength(1));
      expect(CookingRecipeCatalog.forRawFish('missing_fish'), isEmpty);
      expect(CookingRecipeCatalog.all[8].cost.quantityOf('abyssal_eel'), 1);
      expect(CookingRecipeCatalog.all[9].cost.quantityOf('runic_leviathan'), 1);
      expect(
        CookingRecipeCatalog.all.map((recipe) => recipe.rawFishId).toSet(),
        GatheringResource.forDiscipline(
          GatheringDiscipline.fishing,
        ).map((resource) => resource.id).toSet(),
      );
      expect(CookingRecipeCatalog.unlockedAt(1), hasLength(1));
      expect(CookingRecipeCatalog.unlockedAt(80), hasLength(9));
      expect(CookingRecipeCatalog.unlockedAt(90), hasLength(10));
    });
  });

  group('SkewerRecipeCatalog', () {
    test('turns one common log into five reusable cooking inputs', () {
      final recipe = SkewerRecipeCatalog.recipe;
      expect(SkewerRecipeCatalog.all, [same(recipe)]);
      expect(SkewerRecipeCatalog.byId(recipe.id), same(recipe));
      expect(SkewerRecipeCatalog.byId('missing'), isNull);
      expect(recipe.id, 'carve_wooden_skewers');
      expect(recipe.woodId, 'normal_log');
      expect(recipe.wood, same(GatheringResource.byId('normal_log')));
      expect(recipe.cost.materials, {'normal_log': 1});
      expect(recipe.skewerId, ProcessingResourceIds.woodenSkewer);
      expect(recipe.output.quantity, 5);
      expect(recipe.skillId, 'crafting');
      expect(recipe.kind, ProcessingKind.woodworking);
      expect(recipe.requiredLevel, 1);
      expect(recipe.durationMilliseconds, greaterThan(0));
      expect(recipe.experience, greaterThan(0));
    });
  });

  group('ProcessingRecipeCatalog facade', () {
    test('offers unified UI and GameState lookup APIs', () {
      expect(ProcessingRecipeCatalog.all, hasLength(29));
      expect(
        ProcessingRecipeCatalog.all.map((recipe) => recipe.id).toSet(),
        hasLength(29),
      );
      expect(
        () =>
            ProcessingRecipeCatalog.all.add(ProcessingRecipeCatalog.all.first),
        throwsUnsupportedError,
      );
      expect(
        ProcessingRecipeCatalog.forKind(ProcessingKind.smelting),
        hasLength(9),
      );
      expect(
        ProcessingRecipeCatalog.forKind(ProcessingKind.arcaneRefining),
        hasLength(1),
      );
      expect(
        ProcessingRecipeCatalog.forKind(ProcessingKind.cooking),
        hasLength(10),
      );
      expect(
        ProcessingRecipeCatalog.forKind(ProcessingKind.woodworking),
        hasLength(9),
      );
      expect(ProcessingRecipeCatalog.forSkill('smithing'), hasLength(9));
      expect(ProcessingRecipeCatalog.forSkill('arcanism'), hasLength(1));
      expect(ProcessingRecipeCatalog.forSkill('cooking'), hasLength(10));
      expect(ProcessingRecipeCatalog.forSkill('crafting'), hasLength(9));
      expect(
        ProcessingRecipeCatalog.consuming(ProcessingResourceIds.coal),
        hasLength(19),
      );
      expect(
        ProcessingRecipeCatalog.consuming(ProcessingResourceIds.woodenSkewer),
        hasLength(10),
      );
      expect(
        ProcessingRecipeCatalog.producing(ProcessingResourceIds.woodenSkewer),
        [same(SkewerRecipeCatalog.recipe)],
      );
      expect(
        ProcessingRecipeCatalog.byId(SmeltingRecipeCatalog.all.first.id),
        same(SmeltingRecipeCatalog.all.first),
      );
      expect(ProcessingRecipeCatalog.byId('missing'), isNull);
      expect(
        ProcessingRecipeCatalog.unlockedFor(skillId: 'smithing', skillLevel: 1),
        hasLength(1),
      );
    });

    test('recipe helpers are ready for queued batch processing', () {
      final recipe = SmeltingRecipeCatalog.all.first;
      final inventory = {recipe.oreId: 3, ProcessingResourceIds.coal: 3};
      expect(
        recipe.canStart(skillLevel: 1, inventory: inventory, batches: 3),
        isTrue,
      );
      expect(
        recipe.canStart(skillLevel: 0, inventory: inventory, batches: 1),
        isFalse,
      );
      expect(recipe.output.forBatches(3), 3);
      expect(
        recipe.duration,
        Duration(milliseconds: recipe.durationMilliseconds),
      );
      expect(recipe.durationSeconds, greaterThan(0));
    });
  });
}
