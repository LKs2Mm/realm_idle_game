import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/processing/data/smelting_recipe_catalog.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/features/production/services/production_service.dart';
import 'package:realm_idle_game/models/game_state.dart';

void main() {
  late DateTime currentTime;
  late GameState state;
  late ProductionService service;
  late List<bool> saveRequests;
  final recipe = SmeltingRecipeCatalog.all.first;

  void addBatches(int batches) {
    for (final entry in recipe.cost.multipliedBy(batches).entries) {
      state.gatheringInventory.add(entry.key, entry.value);
    }
  }

  setUp(() {
    currentTime = DateTime(2026, 1, 1, 12);
    state = GameState();
    state.skills[recipe.skillId]!.level = recipe.requiredLevel + 5;
    saveRequests = [];
    service = ProductionService(
      onUpdate: (_, shouldSave) => saveRequests.add(shouldSave),
      now: () => currentTime,
      enableTimer: false,
    );
  });

  tearDown(() => service.dispose());

  test('produção contínua reinicia a mesma receita enquanto há material', () {
    addBatches(2);
    expect(
      state.startProcessing(recipe.id, at: currentTime, repeat: true),
      ProductionStartResult.success,
    );
    service.initialize(state);

    currentTime = currentTime.add(
      Duration(milliseconds: recipe.durationMilliseconds),
    );
    final result = service.advanceTo(currentTime);

    expect(result.hasReward, isTrue);
    expect(result.reward!.recipeId, recipe.id);
    expect(result.repeated, isTrue);
    expect(result.repeatStoppedForResources, isFalse);
    expect(state.activeProductionSession, isNotNull);
    expect(state.activeProductionSession!.recipeId, recipe.id);
    expect(state.activeProductionSession!.repeatWhenDone, isTrue);
    expect(
      state.activeProductionSession!.timeRemainingMilliseconds,
      recipe.durationMilliseconds,
    );
    for (final entry in recipe.cost.materials.entries) {
      expect(state.gatheringInventory.quantityOf(entry.key), 0);
    }
  });

  test('produção contínua para sozinha quando o material acaba', () {
    addBatches(1);
    expect(
      state.startProcessing(recipe.id, at: currentTime, repeat: true),
      ProductionStartResult.success,
    );
    service.initialize(state);

    currentTime = currentTime.add(
      Duration(milliseconds: recipe.durationMilliseconds),
    );
    final result = service.advanceTo(currentTime);

    expect(result.hasReward, isTrue);
    expect(result.repeated, isFalse);
    expect(result.repeatStoppedForResources, isTrue);
    expect(state.activeProductionSession, isNull);
  });

  test('um lote comum nunca reinicia sozinho quando repeat está desligado', () {
    addBatches(2);
    expect(
      state.startProcessing(recipe.id, at: currentTime),
      ProductionStartResult.success,
    );
    service.initialize(state);

    currentTime = currentTime.add(
      Duration(milliseconds: recipe.durationMilliseconds),
    );
    final result = service.advanceTo(currentTime);

    expect(result.hasReward, isTrue);
    expect(result.repeated, isFalse);
    expect(result.repeatStoppedForResources, isFalse);
    expect(state.activeProductionSession, isNull);
    for (final entry in recipe.cost.materials.entries) {
      expect(state.gatheringInventory.quantityOf(entry.key), entry.value);
    }
  });
}
