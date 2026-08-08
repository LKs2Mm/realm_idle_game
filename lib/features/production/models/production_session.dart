import 'package:realm_idle_game/core/utils/offline_progress_policy.dart';

enum ProductionKind {
  equipment,
  spell,
  potion,
  smelting,
  arcaneRefining,
  cooking,
  woodworking,
}

enum ProductionStartResult {
  success,
  unknownRecipe,
  productionBusy,
  levelRequired,
  insufficientGold,
  insufficientResources,
  alreadyOwned,
  invalidQuantity,
}

extension ProductionKindDetails on ProductionKind {
  String get saveKey => switch (this) {
    ProductionKind.equipment => 'equipment',
    ProductionKind.spell => 'spell',
    ProductionKind.potion => 'potion',
    ProductionKind.smelting => 'smelting',
    ProductionKind.arcaneRefining => 'arcane_refining',
    ProductionKind.cooking => 'cooking',
    ProductionKind.woodworking => 'woodworking',
  };

  String get displayName => switch (this) {
    ProductionKind.equipment => 'Equipamento',
    ProductionKind.spell => 'Magia',
    ProductionKind.potion => 'Poção',
    ProductionKind.smelting => 'Fundíção',
    ProductionKind.arcaneRefining => 'Consagração Arcana',
    ProductionKind.cooking => 'Culinária',
    ProductionKind.woodworking => 'Marcenaria',
  };

  static ProductionKind? fromSaveKey(Object? value) {
    if (value is! String) return null;
    for (final kind in ProductionKind.values) {
      if (kind.saveKey == value) return kind;
    }
    return null;
  }
}

class ProductionReward {
  final ProductionKind kind;
  final String recipeId;
  final int quantity;
  final String skillId;
  final double experience;

  const ProductionReward({
    required this.kind,
    required this.recipeId,
    required this.quantity,
    required this.skillId,
    required this.experience,
  });
}

class ProductionSession {
  final ProductionKind kind;
  final String recipeId;
  final String displayName;
  final int quantity;
  final int durationMilliseconds;
  int timeRemainingMilliseconds;
  int lastProcessedAt;
  final int goldCost;
  final Map<String, int> resourceCost;
  final String skillId;
  final double experience;

  ProductionSession({
    required this.kind,
    required this.recipeId,
    required this.displayName,
    required this.quantity,
    required this.durationMilliseconds,
    required this.timeRemainingMilliseconds,
    required this.lastProcessedAt,
    required this.goldCost,
    required Map<String, int> resourceCost,
    required this.skillId,
    required this.experience,
  }) : resourceCost = Map.unmodifiable(resourceCost);

  double get progress {
    if (durationMilliseconds <= 0) return 0;
    return (1 - (timeRemainingMilliseconds / durationMilliseconds)).clamp(
      0.0,
      1.0,
    );
  }

  int elapsedMillisecondsAt(DateTime timestamp) {
    final elapsed = timestamp.millisecondsSinceEpoch - lastProcessedAt;
    if (elapsed <= 0) return 0;
    return elapsed.clamp(0, OfflineProgressPolicy.maxElapsedMilliseconds);
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.saveKey,
    'recipeId': recipeId,
    'displayName': displayName,
    'quantity': quantity,
    'durationMilliseconds': durationMilliseconds,
    'timeRemainingMilliseconds': timeRemainingMilliseconds,
    'lastProcessedAt': lastProcessedAt,
    'goldCost': goldCost,
    'resourceCost': resourceCost,
    'skillId': skillId,
    'experience': experience,
  };

  factory ProductionSession.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Invalid production session');
    }
    final kind = ProductionKindDetails.fromSaveKey(json['kind']);
    final recipeId = json['recipeId'];
    final displayName = json['displayName'];
    final skillId = json['skillId'];
    final quantity = _safeInt(json['quantity'], minimum: 1, maximum: 100);
    final duration = _safeInt(
      json['durationMilliseconds'],
      minimum: 1,
      maximum: 604800000,
    );
    final remaining = _safeInt(
      json['timeRemainingMilliseconds'],
      minimum: 1,
      maximum: duration,
    );
    final lastProcessedAt = _safeInt(
      json['lastProcessedAt'],
      minimum: 0,
      maximum: 8640000000000000,
    );
    final goldCost = _safeInt(
      json['goldCost'],
      minimum: 0,
      maximum: 9000000000000000,
    );
    final experience = _safeDouble(json['experience'], minimum: 0);
    if (kind == null ||
        recipeId is! String ||
        recipeId.isEmpty ||
        displayName is! String ||
        displayName.isEmpty ||
        skillId is! String ||
        skillId.isEmpty) {
      throw const FormatException('Incomplete production session');
    }

    final resourceCost = <String, int>{};
    final rawCost = json['resourceCost'];
    if (rawCost is Map) {
      for (final entry in rawCost.entries) {
        if (entry.key is String && entry.value is num) {
          final amount = (entry.value as num).toInt();
          if (amount > 0) resourceCost[entry.key as String] = amount;
        }
      }
    }
    return ProductionSession(
      kind: kind,
      recipeId: recipeId,
      displayName: displayName,
      quantity: quantity,
      durationMilliseconds: duration,
      timeRemainingMilliseconds: remaining,
      lastProcessedAt: lastProcessedAt,
      goldCost: goldCost,
      resourceCost: resourceCost,
      skillId: skillId,
      experience: experience,
    );
  }

  static int _safeInt(
    Object? value, {
    required int minimum,
    required int maximum,
  }) {
    if (value is! num || !value.isFinite) {
      throw const FormatException('Invalid integer in production session');
    }
    return value.toInt().clamp(minimum, maximum);
  }

  static double _safeDouble(Object? value, {required double minimum}) {
    if (value is! num || !value.isFinite) {
      throw const FormatException('Invalid decimal in production session');
    }
    return value.toDouble() < minimum ? minimum : value.toDouble();
  }
}
