import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/content/data/potion_catalog.dart';
import 'package:realm_idle_game/features/content/data/spell_catalog.dart';
import 'package:realm_idle_game/features/content/models/alchemy.dart';
import 'package:realm_idle_game/features/equipment/data/equipment_catalog.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/features/production/services/production_service.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';

void main() {
  EquipmentDefinition starterEquipment({
    HeroClass heroClass = HeroClass.knight,
    EquipmentSlot slot = EquipmentSlot.weapon,
  }) {
    return EquipmentCatalog.definition(
      heroClass: heroClass,
      slot: slot,
      material: EquipmentMaterial.copper,
      rarity: EquipmentRarity.common,
    );
  }

  void addResources(GameState state, Map<String, int> resources) {
    for (final entry in resources.entries) {
      state.gatheringInventory.add(entry.key, entry.value);
    }
  }

  group('Produção temporizada de equipamentos', () {
    test('cobra ouro e minério, e só concede item e XP no fim', () {
      final startedAt = DateTime.utc(2026, 8, 1, 12);
      final definition = starterEquipment();
      final state = GameState()..addGold(definition.cost.gold + 17);
      addResources(state, {
        for (final entry in definition.cost.resources.entries)
          entry.key: entry.value + 3,
      });
      final updates = <bool>[];
      final service = ProductionService(
        onUpdate: (_, shouldSave) => updates.add(shouldSave),
        now: () => startedAt,
        enableTimer: false,
      );

      expect(
        state.craftEquipment(definition.id, at: startedAt),
        ProductionStartResult.success,
      );
      service.initialize(state);

      expect(state.gold, 17);
      for (final entry in definition.cost.resources.entries) {
        expect(state.gatheringInventory.quantityOf(entry.key), 3);
      }
      expect(state.equipment.inventory.itemQuantity(definition.id), 0);
      expect(state.skills[definition.workshop.skillId]!.experience, 0);
      expect(state.activeProductionSession?.kind, ProductionKind.equipment);
      expect(
        state.activeProductionSession?.durationMilliseconds,
        definition.craftDurationSeconds * 1000,
      );

      final almostFinished = service.advanceTo(
        startedAt.add(
          Duration(milliseconds: (definition.craftDurationSeconds * 1000) - 1),
        ),
      );

      expect(almostFinished.hasReward, isFalse);
      expect(state.activeProductionSession?.timeRemainingMilliseconds, 1);
      expect(state.equipment.inventory.itemQuantity(definition.id), 0);
      expect(state.skills[definition.workshop.skillId]!.experience, 0);

      final completed = service.advanceTo(
        startedAt.add(
          Duration(milliseconds: definition.craftDurationSeconds * 1000),
        ),
      );

      expect(completed.reward?.recipeId, definition.id);
      expect(completed.reward?.kind, ProductionKind.equipment);
      expect(completed.reward?.experience, definition.workshopExperience);
      expect(state.activeProductionSession, isNull);
      expect(state.equipment.inventory.itemQuantity(definition.id), 1);
      final expectedSkill =
          Skill(
              id: definition.workshop.skillId,
              name: definition.workshop.skillId,
              category: SkillCategory.processing,
            )
            ..addExperience(definition.workshopExperience);
      expect(
        state.skills[definition.workshop.skillId]!.level,
        expectedSkill.level,
      );
      expect(
        state.skills[definition.workshop.skillId]!.experience,
        expectedSkill.experience,
      );
      expect(state.profile.totalCrafts, 1);
      expect(updates, [false, true]);

      service.dispose();
    });

    test('cancelamento devolve integralmente ouro e materiais', () {
      final definition = starterEquipment(slot: EquipmentSlot.body);
      final state = GameState()..addGold(definition.cost.gold);
      addResources(state, definition.cost.resources);

      expect(
        state.craftEquipment(definition.id),
        ProductionStartResult.success,
      );
      expect(state.gold, 0);
      for (final resourceId in definition.cost.resources.keys) {
        expect(state.gatheringInventory.quantityOf(resourceId), 0);
      }

      state.cancelProduction();

      expect(state.gold, definition.cost.gold);
      for (final entry in definition.cost.resources.entries) {
        expect(state.gatheringInventory.quantityOf(entry.key), entry.value);
      }
      expect(state.activeProductionSession, isNull);
      expect(state.equipment.inventory.itemQuantity(definition.id), 0);
      expect(state.skills[definition.workshop.skillId]!.experience, 0);
    });
  });

  group('Classes livres e progressão independente', () {
    test('troca de classe não é permanente e separa XP e vitórias', () {
      final state = GameState();

      state.selectHeroClass(HeroClass.knight);
      state.completeCombatVictories('grave_rat', 34);
      state.selectHeroClass(HeroClass.assassin);
      state.completeCombatVictories('grave_rat', 1);

      expect(state.activeHeroClass, HeroClass.assassin);
      expect(state.classLevel(HeroClass.knight), 2);
      expect(state.classLevel(HeroClass.assassin), 1);
      expect(state.skills['knight_mastery']!.experience, 52);
      expect(state.skills['assassin_mastery']!.experience, 3);
      expect(state.skills['mage_mastery']!.experience, 0);
      expect(state.skills['archer_mastery']!.experience, 0);
      expect(state.victoriesForClass(HeroClass.knight), 34);
      expect(state.victoriesForClass(HeroClass.assassin), 1);
      expect(state.victoriesForClass(HeroClass.mage), 0);
      expect(state.victoriesForClass(HeroClass.archer), 0);
      expect(state.profile.totalVictories, 35);

      for (final heroClass in HeroClass.values) {
        state.selectHeroClass(heroClass);
        expect(state.activeHeroClass, heroClass);
      }
    });
  });

  group('Arcanismo e alquimia', () {
    test('magia exige essência rúnica, é produzida e fica equipável', () {
      final state = GameState();
      final spell = SpellCatalog.byId('runic_ember')!;
      final runeEssenceCost = spell.cost.materials['rune_essence']!;
      final nonRuneCosts = Map<String, int>.from(spell.cost.materials)
        ..remove('rune_essence');
      addResources(state, nonRuneCosts);

      expect(runeEssenceCost, greaterThan(0));
      expect(
        state.craftSpell(spell.id),
        ProductionStartResult.insufficientResources,
      );
      expect(state.activeProductionSession, isNull);

      state.gatheringInventory.add('rune_essence', runeEssenceCost);
      expect(state.craftSpell(spell.id), ProductionStartResult.success);
      expect(state.gatheringInventory.quantityOf('rune_essence'), 0);

      final reward = state.completeProduction();

      expect(reward?.kind, ProductionKind.spell);
      expect(reward?.skillId, 'arcanism');
      expect(state.contentInventory.quantityOfSpell(spell.id), 1);
      expect(state.skills['arcanism']!.experience, spell.craftingExperience);
      expect(state.equipSpell(spell.id), isTrue);
      expect(state.activeSpell?.id, spell.id);
    });

    test('poção é produzida, consumida e aplica o multiplicador', () {
      final brewedAt = DateTime.utc(2026, 8, 1, 12);
      final potion = PotionCatalog.byId('gravefury_draught')!;
      final state = GameState();
      addResources(state, {
        for (final entry in potion.cost.materials.entries)
          entry.key: entry.value * 2,
      });

      expect(
        state.brewPotion(potion.id, quantity: 2, at: brewedAt),
        ProductionStartResult.success,
      );
      expect(state.completeProduction(at: brewedAt)?.quantity, 2);
      expect(state.contentInventory.quantityOfConsumable(potion.id), 2);
      expect(
        state.skills['alchemy']!.experience,
        potion.craftingExperience * 2,
      );

      expect(state.consumePotion(potion.id, at: brewedAt), isTrue);

      expect(state.contentInventory.quantityOfConsumable(potion.id), 1);
      expect(state.profile.potionsConsumed, 1);
      expect(
        state.buffMultiplier(
          BuffType.attackPower,
          at: brewedAt.add(const Duration(seconds: 1)),
        ),
        closeTo(1 + potion.potency, 0.000001),
      );
      expect(
        state.buffMultiplier(
          BuffType.attackPower,
          at: brewedAt.add(Duration(seconds: potion.durationSeconds)),
        ),
        1,
      );
    });
  });

  group('Espólios determinísticos', () {
    test('lote e vitórias unitárias geram o mesmo inventário e restos', () {
      final foughtAt = DateTime.utc(2026, 8, 1, 12);
      final batched = GameState();
      final sequential = GameState();

      final batchReward = batched.completeCombatVictories(
        'grave_rat',
        10,
        at: foughtAt,
      );
      for (var victory = 0; victory < 10; victory++) {
        sequential.completeCombatVictories('grave_rat', 1, at: foughtAt);
      }

      expect(batchReward?.loot, {'grave_dust': 13, 'tarnished_fang': 2});
      expect(batched.gatheringInventory.quantityOf('grave_dust'), 13);
      expect(batched.gatheringInventory.quantityOf('tarnished_fang'), 2);
      expect(
        sequential.gatheringInventory.toJson(),
        batched.gatheringInventory.toJson(),
      );
      expect(
        sequential.combatDropRemainders.keys,
        unorderedEquals(batched.combatDropRemainders.keys),
      );
      for (final entry in batched.combatDropRemainders.entries) {
        expect(
          sequential.combatDropRemainders[entry.key],
          closeTo(entry.value, 0.000000001),
        );
      }
    });
  });

  group('Persistência integrada', () {
    test(
      'roundtrip preserva equipamentos, conteúdo, perfil, classes, região e produção',
      () {
        final state = GameState();
        final knightWeapon = starterEquipment();
        final pendingItem = starterEquipment(
          heroClass: HeroClass.archer,
          slot: EquipmentSlot.head,
        );
        final spell = SpellCatalog.byId('runic_ember')!;
        final potion = PotionCatalog.byId('gravefury_draught')!;
        final startedAt = DateTime.utc(2099, 8, 1, 12);

        state.equipment = state.equipment.grantDefinition(knightWeapon);
        expect(state.equipItem(knightWeapon.id), EquipmentActionResult.success);
        state.contentInventory.addSpell(spell.id);
        state.contentInventory.addConsumable(potion.id, 2);
        expect(state.equipSpell(spell.id), isTrue);
        expect(state.consumePotion(potion.id, at: startedAt), isTrue);
        state.updateProfile(
          name: 'Aldric das Cinzas',
          title: 'Guardião da Última Runa',
        );

        state.skills['attack']!.level = 10;
        state.skills['woodcutting']!.level = 10;
        expect(state.selectRegion('whispering_woods'), isTrue);
        state.selectHeroClass(HeroClass.assassin);
        state.completeCombatVictories('grave_rat', 3, at: startedAt);

        state.addGold(pendingItem.cost.gold + 50);
        addResources(state, pendingItem.cost.resources);
        expect(
          state.craftEquipment(pendingItem.id, at: startedAt),
          ProductionStartResult.success,
        );
        state.activeProductionSession!.timeRemainingMilliseconds = 1234;

        final restored = GameState.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(jsonEncode(state.toJson())) as Map,
          ),
        );

        expect(restored.equipment.inventory.itemQuantity(knightWeapon.id), 1);
        expect(
          restored.equipment.loadouts.equippedId(
            HeroClass.knight,
            EquipmentSlot.weapon,
          ),
          knightWeapon.id,
        );
        expect(restored.contentInventory.quantityOfSpell(spell.id), 1);
        expect(restored.contentInventory.quantityOfConsumable(potion.id), 1);
        expect(restored.activeSpellId, spell.id);
        expect(
          restored.buffMultiplier(
            BuffType.attackPower,
            at: startedAt.add(const Duration(seconds: 1)),
          ),
          closeTo(1 + potion.potency, 0.000001),
        );
        expect(restored.profile.name, 'Aldric das Cinzas');
        expect(restored.profile.title, 'Guardião da Última Runa');
        expect(restored.profile.totalVictories, 3);
        expect(restored.profile.potionsConsumed, 1);
        expect(restored.profile.selectedRegionId, 'whispering_woods');
        expect(restored.activeHeroClass, HeroClass.assassin);
        expect(restored.victoriesForClass(HeroClass.assassin), 3);
        expect(restored.skills['assassin_mastery']!.experience, 9);
        expect(restored.visitedRegionIds, contains('ashen_crossroads'));
        expect(restored.visitedRegionIds, contains('whispering_woods'));
        expect(
          restored.activeProductionSession?.kind,
          ProductionKind.equipment,
        );
        expect(restored.activeProductionSession?.recipeId, pendingItem.id);
        expect(
          restored.activeProductionSession?.timeRemainingMilliseconds,
          1234,
        );
        expect(
          restored.activeProductionSession?.resourceCost,
          pendingItem.cost.resources,
        );
        expect(
          restored.activeProductionSession?.goldCost,
          pendingItem.cost.gold,
        );
      },
    );
  });
}
