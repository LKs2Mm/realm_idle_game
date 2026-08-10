import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/tools/models/tool_models.dart';
import 'package:realm_idle_game/models/game_state.dart';

void main() {
  group('GameState tool ownership', () {
    test('starts with one owned and equipped tool per discipline', () {
      final state = GameState();

      expect(state.tools.ownedById, hasLength(3));
      expect(state.ownedTool('pickaxe:wooden'), isNotNull);
      expect(state.ownedTool('axe:wooden'), isNotNull);
      expect(state.ownedTool('rod:basic'), isNotNull);
      expect(
        state.tools.equippedId(GatheringDiscipline.mining),
        'pickaxe:wooden',
      );
      expect(
        state.tools.equippedId(GatheringDiscipline.woodcutting),
        'axe:wooden',
      );
      expect(state.tools.equippedId(GatheringDiscipline.fishing), 'rod:basic');
    });

    test('blocks acquisition by skill level without spending resources', () {
      final state = GameState();
      state.skills['mining']!.level = 4;
      state.gatheringInventory.add('iron_bar', 10);

      final result = state.acquireTool('pickaxe:iron');

      expect(result, ToolActionResult.skillLevelRequired);
      expect(state.gatheringInventory.quantityOf('iron_bar'), 10);
      expect(state.ownedTool('pickaxe:iron'), isNull);
      expect(
        state.tools.equippedId(GatheringDiscipline.mining),
        'pickaxe:wooden',
      );
    });

    test('does not partially spend a multi-resource recipe', () {
      final state = GameState();
      state.skills['woodcutting']!.level = 5;
      state.addGold(20);
      state.gatheringInventory.add('mahogany_log', 10);
      state.gatheringInventory.add('iron_bar', 4);
      final before = Map<String, int>.from(state.gatheringInventory.resources);

      final result = state.acquireTool('axe:iron');

      expect(result, ToolActionResult.insufficientResources);
      expect(state.gatheringInventory.resources, before);
      expect(state.gold, 20);
      expect(state.ownedTool('axe:iron'), isNull);
    });

    test('missing gold never consumes gathered materials', () {
      final state = GameState();
      state.skills['mining']!.level = 5;
      state.gatheringInventory.add('iron_bar', 10);

      final result = state.acquireTool('pickaxe:iron');

      expect(result, ToolActionResult.insufficientGold);
      expect(state.gatheringInventory.quantityOf('iron_bar'), 10);
      expect(state.gold, 0);
      expect(state.ownedTool('pickaxe:iron'), isNull);
    });

    test('acquires, refuses a second purchase, and equips an owned tool', () {
      final state = GameState();
      state.skills['mining']!.level = 5;
      state.addGold(20);
      state.gatheringInventory.add('iron_bar', 20);

      expect(state.acquireTool('pickaxe:iron'), ToolActionResult.success);
      expect(state.gatheringInventory.quantityOf('iron_bar'), 10);
      expect(state.gold, 0);
      expect(state.ownedTool('pickaxe:iron')?.upgradeLevel, 0);
      expect(
        state.tools.equippedId(GatheringDiscipline.mining),
        'pickaxe:wooden',
      );

      expect(state.acquireTool('pickaxe:iron'), ToolActionResult.alreadyOwned);
      expect(state.gatheringInventory.quantityOf('iron_bar'), 10);

      expect(state.equipTool('pickaxe:iron'), ToolActionResult.success);
      expect(
        state.tools.equippedId(GatheringDiscipline.mining),
        'pickaxe:iron',
      );
    });
  });

  group('GameState tool upgrades', () {
    test('spends each upgrade atomically and stops at level five', () {
      final state = GameState();
      state.skills['mining']!.level = 5;
      state.addGold(20);
      state.gatheringInventory.add('iron_bar', 10);
      expect(state.acquireTool('pickaxe:iron'), ToolActionResult.success);

      expect(
        state.upgradeTool('pickaxe:iron'),
        ToolActionResult.insufficientGold,
      );
      expect(state.ownedTool('pickaxe:iron')?.upgradeLevel, 0);

      state.addGold(15);
      expect(
        state.upgradeTool('pickaxe:iron'),
        ToolActionResult.insufficientResources,
      );
      expect(state.gold, 15);

      const upgradeCosts = [5, 10, 15, 20, 25];
      for (var level = 0; level < upgradeCosts.length; level++) {
        if (level > 0) state.addGold(15 * (level + 1));
        state.gatheringInventory.add('iron_bar', upgradeCosts[level]);

        expect(state.upgradeTool('pickaxe:iron'), ToolActionResult.success);
        expect(state.ownedTool('pickaxe:iron')?.upgradeLevel, level + 1);
        expect(state.gatheringInventory.quantityOf('iron_bar'), 0);
        expect(state.gold, 0);
      }

      state.addGold(75);
      state.gatheringInventory.add('iron_bar', 25);
      expect(
        state.upgradeTool('pickaxe:iron'),
        ToolActionResult.maxUpgradeReached,
      );
      expect(state.ownedTool('pickaxe:iron')?.upgradeLevel, 5);
      expect(state.gatheringInventory.quantityOf('iron_bar'), 25);
      expect(state.gold, 75);
    });
  });

  group('tool transactions across gathering disciplines', () {
    final scenarios =
        <
          ({
            GatheringDiscipline discipline,
            String skillId,
            String toolId,
            Map<String, int> recipe,
          })
        >[
          (
            discipline: GatheringDiscipline.mining,
            skillId: 'mining',
            toolId: 'pickaxe:iron',
            recipe: {'iron_bar': 10},
          ),
          (
            discipline: GatheringDiscipline.woodcutting,
            skillId: 'woodcutting',
            toolId: 'axe:iron',
            recipe: {'mahogany_log': 10, 'iron_bar': 5},
          ),
          (
            discipline: GatheringDiscipline.fishing,
            skillId: 'fishing',
            toolId: 'rod:reinforced',
            recipe: {'mahogany_log': 6, 'iron_bar': 3},
          ),
        ];

    for (final scenario in scenarios) {
      test('acquires and equips ${scenario.discipline.name} tools', () {
        final state = GameState();
        state.skills[scenario.skillId]!.level = 5;
        state.addGold(20);
        final experienceBefore = state.skills[scenario.skillId]!.experience;
        for (final ingredient in scenario.recipe.entries) {
          state.gatheringInventory.add(ingredient.key, ingredient.value);
        }

        expect(state.acquireTool(scenario.toolId), ToolActionResult.success);
        expect(state.equipTool(scenario.toolId), ToolActionResult.success);

        expect(state.ownedTool(scenario.toolId), isNotNull);
        expect(state.gold, 0);
        expect(state.tools.equippedId(scenario.discipline), scenario.toolId);
        for (final resourceId in scenario.recipe.keys) {
          expect(state.gatheringInventory.quantityOf(resourceId), 0);
        }
        expect(state.skills[scenario.skillId]!.experience, experienceBefore);
      });
    }
  });
}
