import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';

/// Consagração Arcana: o refino que o Arcanista aplica sobre minérios
/// mágicos que não fazem sentido como uma barra comum da Fundição. Hoje
/// cobre apenas o Cristal Arcano, mas fica pronto para acolher outros
/// minérios mágicos (Essência Rúnica, Pedra de Essência) no futuro.
abstract final class ArcaneRefiningCatalog {
  static final List<ArcaneRefiningRecipe> all = List.unmodifiable([
    _arcaneCrystal(),
  ]);

  static ArcaneRefiningRecipe? byId(String id) {
    for (final recipe in all) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  static ArcaneRefiningRecipe? forMaterial(EquipmentMaterial material) {
    for (final recipe in all) {
      if (recipe.material == material) return recipe;
    }
    return null;
  }

  static ArcaneRefiningRecipe? forOre(String oreResourceId) {
    for (final recipe in all) {
      if (recipe.oreId == oreResourceId) return recipe;
    }
    return null;
  }

  static List<ArcaneRefiningRecipe> unlockedAt(int arcanismLevel) =>
      List.unmodifiable(
        all.where((recipe) => recipe.isUnlockedAt(arcanismLevel)),
      );

  static ArcaneRefiningRecipe _arcaneCrystal() {
    const material = EquipmentMaterial.arcaneCrystal;
    final ore = material.resource;
    return ArcaneRefiningRecipe(
      id: 'consecrate_${material.resourceId}',
      name: 'Consagrar Lingote Arcano',
      description:
          'Consagra o cristal arcano com essência rúnica em rituais que '
          'selam seu poder em uma forma estável, sem o fogo da forja comum.',
      tier: material.tier + 1,
      material: material,
      ore: ore,
      cost: ProcessingCost({material.resourceId: 1, 'rune_essence': 8}),
      output: const ProcessingOutput(resourceId: 'arcane_ingot', quantity: 1),
      durationMilliseconds: 23000,
      experience: 244,
      requiredLevel: 90,
    );
  }
}
