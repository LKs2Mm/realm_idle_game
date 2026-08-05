import 'dart:async';

import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_session.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';

typedef GatheringUpdateCallback =
    void Function(GameState state, bool shouldSave);

class GatheringAdvanceResult {
  int elapsedMilliseconds = 0;
  int completedCycles = 0;
  final Map<String, int> collectedResources = {};
  final Map<String, double> experienceBySkill = {};

  bool get hasRewards => completedCycles > 0;
  int get totalItems => collectedResources.values.fold(0, (a, b) => a + b);
  double get totalExperience =>
      experienceBySkill.values.fold<double>(0, (sum, value) => sum + value);

  void addReward(GatheringReward? reward) {
    if (reward == null) return;
    completedCycles += reward.cycles;
    collectedResources.update(
      reward.resourceId,
      (quantity) => quantity + reward.quantity,
      ifAbsent: () => reward.quantity,
    );
    experienceBySkill.update(
      reward.skillId,
      (experience) => Skill.normalizeExperience(experience + reward.experience),
      ifAbsent: () => reward.experience,
    );
  }
}

class GatheringService {
  static const Duration _updateInterval = Duration(milliseconds: 200);

  final GatheringUpdateCallback onUpdate;
  final DateTime Function() now;
  final bool enableTimer;

  Timer? _timer;
  GameState? _gameState;

  GatheringService({
    required this.onUpdate,
    DateTime Function()? now,
    this.enableTimer = true,
  }) : now = now ?? DateTime.now;

  GameState get gameState {
    final state = _gameState;
    if (state == null) throw StateError('GatheringService is not initialized');
    return state;
  }

  GatheringAdvanceResult initialize(GameState state) {
    _gameState = state;
    final result = advanceTo(now(), notify: false);
    _ensureTimer();
    return result;
  }

  void selectResource(String resourceId) {
    final elapsedResult = advanceTo(now(), notify: false);
    final resource = GatheringResource.byId(resourceId);
    if (resource == null || !gameState.canGather(resource)) {
      if (elapsedResult.hasRewards) onUpdate(gameState, true);
      return;
    }

    final session = gameState.activeGatheringSession;
    var selectionChanged = false;
    if (session == null) {
      selectionChanged = gameState.startGathering(resource.id, at: now());
    } else if (session.resourceId != resource.id &&
        session.queuedResourceId != resource.id) {
      session.queuedResourceId = resource.id;
      selectionChanged = true;
    }

    _ensureTimer();
    if (selectionChanged || elapsedResult.hasRewards) {
      onUpdate(gameState, true);
    }
  }

  void stop() {
    advanceTo(now(), notify: false);
    if (gameState.activeGatheringSession == null) return;

    gameState.stopGathering();
    _timer?.cancel();
    onUpdate(gameState, true);
  }

  GatheringAdvanceResult advanceTo(DateTime timestamp, {bool notify = true}) {
    final result = GatheringAdvanceResult();
    final session = gameState.activeGatheringSession;
    if (session == null) {
      _timer?.cancel();
      return result;
    }

    final activeResource = GatheringResource.byId(session.resourceId);
    if (activeResource == null) {
      gameState.stopGathering();
      _timer?.cancel();
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
    result.addReward(
      gameState.completeGatheringCycles(
        activeResource.id,
        1,
        toolId: session.toolId,
        yieldMultiplier: session.yieldMultiplier,
        at: timestamp,
      ),
    );

    final nextResource = _nextResourceAfter(session, activeResource);
    final nextDuration = gameState.gatheringCycleDurationMilliseconds(
      nextResource,
      at: timestamp,
    );
    final nextTool = gameState.equippedToolDefinition(nextResource.discipline);
    final nextYieldMultiplier = gameState.gatheringYieldMultiplier(
      nextResource.discipline,
      at: timestamp,
    );
    final additionalCycles = remainingElapsed ~/ nextDuration;
    if (additionalCycles > 0) {
      result.addReward(
        gameState.completeGatheringCycles(
          nextResource.id,
          additionalCycles,
          toolId: nextTool.id,
          yieldMultiplier: nextYieldMultiplier,
          at: timestamp,
        ),
      );
      remainingElapsed %= nextDuration;
    }

    gameState.activeGatheringSession = GatheringSession(
      resourceId: nextResource.id,
      cycleDurationMilliseconds: nextDuration,
      timeRemainingMilliseconds: nextDuration - remainingElapsed,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
      toolId: nextTool.id,
      yieldMultiplier: nextYieldMultiplier,
    );

    if (notify) onUpdate(gameState, true);
    return result;
  }

  GatheringResource _nextResourceAfter(
    GatheringSession session,
    GatheringResource fallback,
  ) {
    final queuedId = session.queuedResourceId;
    if (queuedId == null) return fallback;

    final queuedResource = GatheringResource.byId(queuedId);
    if (queuedResource == null || !gameState.canGather(queuedResource)) {
      return fallback;
    }
    return queuedResource;
  }

  void _ensureTimer() {
    if (!enableTimer || gameState.activeGatheringSession == null) return;
    if (_timer?.isActive ?? false) return;

    _timer = Timer.periodic(_updateInterval, (_) => advanceTo(now()));
  }

  void dispose() {
    _timer?.cancel();
  }
}
