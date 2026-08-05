import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';

enum ToolKind { pickaxe, axe, fishingRod }

extension ToolKindDetails on ToolKind {
  GatheringDiscipline get discipline => switch (this) {
    ToolKind.pickaxe => GatheringDiscipline.mining,
    ToolKind.axe => GatheringDiscipline.woodcutting,
    ToolKind.fishingRod => GatheringDiscipline.fishing,
  };

  String get saveKey => switch (this) {
    ToolKind.pickaxe => 'pickaxe',
    ToolKind.axe => 'axe',
    ToolKind.fishingRod => 'fishingRod',
  };
}

class ToolCost {
  final int gold;
  final Map<String, int> resources;

  const ToolCost({this.gold = 0, this.resources = const {}});

  bool get isFree => gold <= 0 && resources.values.every((value) => value <= 0);
}

class ToolDefinition {
  final String id;
  final ToolKind kind;
  final String name;
  final String description;
  final int tier;
  final int requiredSkillLevel;
  final ToolCost purchaseCost;
  final double baseSpeedMultiplier;
  final double baseYieldMultiplier;
  final double speedPerUpgrade;
  final double yieldPerUpgrade;
  final int maxUpgradeLevel;
  final String upgradeMaterialId;
  final int upgradeBaseAmount;
  final int upgradeGoldBase;

  const ToolDefinition({
    required this.id,
    required this.kind,
    required this.name,
    required this.description,
    required this.tier,
    required this.requiredSkillLevel,
    required this.purchaseCost,
    required this.baseSpeedMultiplier,
    required this.baseYieldMultiplier,
    required this.upgradeMaterialId,
    required this.upgradeBaseAmount,
    required this.upgradeGoldBase,
    this.speedPerUpgrade = 0.02,
    this.yieldPerUpgrade = 0.01,
    this.maxUpgradeLevel = 5,
  });

  GatheringDiscipline get discipline => kind.discipline;
  bool get isStarter => tier == 0;

  double speedForUpgrade(int upgradeLevel) {
    final level = upgradeLevel.clamp(0, maxUpgradeLevel);
    return baseSpeedMultiplier + (speedPerUpgrade * level);
  }

  double yieldForUpgrade(int upgradeLevel) {
    final level = upgradeLevel.clamp(0, maxUpgradeLevel);
    return baseYieldMultiplier + (yieldPerUpgrade * level);
  }

  ToolCost? upgradeCostFor(int currentUpgradeLevel) {
    if (currentUpgradeLevel < 0 || currentUpgradeLevel >= maxUpgradeLevel) {
      return null;
    }
    return ToolCost(
      gold: upgradeGoldBase * (currentUpgradeLevel + 1),
      resources: {
        upgradeMaterialId: upgradeBaseAmount * (currentUpgradeLevel + 1),
      },
    );
  }
}

class OwnedTool {
  final String toolId;
  int upgradeLevel;

  OwnedTool({required this.toolId, this.upgradeLevel = 0});

  Map<String, dynamic> toJson() => {'upgradeLevel': upgradeLevel};

  factory OwnedTool.fromJson(String toolId, Object? json) {
    if (json is! Map) return OwnedTool(toolId: toolId);
    final rawUpgradeLevel = json['upgradeLevel'] ?? json['upgadeLevel'];
    final upgradeLevel = rawUpgradeLevel is num && rawUpgradeLevel.isFinite
        ? rawUpgradeLevel.toInt().clamp(0, 5)
        : 0;
    return OwnedTool(toolId: toolId, upgradeLevel: upgradeLevel);
  }
}

class ToolCollection {
  final Map<String, OwnedTool> ownedById;
  final Map<GatheringDiscipline, String> equippedByDiscipline;

  ToolCollection({
    Map<String, OwnedTool>? ownedById,
    Map<GatheringDiscipline, String>? equippedByDiscipline,
  }) : ownedById = ownedById ?? {},
       equippedByDiscipline = equippedByDiscipline ?? {};

  OwnedTool? ownedTool(String toolId) => ownedById[toolId];

  String? equippedId(GatheringDiscipline discipline) {
    return equippedByDiscipline[discipline];
  }

  Map<String, dynamic> toJson() => {
    'owned': ownedById.map(
      (toolId, ownedTool) => MapEntry(toolId, ownedTool.toJson()),
    ),
    'equipped': equippedByDiscipline.map(
      (discipline, toolId) => MapEntry(discipline.skillId, toolId),
    ),
  };

  factory ToolCollection.fromJson(Object? json) {
    if (json is! Map) return ToolCollection();

    final owned = <String, OwnedTool>{};
    final ownedJson = json['owned'];
    if (ownedJson is Map) {
      for (final entry in ownedJson.entries) {
        if (entry.key is! String) continue;
        final toolId = entry.key as String;
        owned[toolId] = OwnedTool.fromJson(toolId, entry.value);
      }
    }

    final equipped = <GatheringDiscipline, String>{};
    final equippedJson = json['equipped'];
    if (equippedJson is Map) {
      for (final discipline in GatheringDiscipline.values) {
        final toolId = equippedJson[discipline.skillId];
        if (toolId is String) equipped[discipline] = toolId;
      }
    }

    return ToolCollection(ownedById: owned, equippedByDiscipline: equipped);
  }
}

enum ToolActionResult {
  success,
  unknownTool,
  alreadyOwned,
  notOwned,
  skillLevelRequired,
  insufficientGold,
  insufficientResources,
  maxUpgradeReached,
  wrongDiscipline,
}
