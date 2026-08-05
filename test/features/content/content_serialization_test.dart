import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/content/data/potion_catalog.dart';
import 'package:realm_idle_game/features/content/models/active_buffs.dart';
import 'package:realm_idle_game/features/content/models/alchemy.dart';
import 'package:realm_idle_game/features/content/models/content_cost.dart';
import 'package:realm_idle_game/features/content/models/content_inventory.dart';

void main() {
  group('ContentCost', () {
    test('checks every material without mutating the inventory', () {
      const cost = ContentCost({'rune_essence': 4, 'grave_dust': 2});
      final inventory = {'rune_essence': 5, 'grave_dust': 2};
      expect(cost.canAfford(inventory), isTrue);
      expect(cost.canAfford({'rune_essence': 5}), isFalse);
      expect(inventory, {'rune_essence': 5, 'grave_dust': 2});
      expect(cost.totalUnits, 6);
    });
  });

  group('ContentInventory', () {
    test('round-trips crafted potions and spell charges through JSON', () {
      final original = ContentInventory(
        consumables: {'gravefury_draught': 3},
        spells: {'runic_ember': 7, 'storm_needle': 2},
      );
      final encoded = jsonEncode(original.toJson());
      final restored = ContentInventory.fromJson(jsonDecode(encoded));

      expect(restored.consumables, original.consumables);
      expect(restored.spells, original.spells);
      expect(restored.totalConsumables, 3);
      expect(restored.totalSpells, 9);
    });

    test('adds and consumes atomically while rejecting invalid quantities', () {
      final inventory = ContentInventory();
      inventory.addConsumable('cryptskin_elixir', 2);
      inventory.addSpell('runic_ember', 3);

      expect(inventory.tryConsumeConsumable('cryptskin_elixir'), isTrue);
      expect(inventory.quantityOfConsumable('cryptskin_elixir'), 1);
      expect(inventory.tryConsumeConsumable('cryptskin_elixir', 2), isFalse);
      expect(inventory.quantityOfConsumable('cryptskin_elixir'), 1);
      expect(inventory.tryConsumeSpell('runic_ember', 3), isTrue);
      expect(inventory.quantityOfSpell('runic_ember'), 0);
      expect(inventory.tryConsumeSpell('runic_ember', 0), isFalse);
    });

    test('sanitizes damaged save entries', () {
      final inventory = ContentInventory.fromJson({
        'consumables': {'valid': 2, 'negative': -2, 'text': '3'},
        'spells': {'valid_spell': 1.9, 'zero': 0},
      });
      expect(inventory.consumables, {'valid': 2});
      expect(inventory.spells, {'valid_spell': 1});
    });
  });

  group('ActiveBuffs', () {
    test('activates real multipliers and expires them at the exact time', () {
      final buffs = ActiveBuffs();
      final potion = PotionCatalog.forBuff(BuffType.attackPower)!;
      final start = DateTime.utc(2026, 8, 1, 12);
      final buff = buffs.activate(potion, start);

      expect(
        buffs.multiplierFor(
          BuffType.attackPower,
          start.add(const Duration(seconds: 1)),
        ),
        closeTo(1.08, 0.000001),
      );
      expect(
        buff.remainingAt(start.add(const Duration(seconds: 60))),
        const Duration(seconds: 240),
      );
      expect(
        buffs.multiplierFor(
          BuffType.attackPower,
          start.add(Duration(seconds: potion.durationSeconds)),
        ),
        1,
      );
    });

    test('round-trips all active buff data through JSON', () {
      final start = DateTime.utc(2026, 8, 1, 12);
      final original = ActiveBuffs();
      original.activate(PotionCatalog.forBuff(BuffType.gatheringSpeed)!, start);
      original.activate(PotionCatalog.forBuff(BuffType.goldGain)!, start);

      final restored = ActiveBuffs.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );
      expect(restored.activeByType, hasLength(2));
      for (final type in [BuffType.gatheringSpeed, BuffType.goldGain]) {
        final before = original.activeByType[type]!;
        final after = restored.activeByType[type]!;
        expect(after.sourcePotionId, before.sourcePotionId);
        expect(after.type, before.type);
        expect(after.potency, before.potency);
        expect(
          after.expiresAtEpochMilliseconds,
          before.expiresAtEpochMilliseconds,
        );
      }
    });

    test('refreshes equal buff types and prunes expired entries', () {
      final potion = PotionCatalog.forBuff(BuffType.defense)!;
      final start = DateTime.utc(2026, 8, 1, 12);
      final buffs = ActiveBuffs();
      final first = buffs.activate(potion, start);
      final refreshed = buffs.activate(
        potion,
        start.add(const Duration(seconds: 30)),
      );

      expect(buffs.activeByType, hasLength(1));
      expect(
        refreshed.expiresAtEpochMilliseconds,
        greaterThan(first.expiresAtEpochMilliseconds),
      );
      expect(buffs.pruneExpired(start.add(const Duration(hours: 1))), 1);
      expect(buffs.activeByType, isEmpty);
    });

    test('ignores malformed entries without losing valid buffs', () {
      final start = DateTime.utc(2026, 8, 1, 12);
      final valid = ActiveBuffs()
        ..activate(PotionCatalog.forBuff(BuffType.lootChance)!, start);
      final json = valid.toJson()..['damaged'] = {'potency': -1};

      final restored = ActiveBuffs.fromJson(json);
      expect(restored.activeByType.keys, [BuffType.lootChance]);
    });
  });
}
