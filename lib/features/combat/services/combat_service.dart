import 'dart:async';

import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/features/combat/models/combat_session.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';

typedef CombatUpdateCallback = void Function(GameState state, bool shouldSave);

class CombatAdvanceResult {
  int elapsedMilliseconds = 0;
  int completedVictories = 0;
  int goldEarned = 0;
  int damageTaken = 0;
  double experienceEarned = 0;
  bool wasDefeated = false;
  bool sessionEnded = false;
  final Map<String, int> victoriesByEncounter = {};
  final Map<String, int> lootEarned = {};

  bool get hasRewards =>
      completedVictories > 0 || damageTaken > 0 || wasDefeated;

  bool get shouldSave => hasRewards || sessionEnded;

  void addReward(CombatReward? reward) {
    if (reward == null) return;

    if (reward.damageTaken > 0) damageTaken += reward.damageTaken;
    wasDefeated = wasDefeated || reward.wasDefeated;
    if (reward.victories <= 0) return;

    completedVictories += reward.victories;
    goldEarned += reward.gold;
    experienceEarned = Skill.normalizeExperience(
      experienceEarned + reward.experience,
    );
    victoriesByEncounter.update(
      reward.encounterId,
      (victories) => victories + reward.victories,
      ifAbsent: () => reward.victories,
    );
    for (final entry in reward.loot.entries) {
      lootEarned.update(
        entry.key,
        (quantity) => quantity + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }
}

class CombatService {
  static const Duration _updateInterval = Duration(milliseconds: 200);

  final CombatUpdateCallback onUpdate;
  final DateTime Function() now;
  final bool enableTimer;

  Timer? _timer;
  GameState? _gameState;

  CombatService({
    required this.onUpdate,
    DateTime Function()? now,
    this.enableTimer = true,
  }) : now = now ?? DateTime.now;

  GameState get gameState {
    final state = _gameState;
    if (state == null) throw StateError('CombatService is not initialized');
    return state;
  }

  CombatAdvanceResult initialize(GameState state) {
    _gameState = state;
    final result = advanceTo(now(), notify: false);
    _ensureTimer();
    return result;
  }

  void selectEncounter(String encounterId) {
    final timestamp = now();
    final elapsedResult = advanceTo(timestamp, notify: false);
    final encounter = CombatEncounter.byId(encounterId);
    if (gameState.isDefeated ||
        encounter == null ||
        !gameState.canFight(encounter)) {
      if (elapsedResult.shouldSave) onUpdate(gameState, true);
      return;
    }

    final session = gameState.activeCombatSession;
    var selectionChanged = false;
    if (session == null) {
      selectionChanged = gameState.startCombat(encounter.id, at: timestamp);
    } else if (session.encounterId != encounter.id &&
        session.queuedEncounterId != encounter.id) {
      session.queuedEncounterId = encounter.id;
      selectionChanged = true;
    }

    _ensureTimer();
    if (selectionChanged || elapsedResult.shouldSave) {
      onUpdate(gameState, true);
    }
  }

  void stop() {
    final elapsedResult = advanceTo(now(), notify: false);
    if (gameState.activeCombatSession == null) {
      if (elapsedResult.shouldSave) onUpdate(gameState, true);
      return;
    }

    gameState.stopCombat();
    elapsedResult.sessionEnded = true;
    _timer?.cancel();
    onUpdate(gameState, true);
  }

  CombatAdvanceResult advanceTo(DateTime timestamp, {bool notify = true}) {
    final result = CombatAdvanceResult();
    final session = gameState.activeCombatSession;
    if (session == null) {
      _timer?.cancel();
      return result;
    }

    if (gameState.isDefeated) {
      _endSession(result);
      if (notify) onUpdate(gameState, true);
      return result;
    }

    final activeEncounter = CombatEncounter.byId(session.encounterId);
    if (activeEncounter == null) {
      _endSession(result);
      if (notify) onUpdate(gameState, true);
      return result;
    }

    final elapsedMilliseconds = session.elapsedMillisecondsAt(timestamp);
    result.elapsedMilliseconds = elapsedMilliseconds;
    if (elapsedMilliseconds <= 0) return result;

    session.lastProcessedAt = timestamp.millisecondsSinceEpoch;
    if (elapsedMilliseconds < session.timeRemainingMilliseconds) {
      session.timeRemainingMilliseconds -= elapsedMilliseconds;
      return result;
    }

    var remainingElapsed =
        elapsedMilliseconds - session.timeRemainingMilliseconds;
    final firstReward = gameState.completeCombatVictories(
      activeEncounter.id,
      1,
      at: timestamp,
    );
    result.addReward(firstReward);
    _maybeAutoEat();

    // A rejected cycle or a fatal victory must never be converted into more
    // offline victories. GameState is authoritative about the real result.
    if ((firstReward?.victories ?? 0) < 1 ||
        firstReward!.wasDefeated ||
        gameState.isDefeated) {
      _endSession(result);
      if (notify) onUpdate(gameState, true);
      return result;
    }

    final nextEncounter = _nextEncounterAfter(session, activeEncounter);
    final nextDuration = gameState.combatCycleDurationMilliseconds(
      nextEncounter,
      at: timestamp,
    );
    final requestedAdditionalVictories = remainingElapsed ~/ nextDuration;
    if (requestedAdditionalVictories > 0) {
      final additionalReward = gameState.completeCombatVictories(
        nextEncounter.id,
        requestedAdditionalVictories,
        at: timestamp,
      );
      result.addReward(additionalReward);
      _maybeAutoEat();

      final actualAdditionalVictories = additionalReward?.victories ?? 0;
      final batchWasInterrupted =
          actualAdditionalVictories < requestedAdditionalVictories;
      if (batchWasInterrupted ||
          (additionalReward?.wasDefeated ?? false) ||
          gameState.isDefeated) {
        _endSession(result);
        if (notify) onUpdate(gameState, true);
        return result;
      }

      remainingElapsed -= actualAdditionalVictories * nextDuration;
    }

    gameState.activeCombatSession = CombatSession(
      encounterId: nextEncounter.id,
      cycleDurationMilliseconds: nextDuration,
      timeRemainingMilliseconds: nextDuration - remainingElapsed,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
    );

    if (notify) onUpdate(gameState, true);
    return result;
  }

  void _maybeAutoEat() {
    final settings = gameState.autoEatSettings;
    if (!settings.enabled || gameState.isDefeated) return;

    final maxHealth = gameState.maxHealth;
    if (maxHealth <= 0) return;
    final healthPercent = gameState.currentHealth * 100 ~/ maxHealth;
    if (healthPercent >= settings.thresholdPercent) return;

    final foodId = gameState.bestOwnedFoodId;
    if (foodId == null) return;
    gameState.consumeCookedFish(foodId);
  }

  void _endSession(CombatAdvanceResult result) {
    if (gameState.activeCombatSession != null) gameState.stopCombat();
    result.sessionEnded = true;
    result.wasDefeated = result.wasDefeated || gameState.isDefeated;
    _timer?.cancel();
  }

  CombatEncounter _nextEncounterAfter(
    CombatSession session,
    CombatEncounter fallback,
  ) {
    final queuedId = session.queuedEncounterId;
    if (queuedId == null) return fallback;

    final queuedEncounter = CombatEncounter.byId(queuedId);
    if (queuedEncounter == null || !gameState.canFight(queuedEncounter)) {
      return fallback;
    }
    return queuedEncounter;
  }

  void _ensureTimer() {
    if (!enableTimer ||
        gameState.isDefeated ||
        gameState.activeCombatSession == null) {
      return;
    }
    if (_timer?.isActive ?? false) return;
    _timer = Timer.periodic(_updateInterval, (_) => advanceTo(now()));
  }

  void dispose() {
    _timer?.cancel();
  }
}
