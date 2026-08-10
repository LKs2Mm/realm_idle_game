import 'dart:async';

import 'package:realm_idle_game/features/processing/data/processing_recipe_catalog.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/models/game_state.dart';

typedef ProductionUpdateCallback =
    void Function(GameState state, bool shouldSave);

class ProductionAdvanceResult {
  int elapsedMilliseconds = 0;
  ProductionReward? reward;
  bool repeated = false;
  bool repeatStoppedForResources = false;

  bool get hasReward => reward != null;
}

class ProductionService {
  static const Duration _updateInterval = Duration(milliseconds: 200);

  final ProductionUpdateCallback onUpdate;
  final DateTime Function() now;
  final bool enableTimer;

  Timer? _timer;
  GameState? _gameState;

  ProductionService({
    required this.onUpdate,
    DateTime Function()? now,
    this.enableTimer = true,
  }) : now = now ?? DateTime.now;

  GameState get gameState {
    final state = _gameState;
    if (state == null) throw StateError('ProductionService is not initialized');
    return state;
  }

  ProductionAdvanceResult initialize(GameState state) {
    _gameState = state;
    final result = advanceTo(now(), notify: false);
    _ensureTimer();
    return result;
  }

  void notifyProductionStarted() {
    _ensureTimer();
    onUpdate(gameState, true);
  }

  void cancel() {
    final elapsedResult = advanceTo(now(), notify: false);
    if (gameState.activeProductionSession == null) {
      if (elapsedResult.hasReward) onUpdate(gameState, true);
      return;
    }
    gameState.cancelProduction(refund: true);
    _timer?.cancel();
    onUpdate(gameState, true);
  }

  ProductionAdvanceResult advanceTo(DateTime timestamp, {bool notify = true}) {
    final result = ProductionAdvanceResult();
    final session = gameState.activeProductionSession;
    if (session == null) {
      _timer?.cancel();
      return result;
    }

    final elapsed = session.elapsedMillisecondsAt(timestamp);
    result.elapsedMilliseconds = elapsed;
    if (elapsed <= 0) return result;
    session.lastProcessedAt = timestamp.millisecondsSinceEpoch;

    if (elapsed < session.timeRemainingMilliseconds) {
      session.timeRemainingMilliseconds -= elapsed;
      if (notify) onUpdate(gameState, false);
      return result;
    }

    final repeatWhenDone = session.repeatWhenDone;
    result.reward = gameState.completeProduction(at: timestamp);
    final reward = result.reward;

    if (reward != null && repeatWhenDone) {
      result.repeated = _tryRestart(reward, timestamp);
      result.repeatStoppedForResources = !result.repeated;
    }

    if (gameState.activeProductionSession == null) {
      _timer?.cancel();
    } else {
      _ensureTimer();
    }
    if (notify) onUpdate(gameState, true);
    return result;
  }

  /// Tenta reiniciar a mesma receita/quantidade que acabou de concluir,
  /// pra "produção contínua". Não tenta recuperar tempo offline perdido —
  /// só reinicia um lote novo, do zero, a partir de [timestamp] — mesmo
  /// comportamento que a produção já tinha antes de sobras de tempo
  /// ociosas serem descartadas em uma pausa longa.
  bool _tryRestart(ProductionReward reward, DateTime timestamp) {
    final recipe = ProcessingRecipeCatalog.byId(reward.recipeId);
    if (recipe == null) return false;

    final hasLevel =
        (gameState.skills[recipe.skillId]?.level ?? 1) >= recipe.requiredLevel;
    final canAfford = recipe.cost.canAfford(
      gameState.gatheringInventory.resources,
      batches: reward.quantity,
    );
    if (!hasLevel || !canAfford) return false;

    final startResult = gameState.startProcessing(
      reward.recipeId,
      quantity: reward.quantity,
      at: timestamp,
      repeat: true,
    );
    return startResult == ProductionStartResult.success;
  }

  void _ensureTimer() {
    if (!enableTimer || gameState.activeProductionSession == null) return;
    if (_timer?.isActive ?? false) return;
    _timer = Timer.periodic(_updateInterval, (_) => advanceTo(now()));
  }

  void dispose() {
    _timer?.cancel();
  }
}
