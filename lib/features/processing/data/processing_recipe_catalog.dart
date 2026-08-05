import 'package:realm_idle_game/features/processing/data/arcane_refining_catalog.dart';
import 'package:realm_idle_game/features/processing/data/cooking_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/shaft_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/skewer_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/smelting_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';

abstract final class ProcessingRecipeCatalog {
  static final List<ProcessingRecipe> all = List.unmodifiable([
    ...SmeltingRecipeCatalog.all,
    ...ArcaneRefiningCatalog.all,
    ...CookingRecipeCatalog.all,
    ...SkewerRecipeCatalog.all,
    ...ShaftRecipeCatalog.all,
  ]);

  static ProcessingRecipe? byId(String id) {
    for (final recipe in all) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  static List<ProcessingRecipe> forKind(ProcessingKind kind) =>
      List.unmodifiable(all.where((recipe) => recipe.kind == kind));

  static List<ProcessingRecipe> forSkill(String skillId) =>
      List.unmodifiable(all.where((recipe) => recipe.skillId == skillId));

  static List<ProcessingRecipe> consuming(String resourceId) =>
      List.unmodifiable(
        all.where((recipe) => recipe.cost.quantityOf(resourceId) > 0),
      );

  static List<ProcessingRecipe> producing(String resourceId) =>
      List.unmodifiable(
        all.where((recipe) => recipe.output.resourceId == resourceId),
      );

  static List<ProcessingRecipe> unlockedFor({
    required String skillId,
    required int skillLevel,
  }) => List.unmodifiable(
    all.where(
      (recipe) => recipe.skillId == skillId && recipe.isUnlockedAt(skillLevel),
    ),
  );
}
