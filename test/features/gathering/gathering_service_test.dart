import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/gathering/services/gathering_service.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';

void main() {
  late DateTime currentTime;
  late GameState state;
  late GatheringService service;

  setUp(() {
    currentTime = DateTime(2026, 1, 1, 12);
    state = GameState();
    service = GatheringService(
      onUpdate: (_, _) {},
      now: () => currentTime,
      enableTimer: false,
    );
    service.initialize(state);
  });

  tearDown(() => service.dispose());

  test('selection starts one continuous activity without granting XP', () {
    service.selectResource('copper');

    expect(state.activeGatheringSession!.resourceId, 'copper');
    expect(state.skills['mining']!.experience, 0);
    expect(state.gatheringInventory.quantityOf('copper'), 0);
  });

  test('offline progress completes cycles in a single batch', () {
    service.selectResource('copper');
    currentTime = currentTime.add(const Duration(seconds: 7));

    final result = service.advanceTo(currentTime);

    expect(result.completedCycles, 2);
    expect(result.collectedResources, {'copper': 2});
    expect(result.totalExperience, closeTo(11.2, 0.0001));
    expect(state.gatheringInventory.quantityOf('copper'), 2);
    expect(state.skills['mining']!.experience, closeTo(11.2, 0.0001));
    expect(state.activeGatheringSession!.timeRemainingMilliseconds, 2000);
  });

  test('batches decimal XP from rune essence without precision loss', () {
    final mining = state.skills['mining']!;
    mining.level = 10;
    mining.experienceToNextLevel = Skill.experienceRequiredForLevel(10);
    service.selectResource('rune_essence');
    currentTime = currentTime.add(const Duration(seconds: 3));

    final result = service.advanceTo(currentTime);

    expect(result.completedCycles, 3);
    expect(result.collectedResources, {'rune_essence': 3});
    expect(result.experienceBySkill['mining'], closeTo(3.9, 0.0001));
    expect(result.totalExperience, closeTo(3.9, 0.0001));
    expect(mining.experience, 3.9);
  });

  test('a new selection is queued and starts after the current cycle', () {
    service.selectResource('copper');
    currentTime = currentTime.add(const Duration(seconds: 1));
    service.selectResource('normal_log');

    expect(state.activeGatheringSession!.resourceId, 'copper');
    expect(state.activeGatheringSession!.queuedResourceId, 'normal_log');

    currentTime = currentTime.add(const Duration(seconds: 6));
    service.advanceTo(currentTime);

    expect(state.gatheringInventory.quantityOf('copper'), 1);
    expect(state.gatheringInventory.quantityOf('normal_log'), 1);
    expect(state.activeGatheringSession!.resourceId, 'normal_log');
    expect(state.activeGatheringSession!.timeRemainingMilliseconds, 2000);
  });

  test('selecting the active resource again does not restart it', () {
    service.selectResource('copper');
    currentTime = currentTime.add(const Duration(seconds: 1));
    service.advanceTo(currentTime);
    final remaining = state.activeGatheringSession!.timeRemainingMilliseconds;

    service.selectResource('copper');

    expect(state.activeGatheringSession!.timeRemainingMilliseconds, remaining);
    expect(state.skills['mining']!.experience, 0);
  });

  test('tool changes apply only after the current cycle', () {
    service.selectResource('copper');
    final session = state.activeGatheringSession!;
    expect(session.cycleDurationMilliseconds, 3000);
    expect(session.yieldMultiplier, 1.0);

    state.ownedTool('pickaxe:wooden')!.upgradeLevel = 5;
    currentTime = currentTime.add(const Duration(seconds: 3));
    service.advanceTo(currentTime);

    expect(state.gatheringInventory.quantityOf('copper'), 1);
    expect(state.gatheringYieldRemainders['mining'] ?? 0, 0);
    expect(state.activeGatheringSession!.cycleDurationMilliseconds, 2728);
    expect(state.activeGatheringSession!.yieldMultiplier, 1.05);
  });

  test('many offline cycles do not require a cycle-by-cycle timer', () {
    service.selectResource('shrimp');
    currentTime = currentTime.add(const Duration(hours: 12));

    final result = service.advanceTo(currentTime);

    expect(result.completedCycles, 14400);
    expect(state.gatheringInventory.quantityOf('shrimp'), 14400);
    expect(state.activeGatheringSession!.resourceId, 'shrimp');
  });

  test('clock moving backwards never generates rewards', () {
    service.selectResource('copper');
    currentTime = currentTime.subtract(const Duration(minutes: 10));

    final result = service.advanceTo(currentTime);

    expect(result.hasRewards, isFalse);
    expect(state.gatheringInventory.totalCount, 0);
  });
}
