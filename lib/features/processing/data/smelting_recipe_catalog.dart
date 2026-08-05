import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';

abstract final class SmeltingRecipeCatalog {
  /// O Cristal Arcano não entra aqui: seu refino é a Consagração Arcana do
  /// Arcanista (ver `ArcaneRefiningCatalog`), não uma barra de metal comum.
  static final List<SmeltingRecipe> all = List.unmodifiable(
    EquipmentMaterial.values
        .where((material) => material != EquipmentMaterial.arcaneCrystal)
        .map(_buildRecipe),
  );

  static SmeltingRecipe? byId(String id) {
    for (final recipe in all) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  static SmeltingRecipe? forMaterial(EquipmentMaterial material) {
    for (final recipe in all) {
      if (recipe.material == material) return recipe;
    }
    return null;
  }

  static SmeltingRecipe? forOre(String oreResourceId) {
    for (final recipe in all) {
      if (recipe.oreId == oreResourceId) return recipe;
    }
    return null;
  }

  static List<SmeltingRecipe> unlockedAt(int smithingLevel) =>
      List.unmodifiable(
        all.where((recipe) => recipe.isUnlockedAt(smithingLevel)),
      );

  static SmeltingRecipe _buildRecipe(EquipmentMaterial material) {
    final tier = material.tier + 1;
    final ore = material.resource;
    final outputId = '${material.resourceId}_bar';
    final outputName = 'Barra de ${material.displayName.toLowerCase()}';
    final requiredLevel = tier == 1 ? 1 : (tier - 1) * 10;
    final coalCost = 1 + ((tier - 1) ~/ 3);

    return SmeltingRecipe(
      id: 'smelt_${material.resourceId}',
      name: 'Fundir $outputName',
      description:
          'Purifica ${ore.name.toLowerCase()} nas chamas escuras da forja e sela suas impurezas com carvão.',
      tier: tier,
      material: material,
      ore: ore,
      cost: ProcessingCost({
        material.resourceId: 1,
        ProcessingResourceIds.coal: coalCost,
      }),
      output: ProcessingOutput(resourceId: outputId, quantity: 1),
      durationMilliseconds: (3 + tier * 2) * 1000,
      experience: (4 + tier * tier * 2.4),
      requiredLevel: requiredLevel,
    );
  }
}
