import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/features/content/data/combat_drop_catalog.dart';
import 'package:realm_idle_game/features/content/data/potion_catalog.dart';
import 'package:realm_idle_game/features/content/data/spell_catalog.dart';
import 'package:realm_idle_game/features/content/data/world_region_catalog.dart';
import 'package:realm_idle_game/features/content/models/alchemy.dart';
import 'package:realm_idle_game/features/content/models/spell.dart';
import 'package:realm_idle_game/features/content/models/world_region.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';

void main() {
  group('SpellCatalog', () {
    test('contains twelve unique spells and two from every school', () {
      expect(SpellCatalog.all, hasLength(12));
      expect(
        SpellCatalog.all.map((spell) => spell.id).toSet(),
        hasLength(SpellCatalog.all.length),
      );

      for (final school in SpellSchool.values) {
        expect(SpellCatalog.forSchool(school), hasLength(2));
      }
    });

    test('every spell consumes rune essence and only known materials', () {
      final knownMaterials = {
        ...GatheringResource.all.map((resource) => resource.id),
        ...CombatDropCatalog.all.map((drop) => drop.id),
      };

      for (final spell in SpellCatalog.all) {
        expect(spell.cost.quantityOf('rune_essence'), greaterThan(0));
        expect(spell.cost.materials.length, greaterThanOrEqualTo(2));
        expect(spell.cost.materials.keys, everyElement(isIn(knownMaterials)));
        expect(spell.cost.materials.values, everyElement(greaterThan(0)));
        expect(spell.effects, isNotEmpty);
        expect(
          spell.effects.map((effect) => effect.magnitude),
          everyElement(greaterThan(0)),
        );
      }
    });

    test('level, time, experience and essence costs rise with progression', () {
      for (var index = 1; index < SpellCatalog.all.length; index++) {
        final previous = SpellCatalog.all[index - 1];
        final current = SpellCatalog.all[index];
        expect(current.requiredLevel, greaterThan(previous.requiredLevel));
        expect(
          current.craftDurationMilliseconds,
          greaterThan(previous.craftDurationMilliseconds),
        );
        expect(
          current.craftingExperience,
          greaterThan(previous.craftingExperience),
        );
        expect(
          current.cost.quantityOf('rune_essence'),
          greaterThan(previous.cost.quantityOf('rune_essence')),
        );
      }
      expect(SpellCatalog.byId('gate_of_nothing'), isNotNull);
      expect(SpellCatalog.byId('unknown'), isNull);
    });
  });

  group('PotionCatalog', () {
    test('provides one real temporary buff for each supported type', () {
      expect(PotionCatalog.all, hasLength(8));
      expect(
        PotionCatalog.all.map((potion) => potion.id).toSet(),
        hasLength(PotionCatalog.all.length),
      );
      expect(
        PotionCatalog.all.map((potion) => potion.buffType).toSet(),
        equals(BuffType.values.toSet()),
      );

      for (final type in BuffType.values) {
        final potion = PotionCatalog.forBuff(type);
        expect(potion, isNotNull);
        expect(potion!.multiplier, greaterThan(1));
        expect(potion.durationSeconds, greaterThanOrEqualTo(300));
      }
    });

    test('every recipe joins gathering resources and combat drops', () {
      final gatheringIds = GatheringResource.all
          .map((resource) => resource.id)
          .toSet();
      final dropIds = CombatDropCatalog.all.map((drop) => drop.id).toSet();

      for (final potion in PotionCatalog.all) {
        expect(
          potion.cost.materials.keys.any(gatheringIds.contains),
          isTrue,
          reason: '${potion.id} needs a gathering ingredient',
        );
        expect(
          potion.cost.materials.keys.any(dropIds.contains),
          isTrue,
          reason: '${potion.id} needs a combat drop',
        );
        expect(potion.craftDurationMilliseconds, greaterThan(0));
        expect(potion.craftingExperience, greaterThan(0));
        expect(potion.potency, inInclusiveRange(0.05, 0.30));
      }
    });

    test('recipes unlock in an increasing alchemy progression', () {
      for (var index = 1; index < PotionCatalog.all.length; index++) {
        final previous = PotionCatalog.all[index - 1];
        final current = PotionCatalog.all[index];
        expect(current.requiredLevel, greaterThan(previous.requiredLevel));
        expect(
          current.craftDurationMilliseconds,
          greaterThan(previous.craftDurationMilliseconds),
        );
        expect(
          current.craftingExperience,
          greaterThan(previous.craftingExperience),
        );
      }
    });
  });

  group('CombatDropCatalog', () {
    test('contains the named crafting materials with valid drop rules', () {
      const requiredIds = {
        'grave_dust',
        'cultist_cloth',
        'crypt_leather',
        'hollow_steel',
        'abyssal_scale',
        'runic_core',
      };
      expect(CombatDropCatalog.all, hasLength(12));
      expect(
        CombatDropCatalog.all.map((drop) => drop.id).toSet(),
        hasLength(CombatDropCatalog.all.length),
      );
      expect(
        CombatDropCatalog.all.map((drop) => drop.id),
        containsAll(requiredIds),
      );

      final encounterIds = CombatEncounter.all
          .map((encounter) => encounter.id)
          .toSet();
      for (final drop in CombatDropCatalog.all) {
        expect(drop.dropChance, greaterThan(0));
        expect(drop.dropChance, lessThanOrEqualTo(1));
        expect(drop.minimumQuantity, greaterThan(0));
        expect(
          drop.maximumQuantity,
          greaterThanOrEqualTo(drop.minimumQuantity),
        );
        expect(drop.sourceEncounterIds, isNotEmpty);
        expect(drop.sourceEncounterIds, everyElement(isIn(encounterIds)));
      }
      for (final encounterId in encounterIds) {
        expect(CombatDropCatalog.forEncounter(encounterId), isNotEmpty);
      }
    });
  });

  group('WorldRegionCatalog', () {
    test('contains eight ordered regions with complete visual metadata', () {
      expect(WorldRegionCatalog.all, hasLength(8));
      expect(
        WorldRegionCatalog.all.map((region) => region.id).toSet(),
        hasLength(WorldRegionCatalog.all.length),
      );

      final encounterIds = CombatEncounter.all
          .map((encounter) => encounter.id)
          .toSet();
      for (var index = 0; index < WorldRegionCatalog.all.length; index++) {
        final region = WorldRegionCatalog.all[index];
        expect(region.lore.length, greaterThan(80));
        expect(region.sigil, isNotEmpty);
        expect(region.primaryColorValue >> 24, 0xFF);
        expect(region.accentColorValue >> 24, 0xFF);
        expect(region.enemyIds, isNotEmpty);
        expect(region.enemyIds, everyElement(isIn(encounterIds)));
        expect(region.workshops, isNotEmpty);

        if (index == 0) {
          expect(region.requirement.prerequisiteRegionId, isNull);
        } else {
          final previous = WorldRegionCatalog.all[index - 1];
          expect(
            region.requirement.requiredCombatLevel,
            greaterThan(previous.requirement.requiredCombatLevel),
          );
          expect(region.requirement.prerequisiteRegionId, previous.id);
        }
      }
    });

    test('all five professions receive a workshop in the world', () {
      final workshops = WorldRegionCatalog.all
          .expand((region) => region.workshops)
          .toSet();
      expect(workshops, equals(WorkshopType.values.toSet()));
      expect(WorkshopType.shadowAtelier.displayName, 'Ateliê do Véu');
    });

    test('unlock checks combat, skills and previous region completion', () {
      final first = WorldRegionCatalog.byId('ashen_crossroads')!;
      final woods = WorldRegionCatalog.byId('whispering_woods')!;
      expect(first.requirement.isMet(combatLevel: 1), isTrue);
      expect(
        woods.requirement.isMet(
          combatLevel: 10,
          skillLevels: {'woodcutting': 10},
        ),
        isFalse,
      );
      expect(
        woods.requirement.isMet(
          combatLevel: 10,
          skillLevels: {'woodcutting': 10},
          completedRegionIds: {'ashen_crossroads'},
        ),
        isTrue,
      );

      final unlocked = WorldRegionCatalog.unlockedBy(
        combatLevel: 10,
        skillLevels: {'woodcutting': 10},
        completedRegionIds: {'ashen_crossroads'},
      );
      expect(unlocked.map((region) => region.id), [
        'ashen_crossroads',
        'whispering_woods',
      ]);
    });
  });
}
