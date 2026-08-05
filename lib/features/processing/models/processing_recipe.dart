import 'dart:collection';

import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';

enum ProcessingKind { smelting, arcaneRefining, cooking, woodworking }

extension ProcessingKindDetails on ProcessingKind {
  String get saveKey => switch (this) {
    ProcessingKind.smelting => 'smelting',
    ProcessingKind.arcaneRefining => 'arcane_refining',
    ProcessingKind.cooking => 'cooking',
    ProcessingKind.woodworking => 'woodworking',
  };

  String get displayName => switch (this) {
    ProcessingKind.smelting => 'Fundição',
    ProcessingKind.arcaneRefining => 'Consagração',
    ProcessingKind.cooking => 'Culinária',
    ProcessingKind.woodworking => 'Marcenaria',
  };
}

abstract final class ProcessingResourceIds {
  static const String coal = 'coal';
  static const String woodenSkewer = 'wooden_skewer';
}

String woodShaftIdFor(String woodResourceId) => '${woodResourceId}_shaft';

class ProcessingCost {
  final Map<String, int> materials;

  ProcessingCost(Map<String, int> materials)
    : materials = UnmodifiableMapView(_positiveMaterials(materials));

  bool get isEmpty => materials.isEmpty;

  int quantityOf(String resourceId) => materials[resourceId] ?? 0;

  bool canAfford(Map<String, int> inventory, {int batches = 1}) {
    if (batches <= 0) return false;
    return materials.entries.every(
      (entry) => (inventory[entry.key] ?? 0) >= entry.value * batches,
    );
  }

  Map<String, int> multipliedBy(int batches) {
    if (batches <= 0) return const {};
    return UnmodifiableMapView({
      for (final entry in materials.entries) entry.key: entry.value * batches,
    });
  }

  Map<String, int> missingFrom(Map<String, int> inventory, {int batches = 1}) {
    if (batches <= 0) return const {};
    final missing = <String, int>{};
    for (final entry in materials.entries) {
      final deficit = entry.value * batches - (inventory[entry.key] ?? 0);
      if (deficit > 0) missing[entry.key] = deficit;
    }
    return UnmodifiableMapView(missing);
  }
}

class ProcessingOutput {
  final String resourceId;
  final int quantity;

  const ProcessingOutput({required this.resourceId, required this.quantity})
    : assert(resourceId != ''),
      assert(quantity > 0);

  int forBatches(int batches) => batches <= 0 ? 0 : quantity * batches;
}

abstract class ProcessingRecipe {
  final String id;
  final String name;
  final String description;
  final ProcessingKind kind;
  final int tier;
  final ProcessingCost cost;
  final ProcessingOutput output;
  final int durationMilliseconds;
  final String skillId;
  final double experience;
  final int requiredLevel;

  ProcessingRecipe({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.tier,
    required this.cost,
    required this.output,
    required this.durationMilliseconds,
    required this.skillId,
    required this.experience,
    required this.requiredLevel,
  }) : assert(id != ''),
       assert(name != ''),
       assert(description != ''),
       assert(tier > 0),
       assert(durationMilliseconds > 0),
       assert(skillId != ''),
       assert(experience > 0),
       assert(requiredLevel > 0),
       assert(!cost.isEmpty);

  Duration get duration => Duration(milliseconds: durationMilliseconds);

  double get durationSeconds => durationMilliseconds / 1000;

  bool isUnlockedAt(int skillLevel) => skillLevel >= requiredLevel;

  bool canStart({
    required int skillLevel,
    required Map<String, int> inventory,
    int batches = 1,
  }) {
    return isUnlockedAt(skillLevel) &&
        cost.canAfford(inventory, batches: batches);
  }
}

class SmeltingRecipe extends ProcessingRecipe {
  final EquipmentMaterial material;
  final GatheringResource ore;

  SmeltingRecipe({
    required super.id,
    required super.name,
    required super.description,
    required super.tier,
    required super.cost,
    required super.output,
    required super.durationMilliseconds,
    required super.experience,
    required super.requiredLevel,
    required this.material,
    required this.ore,
  }) : assert(ore.discipline == GatheringDiscipline.mining),
       assert(ore.id == material.resourceId),
       super(kind: ProcessingKind.smelting, skillId: 'smithing');

  String get oreId => ore.id;
  String get barId => output.resourceId;
}

/// Consagração Arcana: o equivalente do Arcanista à Fundição do Ferreiro,
/// para minérios mágicos que não viram uma barra comum.
class ArcaneRefiningRecipe extends ProcessingRecipe {
  final EquipmentMaterial material;
  final GatheringResource ore;

  ArcaneRefiningRecipe({
    required super.id,
    required super.name,
    required super.description,
    required super.tier,
    required super.cost,
    required super.output,
    required super.durationMilliseconds,
    required super.experience,
    required super.requiredLevel,
    required this.material,
    required this.ore,
  }) : assert(ore.discipline == GatheringDiscipline.mining),
       assert(ore.id == material.resourceId),
       super(kind: ProcessingKind.arcaneRefining, skillId: 'arcanism');

  String get oreId => ore.id;
  String get ingotId => output.resourceId;
}

class CookingRecipe extends ProcessingRecipe {
  final GatheringResource rawFish;
  final int healAmount;

  CookingRecipe({
    required super.id,
    required super.name,
    required super.description,
    required super.tier,
    required super.cost,
    required super.output,
    required super.durationMilliseconds,
    required super.experience,
    required super.requiredLevel,
    required this.rawFish,
    required this.healAmount,
  }) : assert(rawFish.discipline == GatheringDiscipline.fishing),
       assert(healAmount > 0),
       super(kind: ProcessingKind.cooking, skillId: 'cooking');

  String get rawFishId => rawFish.id;
  String get foodId => output.resourceId;
}

class SkewerRecipe extends ProcessingRecipe {
  final GatheringResource wood;

  SkewerRecipe({
    required super.id,
    required super.name,
    required super.description,
    required super.cost,
    required super.output,
    required super.durationMilliseconds,
    required super.experience,
    required super.requiredLevel,
    required this.wood,
  }) : assert(wood.discipline == GatheringDiscipline.woodcutting),
       super(kind: ProcessingKind.woodworking, tier: 1, skillId: 'crafting');

  String get woodId => wood.id;
  String get skewerId => output.resourceId;
}

/// Hastes talhadas pelo Artesão: o segundo insumo de arcos, flechas e
/// cajados mágicos, ao lado da barra de metal correspondente.
class ShaftRecipe extends ProcessingRecipe {
  final GatheringResource wood;

  ShaftRecipe({
    required super.id,
    required super.name,
    required super.description,
    required super.tier,
    required super.cost,
    required super.output,
    required super.durationMilliseconds,
    required super.experience,
    required super.requiredLevel,
    required this.wood,
  }) : assert(wood.discipline == GatheringDiscipline.woodcutting),
       super(kind: ProcessingKind.woodworking, skillId: 'crafting');

  String get woodId => wood.id;
  String get shaftId => output.resourceId;
}

Map<String, int> _positiveMaterials(Map<String, int> source) {
  final result = <String, int>{};
  for (final entry in source.entries) {
    if (entry.key.isNotEmpty && entry.value > 0) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}
