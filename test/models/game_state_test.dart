import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/tools/data/tool_catalog.dart';
import 'package:realm_idle_game/features/tools/models/tool_models.dart';
import 'package:realm_idle_game/models/audio_settings.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';

void main() {
  group('GameState gathering', () {
    test('only rewards resources and XP when cycles are completed', () {
      final state = GameState();

      expect(state.startGathering('copper'), isTrue);
      expect(state.gatheringInventory.quantityOf('copper'), 0);
      expect(state.skills['mining']!.experience, 0);

      state.completeGatheringCycles('copper', 2);

      expect(state.gatheringInventory.quantityOf('copper'), 2);
      expect(state.skills['mining']!.experience, closeTo(11.2, 0.0001));
    });

    test('rewards the matching woodcutting and fishing skills', () {
      final state = GameState();

      state.completeGatheringCycles('normal_log', 2);
      state.completeGatheringCycles('shrimp', 3);

      expect(state.gatheringInventory.quantityOf('normal_log'), 2);
      expect(state.gatheringInventory.quantityOf('shrimp'), 3);
      expect(state.skills['woodcutting']!.experience, 20);
      expect(state.skills['fishing']!.experience, 30);
      expect(state.skills['mining']!.experience, 0);
    });

    test('does not start a resource above the discipline level', () {
      final state = GameState();

      expect(state.startGathering('iron'), isFalse);
      expect(state.activeGatheringSession, isNull);
    });

    test('uses stable discipline skill identifiers', () {
      expect(GatheringDiscipline.mining.skillId, 'mining');
      expect(GatheringDiscipline.woodcutting.skillId, 'woodcutting');
      expect(GatheringDiscipline.fishing.skillId, 'fishing');
    });

    test('balances mining resources with early coal and tier unlocks', () {
      final resources = GatheringResource.forDiscipline(
        GatheringDiscipline.mining,
      );

      expect(resources.map((resource) => resource.requiredLevel), [
        1,
        5,
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        90,
        100,
        110,
      ]);

      final copper = GatheringResource.byId('copper')!;
      final coal = GatheringResource.byId('coal')!;
      final runeEssence = GatheringResource.byId('rune_essence')!;
      final iron = GatheringResource.byId('iron')!;
      expect(copper.experiencePerCycle, 5.6);
      expect(copper.cycleSeconds, 3);
      expect(coal.requiredLevel, 5);
      expect(coal.cycleSeconds, 4);
      expect(coal.experiencePerCycle, 6.8);
      expect(coal.description, contains('Combustível'));
      expect(runeEssence.name, 'Essência rúnica');
      expect(runeEssence.experiencePerCycle, 1.3);
      expect(runeEssence.cycleSeconds, 1);
      expect(runeEssence.description, contains('fabricar magias'));
      expect(iron.experiencePerCycle, 15);
      expect(iron.cycleSeconds, 5);

      final trainingResources = resources
          .where((resource) => resource.requiredLevel >= 20)
          .toList();
      for (var index = 1; index < trainingResources.length; index++) {
        final previous = trainingResources[index - 1];
        final current = trainingResources[index];
        expect(
          current.experiencePerCycle / current.cycleSeconds,
          greaterThanOrEqualTo(
            previous.experiencePerCycle / previous.cycleSeconds,
          ),
        );
      }

      final state = GameState();
      final mining = state.skills['mining']!;
      for (final resource in resources.skip(1)) {
        mining.level = resource.requiredLevel - 1;
        expect(state.canGather(resource), isFalse, reason: resource.id);
        mining.level = resource.requiredLevel;
        expect(state.canGather(resource), isTrue, reason: resource.id);
      }
    });

    test('uses a long-form level curve through level 100', () {
      expect(Skill.experienceRequiredForLevel(1), 100);
      expect(Skill.experienceRequiredForLevel(10), 1270);
      expect(Skill.experienceRequiredForLevel(50), 26070);
      expect(Skill.experienceRequiredForLevel(100), 102070);
      expect(Skill.totalExperienceToReachLevel(100), 3389430);

      final resources = GatheringResource.forDiscipline(
        GatheringDiscipline.mining,
      );
      var baseTrainingSeconds = 0.0;
      for (var level = 1; level < 100; level++) {
        var bestUnlockedRate = 0.0;
        for (final resource in resources) {
          if (resource.requiredLevel > level) continue;
          final rate = resource.experiencePerCycle / resource.cycleSeconds;
          if (rate > bestUnlockedRate) bestUnlockedRate = rate;
        }
        baseTrainingSeconds +=
            Skill.experienceRequiredForLevel(level) / bestUnlockedRate;
      }

      final baseTrainingHours = baseTrainingSeconds / 3600;
      expect(baseTrainingHours, greaterThan(200));
      expect(baseTrainingHours, lessThan(225));

      final miningTools = ToolCatalog.forDiscipline(GatheringDiscipline.mining);
      var optimizedTrainingSeconds = 0.0;
      for (var level = 1; level < 100; level++) {
        final bestTool = miningTools
            .where((tool) => tool.requiredSkillLevel <= level)
            .last;
        final speed = bestTool.speedForUpgrade(bestTool.maxUpgradeLevel);
        var bestUnlockedRate = 0.0;
        for (final resource in resources) {
          if (resource.requiredLevel > level) continue;
          final durationMilliseconds = (resource.cycleSeconds * 1000 / speed)
              .ceil();
          final rate =
              resource.experiencePerCycle / (durationMilliseconds / 1000);
          if (rate > bestUnlockedRate) bestUnlockedRate = rate;
        }
        optimizedTrainingSeconds +=
            Skill.experienceRequiredForLevel(level) / bestUnlockedRate;
      }

      final optimizedTrainingHours = optimizedTrainingSeconds / 3600;
      expect(optimizedTrainingHours, greaterThan(145));
      expect(optimizedTrainingHours, lessThan(155));
    });
  });

  group('GameState combat economy', () {
    test('starting combat does not grant gold or click XP', () {
      final state = GameState();

      expect(state.startCombat('grave_rat'), isTrue);

      expect(state.gold, 0);
      expect(state.skills['attack']!.experience, 0);
      expect(state.activeCombatSession?.encounterId, 'grave_rat');
    });

    test('completed victories grant batched gold and attack XP', () {
      final state = GameState();
      final encounter = CombatEncounter.byId('grave_rat')!;

      final reward = state.completeCombatVictories(encounter.id, 3);

      expect(reward?.victories, 3);
      expect(reward?.gold, encounter.goldPerVictory * 3);
      expect(reward?.experience, encounter.experiencePerVictory * 3);
      expect(state.gold, encounter.goldPerVictory * 3);
      expect(
        state.skills['attack']!.experience,
        encounter.experiencePerVictory * 3,
      );
    });

    test('locked encounters cannot start or grant rewards', () {
      final state = GameState();

      expect(state.startCombat('rune_lord'), isFalse);
      expect(state.completeCombatVictories('rune_lord', 1), isNull);
      expect(state.gold, 0);
      expect(state.skills['attack']!.experience, 0);
    });

    test('combat and gathering replace each other as the active activity', () {
      final state = GameState();

      expect(state.startGathering('copper'), isTrue);
      expect(state.startCombat('grave_rat'), isTrue);
      expect(state.activeGatheringSession, isNull);
      expect(state.activeCombatSession, isNotNull);

      expect(state.startGathering('copper'), isTrue);
      expect(state.activeCombatSession, isNull);
      expect(state.activeGatheringSession, isNotNull);
    });
  });

  group('Save migration', () {
    test('migrates legacy mining inventory, session and pickaxe upgrade', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final state = GameState.fromJson({
        'gold': 250,
        'skills': {
          'mining': {
            'id': 'mining',
            'name': 'Mining',
            'category': 0,
            'level': 5,
            'experience': 40,
            'experienceToNextLevel': 350,
          },
        },
        'miningInventory': {'copper': 12},
        'currentPickaxe': {'id': 'wooden', 'upgadeLevel': 4},
        'ownedPickaxes': [
          {'id': 'wooden', 'upgadeLevel': 1},
        ],
        'activeMiningSession': {
          'currentOreId': 'copper',
          'timeRemaining': 2,
          'startTime': now,
          'isActive': true,
        },
      });

      expect(state.gold, 250);
      expect(state.skills['mining']!.name, 'Mineração');
      expect(state.skills['mining']!.level, 5);
      expect(state.skills['mining']!.experience, 48.0);
      expect(state.skills['mining']!.experienceToNextLevel, 420);
      expect(state.gatheringInventory.quantityOf('copper'), 12);
      expect(state.ownedTool('pickaxe:wooden')?.upgradeLevel, 4);
      expect(state.tools.ownedById, hasLength(3));
      expect(
        state.tools.equippedId(GatheringDiscipline.mining),
        'pickaxe:wooden',
      );
      expect(state.activeGatheringSession!.resourceId, 'copper');
      expect(state.activeGatheringSession!.timeRemainingMilliseconds, 2000);
    });

    test('writes only the current gathering schema', () {
      final state = GameState()..startGathering('shrimp');

      final json = state.toJson();

      expect(json['schemaVersion'], GameState.schemaVersion);
      expect(json['gatheringInventory'], isA<Map<String, int>>());
      expect(json['activeGatheringSession'], isNotNull);
      final session = json['activeGatheringSession'] as Map<String, dynamic>;
      expect(session['cycleDurationMilliseconds'], 3000);
      expect(session['timeRemainingMilliseconds'], 3000);
      expect(session['toolId'], 'rod:basic');
      expect(session.containsKey('cycleDurationSeconds'), isFalse);
      expect(json.containsKey('activeMiningSession'), isFalse);
      expect(json.containsKey('miningInventory'), isFalse);
      expect(json.containsKey('currentPickaxe'), isFalse);
      expect(json['tools'], isA<Map<String, dynamic>>());
    });

    test('round-trips decimal XP without truncating it', () {
      final state = GameState();
      state.completeGatheringCycles('copper', 1);

      final encoded = jsonEncode(state.toJson());
      final restored = GameState.fromJson(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );

      expect(restored.skills['mining']!.experience, 5.6);
      expect(restored.skills['mining']!.experienceToNextLevel, 100);
    });

    test('round-trips an active combat hunt and wallet balance', () {
      final startedAt = DateTime(2026, 1, 1, 12);
      final state = GameState()..addGold(4321);
      expect(state.startCombat('grave_rat', at: startedAt), isTrue);
      state.activeCombatSession!.timeRemainingMilliseconds = 1750;

      final restored = GameState.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(state.toJson())) as Map,
        ),
      );

      expect(restored.gold, 4321);
      expect(restored.activeCombatSession?.encounterId, 'grave_rat');
      expect(restored.activeCombatSession?.timeRemainingMilliseconds, 1750);
      expect(
        restored.activeCombatSession?.lastProcessedAt,
        startedAt.millisecondsSinceEpoch,
      );
    });

    test('migrates legacy tin and replaces a newly locked session safely', () {
      final state = GameState.fromJson({
        'schemaVersion': 2,
        'skills': {
          'mining': {'level': 1, 'experience': 0, 'experienceToNextLevel': 100},
        },
        'gatheringInventory': {'tin': 3},
        'activeGatheringSession': {
          'resourceId': 'tin',
          'cycleDurationSeconds': 2,
          'timeRemainingSeconds': 1,
          'lastProcessedAt': 1000,
        },
      });

      expect(state.gatheringInventory.quantityOf('tin'), 0);
      expect(state.gatheringInventory.quantityOf('rune_essence'), 3);
      expect(state.activeGatheringSession?.resourceId, 'copper');
      expect(state.activeGatheringSession?.cycleDurationMilliseconds, 3000);
    });

    test('does not rerun XP migration for a schema three save', () {
      final state = GameState.fromJson({
        'schemaVersion': 3,
        'skills': {
          'mining': {
            'level': 5,
            'experience': 40.0,
            'experienceToNextLevel': 420,
          },
        },
        'gatheringInventory': {'rune_essence': 2},
      });

      expect(state.skills['mining']!.experience, 40.0);
      expect(state.gatheringInventory.quantityOf('rune_essence'), 2);
      expect(state.gatheringInventory.quantityOf('tin'), 0);
    });

    test('loads the legacy pickaxe key without losing progress', () {
      final state = GameState.fromJson({
        'currentPickaxe': {'id': 'wooden', 'upgadeLevel': 4},
        'ownedPickaxes': [
          {'id': 'wooden', 'upgadeLevel': 1},
        ],
      });

      expect(state.ownedTool('pickaxe:wooden')?.upgradeLevel, 4);
      expect(
        state.tools.equippedId(GatheringDiscipline.mining),
        'pickaxe:wooden',
      );
    });

    test('defaults audio settings for saves predating them', () {
      final state = GameState.fromJson({'gold': 10});

      expect(state.audioSettings.musicVolume, AudioSettings.defaultMusicVolume);
      expect(state.audioSettings.sfxVolume, AudioSettings.defaultSfxVolume);
      expect(state.audioSettings.muted, isFalse);
    });

    test('round-trips custom audio settings', () {
      final state = GameState()
        ..setMusicVolume(0.25)
        ..setSfxVolume(0.9)
        ..setAudioMuted(true);

      final restored = GameState.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(state.toJson())) as Map,
        ),
      );

      expect(restored.audioSettings.musicVolume, 0.25);
      expect(restored.audioSettings.sfxVolume, 0.9);
      expect(restored.audioSettings.muted, isTrue);
    });

    test('clamps audio volumes to the valid range', () {
      final state = GameState()
        ..setMusicVolume(-1)
        ..setSfxVolume(5);

      expect(state.audioSettings.musicVolume, 0.0);
      expect(state.audioSettings.sfxVolume, 1.0);
    });

    test('a brand new game has not seen onboarding yet', () {
      expect(GameState().hasSeenOnboarding, isFalse);
    });

    test('treats saves predating onboarding as already onboarded', () {
      final state = GameState.fromJson({'gold': 10});

      expect(state.hasSeenOnboarding, isTrue);
    });

    test('round-trips the onboarding flag once explicitly set', () {
      final state = GameState()..completeOnboarding();

      final restored = GameState.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(state.toJson())) as Map,
        ),
      );

      expect(restored.hasSeenOnboarding, isTrue);
    });

    test('honors an explicit false onboarding flag from a real save', () {
      final state = GameState.fromJson({
        'gold': 10,
        'hasSeenOnboarding': false,
      });

      expect(state.hasSeenOnboarding, isFalse);
    });
  });

  group('Gathering tools', () {
    test('small speed upgrades change cycle duration in milliseconds', () {
      final state = GameState();
      state.addGold(10);
      state.gatheringInventory.add('copper_bar', 20);

      expect(state.upgradeTool('pickaxe:wooden'), ToolActionResult.success);

      final copper = GatheringResource.byId('copper')!;
      expect(state.gatheringSpeedMultiplier(GatheringDiscipline.mining), 1.02);
      expect(state.gatheringCycleDurationMilliseconds(copper), 2942);
    });

    test('fractional yield accumulates deterministically across cycles', () {
      final state = GameState();
      state.ownedTool('pickaxe:wooden')!.upgradeLevel = 5;

      state.completeGatheringCycles('copper', 19);
      expect(state.gatheringInventory.quantityOf('copper'), 19);
      expect(state.gatheringYieldRemainders['mining'], closeTo(0.95, 1e-9));

      state.completeGatheringCycles('copper', 1);
      expect(state.gatheringInventory.quantityOf('copper'), 21);
      expect(state.gatheringYieldRemainders['mining'], closeTo(0, 1e-9));
    });

    test('round-trips tools, equipment and fractional yield', () {
      final state = GameState();
      state.skills['mining']!.level = 20;
      state.addGold(630);
      state.gatheringInventory.add('iron_bar', 72);
      expect(state.acquireTool('pickaxe:iron'), ToolActionResult.success);
      expect(state.upgradeTool('pickaxe:iron'), ToolActionResult.success);
      expect(state.equipTool('pickaxe:iron'), ToolActionResult.success);
      state.completeGatheringCycles('copper', 1);

      final restored = GameState.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(state.toJson())) as Map,
        ),
      );

      expect(restored.ownedTool('pickaxe:iron')?.upgradeLevel, 1);
      expect(
        restored.tools.equippedId(GatheringDiscipline.mining),
        'pickaxe:iron',
      );
      expect(restored.gatheringYieldRemainders['mining'], closeTo(0.06, 1e-9));
    });

    test('applies the same real bonuses to all gathering disciplines', () {
      final scenarios = [
        (
          discipline: GatheringDiscipline.mining,
          toolId: 'pickaxe:iron',
          resourceId: 'copper',
        ),
        (
          discipline: GatheringDiscipline.woodcutting,
          toolId: 'axe:iron',
          resourceId: 'normal_log',
        ),
        (
          discipline: GatheringDiscipline.fishing,
          toolId: 'rod:reinforced',
          resourceId: 'shrimp',
        ),
      ];

      for (final scenario in scenarios) {
        final state = GameState();
        state.tools.ownedById[scenario.toolId] = OwnedTool(
          toolId: scenario.toolId,
        );
        expect(state.equipTool(scenario.toolId), ToolActionResult.success);
        final resource = GatheringResource.byId(scenario.resourceId)!;

        expect(state.gatheringSpeedMultiplier(scenario.discipline), 1.10);
        expect(state.gatheringYieldMultiplier(scenario.discipline), 1.05);
        expect(state.gatheringCycleDurationMilliseconds(resource), 2728);

        state.completeGatheringCycles(scenario.resourceId, 20);
        expect(state.gatheringInventory.quantityOf(scenario.resourceId), 21);
      }
    });
  });
}
