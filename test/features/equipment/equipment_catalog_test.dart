import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/equipment/data/equipment_catalog.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';

void main() {
  group('EquipmentCatalog cardinality and identity', () {
    test('contains every class, slot, material, and rarity combination', () {
      expect(HeroClass.values, hasLength(4));
      expect(EquipmentSlot.values, hasLength(6));
      expect(EquipmentMaterial.values, hasLength(10));
      expect(EquipmentRarity.values, hasLength(10));
      expect(EquipmentCatalog.all, hasLength(2400));
      expect(
        EquipmentCatalog.all.map((definition) => definition.id).toSet(),
        hasLength(2400),
      );

      for (final heroClass in HeroClass.values) {
        expect(EquipmentCatalog.forClass(heroClass), hasLength(600));
        expect(
          EquipmentCatalog.forWorkshop(heroClass.workshop),
          hasLength(600),
        );
        for (final slot in EquipmentSlot.values) {
          final variants = EquipmentCatalog.variantsFor(heroClass, slot);
          expect(variants, hasLength(100));
          expect(
            variants.map((item) => item.material).toSet(),
            EquipmentMaterial.values.toSet(),
          );
          expect(
            variants.map((item) => item.rarity).toSet(),
            EquipmentRarity.values.toSet(),
          );
        }
      }
    });

    test('uses stable readable IDs and constant lookup identity', () {
      final item = EquipmentCatalog.definition(
        heroClass: HeroClass.mage,
        slot: EquipmentSlot.weapon,
        material: EquipmentMaterial.arcaneCrystal,
        rarity: EquipmentRarity.abyssal,
      );

      expect(item.id, 'mage:weapon:arcane_crystal:abyssal');
      expect(identical(EquipmentCatalog.byId(item.id), item), isTrue);
      expect(EquipmentCatalog.byId('missing:item'), isNull);
      expect(() => EquipmentCatalog.all.add(item), throwsUnsupportedError);
    });
  });

  group('Equipment materials and class identity', () {
    test('references the ten requested real mining resources', () {
      const expectedIds = {
        'copper',
        'iron',
        'silver',
        'gold',
        'platinum',
        'mithril',
        'adamantite',
        'runite',
        'orichalcum',
        'arcane_crystal',
      };
      expect(
        EquipmentMaterial.values.map((material) => material.resourceId).toSet(),
        expectedIds,
      );

      for (final material in EquipmentMaterial.values) {
        expect(
          GatheringResource.byId(material.resourceId),
          same(material.resource),
        );
        expect(material.resource.discipline, GatheringDiscipline.mining);
      }
    });

    test('maps every material to a real woodcutting shaft resource', () {
      for (final material in EquipmentMaterial.values) {
        final wood = GatheringResource.byId(material.shaftWoodId);
        expect(wood, isNotNull);
        expect(wood!.discipline, GatheringDiscipline.woodcutting);
        expect(material.shaftResourceId, '${material.shaftWoodId}_shaft');
      }
      expect(
        EquipmentMaterial.values.map((material) => material.shaftWoodId),
        everyElement(isNotEmpty),
      );
    });

    test('assigns every material a distinct, fully-opaque tint color', () {
      final tints = EquipmentMaterial.values
          .map((material) => material.tintRgb)
          .toSet();
      expect(tints, hasLength(EquipmentMaterial.values.length));
      for (final tint in tints) {
        expect(tint, inInclusiveRange(0x000000, 0xFFFFFF));
      }
    });

    test('routes every class to its own workshop skill', () {
      expect(HeroClass.knight.workshop, EquipmentWorkshop.blacksmith);
      expect(HeroClass.assassin.workshop, EquipmentWorkshop.veilGuild);
      expect(HeroClass.mage.workshop, EquipmentWorkshop.arcanist);
      expect(HeroClass.archer.workshop, EquipmentWorkshop.artisan);
      expect(
        EquipmentWorkshop.values.map((workshop) => workshop.skillId).toSet(),
        {'smithing', 'shadowcraft', 'arcanism', 'crafting'},
      );
    });

    test('gives each class its characteristic weapon and offhand', () {
      String name(HeroClass heroClass, EquipmentSlot slot) {
        return EquipmentCatalog.definition(
          heroClass: heroClass,
          slot: slot,
          material: EquipmentMaterial.iron,
          rarity: EquipmentRarity.common,
        ).name;
      }

      expect(name(HeroClass.knight, EquipmentSlot.weapon), contains('Espada'));
      expect(name(HeroClass.knight, EquipmentSlot.offhand), contains('Escudo'));
      expect(
        name(HeroClass.assassin, EquipmentSlot.weapon),
        contains('Lâminas'),
      );
      expect(
        name(HeroClass.assassin, EquipmentSlot.offhand),
        contains('Relicário'),
      );
      expect(name(HeroClass.mage, EquipmentSlot.weapon), contains('Cajado'));
      expect(name(HeroClass.mage, EquipmentSlot.offhand), contains('Grimório'));
      expect(name(HeroClass.archer, EquipmentSlot.weapon), contains('Arco'));
      expect(name(HeroClass.archer, EquipmentSlot.offhand), contains('Aljava'));
    });

    test('changes every class weapon name with the crafting material', () {
      for (final heroClass in HeroClass.values) {
        final weaponNames = EquipmentMaterial.values.map((material) {
          return EquipmentCatalog.definition(
            heroClass: heroClass,
            slot: EquipmentSlot.weapon,
            material: material,
            rarity: EquipmentRarity.common,
          ).name;
        }).toSet();
        expect(weaponNames, hasLength(10));
      }
    });
  });

  group('Equipment balance invariants', () {
    test('only bows, quivers, and staves need a carved shaft', () {
      const expectedShaftSlots = {
        (HeroClass.archer, EquipmentSlot.weapon),
        (HeroClass.archer, EquipmentSlot.offhand),
        (HeroClass.mage, EquipmentSlot.weapon),
      };
      for (final heroClass in HeroClass.values) {
        for (final slot in EquipmentSlot.values) {
          final item = EquipmentCatalog.definition(
            heroClass: heroClass,
            slot: slot,
            material: EquipmentMaterial.iron,
            rarity: EquipmentRarity.common,
          );
          final expectsShaft = expectedShaftSlots.contains((
            heroClass,
            slot,
          ));
          expect(
            item.cost.resources.containsKey(item.material.shaftResourceId),
            expectsShaft,
            reason: '$heroClass $slot',
          );
        }
      }
    });

    test('every recipe costs currency and its selected mineral', () {
      for (final item in EquipmentCatalog.all) {
        expect(item.workshop, item.heroClass.workshop);
        expect(item.cost.gold, greaterThan(0));
        final needsShaft =
            (item.heroClass == HeroClass.archer &&
                (item.slot == EquipmentSlot.weapon ||
                    item.slot == EquipmentSlot.offhand)) ||
            (item.heroClass == HeroClass.mage &&
                item.slot == EquipmentSlot.weapon);
        expect(
          item.cost.resources.keys,
          needsShaft
              ? {item.material.barResourceId, item.material.shaftResourceId}
              : {item.material.barResourceId},
        );
        expect(
          item.cost.resources[item.material.barResourceId],
          greaterThan(0),
        );
        if (needsShaft) {
          expect(
            item.cost.resources[item.material.shaftResourceId],
            greaterThan(0),
          );
        }
        expect(item.requiredWorkshopLevel, inInclusiveRange(1, 100));
        expect(item.craftDurationSeconds, greaterThan(0));
        expect(item.workshopExperience, greaterThan(0));
        expect(item.stats.powerScore, greaterThan(0));
        expect(
          [
            item.stats.physicalPower,
            item.stats.arcanePower,
            item.stats.defense,
            item.stats.vitality,
            item.stats.precision,
            item.stats.evasion,
          ].every((stat) => stat >= 0),
          isTrue,
        );
      }
    });

    test(
      'material tiers strictly increase power, price, time, level, and XP',
      () {
        for (final heroClass in HeroClass.values) {
          for (final slot in EquipmentSlot.values) {
            EquipmentDefinition? previous;
            for (final material in EquipmentMaterial.values) {
              final current = EquipmentCatalog.definition(
                heroClass: heroClass,
                slot: slot,
                material: material,
                rarity: EquipmentRarity.common,
              );
              if (previous != null) {
                expect(
                  current.stats.powerScore,
                  greaterThan(previous.stats.powerScore),
                );
                expect(current.cost.gold, greaterThan(previous.cost.gold));
                expect(
                  current.craftDurationSeconds,
                  greaterThan(previous.craftDurationSeconds),
                );
                expect(
                  current.requiredWorkshopLevel,
                  greaterThan(previous.requiredWorkshopLevel),
                );
                expect(
                  current.workshopExperience,
                  greaterThan(previous.workshopExperience),
                );
              }
              previous = current;
            }
          }
        }
      },
    );

    test('rarities strictly increase progression and visual intensity', () {
      for (final heroClass in HeroClass.values) {
        for (final slot in EquipmentSlot.values) {
          EquipmentDefinition? previous;
          for (final rarity in EquipmentRarity.values) {
            final current = EquipmentCatalog.definition(
              heroClass: heroClass,
              slot: slot,
              material: EquipmentMaterial.mithril,
              rarity: rarity,
            );
            expect(current.visuals.borderTier, rarity.tier);
            expect(current.visuals.borderStyle, rarity.borderStyle);
            expect(current.visuals.auraStyle, rarity.auraStyle);
            if (previous != null) {
              expect(
                current.stats.powerScore,
                greaterThan(previous.stats.powerScore),
              );
              expect(current.cost.gold, greaterThan(previous.cost.gold));
              expect(
                current.visuals.auraIntensity,
                greaterThan(previous.visuals.auraIntensity),
              );
              expect(
                current.visuals.runeDensity,
                greaterThanOrEqualTo(previous.visuals.runeDensity),
              );
            }
            previous = current;
          }
        }
      }
    });

    test('marks the extremes as weathered and abyssal', () {
      final common = EquipmentCatalog.definition(
        heroClass: HeroClass.knight,
        slot: EquipmentSlot.head,
        material: EquipmentMaterial.copper,
        rarity: EquipmentRarity.common,
      );
      final abyssal = EquipmentCatalog.definition(
        heroClass: HeroClass.knight,
        slot: EquipmentSlot.head,
        material: EquipmentMaterial.copper,
        rarity: EquipmentRarity.abyssal,
      );

      expect(common.visuals.borderStyle, EquipmentBorderStyle.weathered);
      expect(common.visuals.auraStyle, EquipmentAuraStyle.none);
      expect(common.visuals.auraIntensity, 0);
      expect(abyssal.visuals.borderStyle, EquipmentBorderStyle.abyssalCrown);
      expect(abyssal.visuals.auraStyle, EquipmentAuraStyle.abyssalFlame);
      expect(abyssal.visuals.auraIntensity, greaterThan(0.9));
    });
  });
}
