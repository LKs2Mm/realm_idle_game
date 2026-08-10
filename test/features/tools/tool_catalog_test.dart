import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/tools/data/tool_catalog.dart';
import 'package:realm_idle_game/features/tools/models/tool_models.dart';

void main() {
  group('ToolCatalog', () {
    test(
      'defines six ordered gold-and-resource tiers for every discipline',
      () {
        expect(ToolCatalog.all, hasLength(18));
        expect(
          ToolCatalog.all.map((tool) => tool.id).toSet(),
          hasLength(ToolCatalog.all.length),
        );

        for (final discipline in GatheringDiscipline.values) {
          final tools = ToolCatalog.forDiscipline(discipline);

          expect(tools.map((tool) => tool.tier), [0, 1, 2, 3, 4, 5]);
          expect(tools.map((tool) => tool.requiredSkillLevel), [
            1,
            5,
            15,
            60,
            80,
            100,
          ]);
          expect(tools.every((tool) => tool.maxUpgradeLevel == 5), isTrue);
          expect(tools.map((tool) => tool.purchaseCost.gold), [
            0,
            20,
            150,
            12000,
            40000,
            120000,
          ]);
          expect(tools.map((tool) => tool.upgradeGoldBase), [
            10,
            15,
            40,
            600,
            2000,
            6000,
          ]);
          expect(tools.first.purchaseCost.isFree, isTrue);
          expect(
            tools
                .skip(1)
                .every(
                  (tool) =>
                      !tool.purchaseCost.isFree &&
                      tool.purchaseCost.resources.isNotEmpty,
                ),
            isTrue,
          );
        }
      },
    );

    test('maps one namespaced starter to each discipline', () {
      expect(
        ToolCatalog.starterFor(GatheringDiscipline.mining).id,
        'pickaxe:wooden',
      );
      expect(
        ToolCatalog.starterFor(GatheringDiscipline.woodcutting).id,
        'axe:wooden',
      );
      expect(
        ToolCatalog.starterFor(GatheringDiscipline.fishing).id,
        'rod:basic',
      );

      for (final discipline in GatheringDiscipline.values) {
        final starter = ToolCatalog.starterFor(discipline);
        expect(starter.discipline, discipline);
        expect(starter.isStarter, isTrue);
      }
    });

    test('caps bonuses and upgrade recipes at level five', () {
      final tool = ToolCatalog.byId('pickaxe:iron')!;

      expect(tool.speedForUpgrade(0), closeTo(1.10, 1e-9));
      expect(tool.speedForUpgrade(5), closeTo(1.20, 1e-9));
      expect(tool.speedForUpgrade(99), closeTo(1.20, 1e-9));
      expect(tool.yieldForUpgrade(0), closeTo(1.05, 1e-9));
      expect(tool.yieldForUpgrade(5), closeTo(1.10, 1e-9));
      expect(tool.yieldForUpgrade(99), closeTo(1.10, 1e-9));
      expect(tool.upgradeCostFor(0)?.resources, {'iron_bar': 5});
      expect(tool.upgradeCostFor(0)?.gold, 15);
      expect(tool.upgradeCostFor(4)?.resources, {'iron_bar': 25});
      expect(tool.upgradeCostFor(4)?.gold, 75);
      expect(tool.upgradeCostFor(5), isNull);
    });
  });

  group('ToolCollection serialization', () {
    test('clamps restored upgrades to the supported range', () {
      final collection = ToolCollection.fromJson({
        'owned': {
          'pickaxe:iron': {'upgradeLevel': 99},
          'axe:iron': {'upgradeLevel': -4},
        },
        'equipped': {'mining': 'pickaxe:iron', 'woodcutting': 'axe:iron'},
      });

      expect(collection.ownedTool('pickaxe:iron')?.upgradeLevel, 5);
      expect(collection.ownedTool('axe:iron')?.upgradeLevel, 0);
      expect(collection.equippedId(GatheringDiscipline.mining), 'pickaxe:iron');
      expect(
        collection.equippedId(GatheringDiscipline.woodcutting),
        'axe:iron',
      );
    });
  });
}
