import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/equipment/data/equipment_catalog.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';

void main() {
  EquipmentDefinition item({
    HeroClass heroClass = HeroClass.knight,
    EquipmentSlot slot = EquipmentSlot.weapon,
  }) {
    return EquipmentCatalog.definition(
      heroClass: heroClass,
      slot: slot,
      material: EquipmentMaterial.iron,
      rarity: EquipmentRarity.rare,
    );
  }

  group('EquipmentCost', () {
    test('checks external gold and resources without mutating either', () {
      final cost = item().cost;
      final resources = Map<String, int>.from(cost.resources);

      expect(
        cost.canAfford(availableGold: cost.gold, availableResources: resources),
        isTrue,
      );
      expect(
        cost.canAfford(
          availableGold: cost.gold - 1,
          availableResources: resources,
        ),
        isFalse,
      );
      expect(
        cost.canAfford(availableGold: cost.gold, availableResources: const {}),
        isFalse,
      );
      expect(resources, cost.resources);
    });
  });

  group('EquipmentState pure operations', () {
    test(
      'grants completed items without carrying duplicate currency state',
      () {
        final original = EquipmentState();
        final definition = item();
        final granted = original.grant(definition.id, quantity: 2);

        expect(original.inventory.itemQuantity(definition.id), 0);
        expect(granted.inventory.itemQuantity(definition.id), 2);
        expect(granted.loadouts.equipped, isEmpty);
        expect(identical(original.grant('', quantity: 2), original), isTrue);
        expect(
          identical(original.grant(definition.id, quantity: 0), original),
          isTrue,
        );
      },
    );

    test('blocks equipping an item that is not owned', () {
      final original = EquipmentState();
      final result = original.equip(item());

      expect(result.result, EquipmentActionResult.itemNotOwned);
      expect(result.succeeded, isFalse);
      expect(identical(result.state, original), isTrue);
    });

    test('keeps independent loadouts so no class choice is permanent', () {
      final knightWeapon = item();
      final mageWeapon = item(heroClass: HeroClass.mage);
      final archerOffhand = item(
        heroClass: HeroClass.archer,
        slot: EquipmentSlot.offhand,
      );
      final stocked = EquipmentState()
          .grantDefinition(knightWeapon)
          .grantDefinition(mageWeapon)
          .grantDefinition(archerOffhand);

      final knightEquipped = stocked.equip(knightWeapon).state;
      final mageEquipped = knightEquipped.equip(mageWeapon).state;
      final allEquipped = mageEquipped.equip(archerOffhand).state;

      expect(
        allEquipped.loadouts.equippedId(HeroClass.knight, EquipmentSlot.weapon),
        knightWeapon.id,
      );
      expect(
        allEquipped.loadouts.equippedId(HeroClass.mage, EquipmentSlot.weapon),
        mageWeapon.id,
      );
      expect(
        allEquipped.loadouts.equippedId(
          HeroClass.archer,
          EquipmentSlot.offhand,
        ),
        archerOffhand.id,
      );
      expect(stocked.loadouts.equipped, isEmpty);
    });

    test('replaces only the matching class slot and can unequip it', () {
      final first = item();
      final replacement = EquipmentCatalog.definition(
        heroClass: HeroClass.knight,
        slot: EquipmentSlot.weapon,
        material: EquipmentMaterial.mithril,
        rarity: EquipmentRarity.epic,
      );
      final equipped = EquipmentState()
          .grantDefinition(first)
          .grantDefinition(replacement)
          .equip(first)
          .state
          .equip(replacement)
          .state;

      expect(
        equipped.loadouts.equippedId(HeroClass.knight, EquipmentSlot.weapon),
        replacement.id,
      );
      expect(equipped.inventory.itemQuantity(first.id), 1);
      expect(equipped.inventory.itemQuantity(replacement.id), 1);

      final unequipped = equipped.unequip(
        HeroClass.knight,
        EquipmentSlot.weapon,
      );
      expect(unequipped.succeeded, isTrue);
      expect(
        unequipped.state.loadouts.equippedId(
          HeroClass.knight,
          EquipmentSlot.weapon,
        ),
        isNull,
      );
      expect(
        unequipped.state.unequip(HeroClass.knight, EquipmentSlot.weapon).result,
        EquipmentActionResult.slotAlreadyEmpty,
      );
    });

    test('exposes deeply unmodifiable inventory and loadouts', () {
      final definition = item();
      final equipped = EquipmentState()
          .grantDefinition(definition)
          .equip(definition)
          .state;

      expect(
        () => equipped.inventory.items[definition.id] = 99,
        throwsUnsupportedError,
      );
      expect(
        () =>
            equipped.loadouts.equipped[HeroClass.knight]![EquipmentSlot
                    .weapon] =
                definition.id,
        throwsUnsupportedError,
      );
    });
  });

  group('EquipmentState serialization', () {
    test('round-trips quantities and independent class loadouts', () {
      final knight = item();
      final assassin = item(heroClass: HeroClass.assassin);
      final mage = item(heroClass: HeroClass.mage);
      final archer = item(heroClass: HeroClass.archer);
      var state = EquipmentState()
          .grantDefinition(knight, quantity: 2)
          .grantDefinition(assassin)
          .grantDefinition(mage)
          .grantDefinition(archer);
      for (final definition in [knight, assassin, mage, archer]) {
        state = state.equip(definition).state;
      }

      final restored = EquipmentState.fromJson(state.toJson());

      expect(restored.toJson(), state.toJson());
      expect(restored.inventory.itemQuantity(knight.id), 2);
      for (final definition in [knight, assassin, mage, archer]) {
        expect(
          restored.loadouts.equippedId(definition.heroClass, definition.slot),
          definition.id,
        );
      }
    });

    test('sanitizes malformed quantities and orphaned equipped IDs', () {
      final definition = item();
      final restored = EquipmentState.fromJson({
        'inventory': {
          'items': {
            definition.id: 2.9,
            'zero': 0,
            'negative': -3,
            'infinite': double.infinity,
            'wrong': '7',
            '': 5,
          },
        },
        'loadouts': {
          'knight': {'weapon': definition.id, 'head': 'not-owned', 'body': 42},
          'unknown-class': {'weapon': definition.id},
        },
      });

      expect(restored.inventory.items, {definition.id: 2});
      expect(
        restored.loadouts.equippedId(HeroClass.knight, EquipmentSlot.weapon),
        definition.id,
      );
      expect(
        restored.loadouts.equippedId(HeroClass.knight, EquipmentSlot.head),
        isNull,
      );
      expect(restored.loadouts.equipped, hasLength(1));
    });

    test('falls back to an empty safe state for non-map data', () {
      final restored = EquipmentState.fromJson('corrupted');

      expect(restored.inventory.items, isEmpty);
      expect(restored.loadouts.equipped, isEmpty);
    });
  });
}
