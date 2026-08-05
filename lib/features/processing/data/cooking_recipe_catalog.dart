import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';

abstract final class CookingRecipeCatalog {
  static final List<CookingRecipe> all = List.unmodifiable(
    _specs.map(_buildRecipe),
  );

  static CookingRecipe? byId(String id) {
    for (final recipe in all) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  static CookingRecipe? byFoodId(String foodResourceId) {
    for (final recipe in all) {
      if (recipe.foodId == foodResourceId) return recipe;
    }
    return null;
  }

  static List<CookingRecipe> forRawFish(String rawFishResourceId) =>
      List.unmodifiable(
        all.where((recipe) => recipe.rawFishId == rawFishResourceId),
      );

  static List<CookingRecipe> unlockedAt(int cookingLevel) => List.unmodifiable(
    all.where((recipe) => recipe.isUnlockedAt(cookingLevel)),
  );

  static CookingRecipe _buildRecipe(_CookingSpec spec) {
    final rawFish = GatheringResource.byId(spec.rawFishId);
    if (rawFish == null || rawFish.discipline != GatheringDiscipline.fishing) {
      throw StateError('Peixe de processamento inválido: ${spec.rawFishId}');
    }
    final coalCost = 1 + ((spec.tier - 1) ~/ 4);
    return CookingRecipe(
      id: 'cook_${spec.foodId}',
      name: spec.name,
      description: spec.description,
      tier: spec.tier,
      rawFish: rawFish,
      healAmount: spec.healAmount,
      cost: ProcessingCost({
        spec.rawFishId: 1,
        ProcessingResourceIds.coal: coalCost,
        ProcessingResourceIds.woodenSkewer: 1,
      }),
      output: ProcessingOutput(resourceId: spec.foodId, quantity: 1),
      durationMilliseconds: spec.durationSeconds * 1000,
      experience: spec.experience,
      requiredLevel: spec.requiredLevel,
    );
  }

  static const List<_CookingSpec> _specs = [
    _CookingSpec(
      tier: 1,
      rawFishId: 'shrimp',
      foodId: 'roasted_shrimp',
      name: 'Camarão assado',
      description:
          'Pequenos camarões tostados em espeto sobre brasas de carvão.',
      requiredLevel: 1,
      durationSeconds: 3,
      experience: 5,
      healAmount: 8,
    ),
    _CookingSpec(
      tier: 2,
      rawFishId: 'sardine',
      foodId: 'roasted_sardine',
      name: 'Sardinha assada',
      description: 'Sardinha salgada e selada sobre o fogo do acampamento.',
      requiredLevel: 10,
      durationSeconds: 4,
      experience: 8,
      healAmount: 12,
    ),
    _CookingSpec(
      tier: 3,
      rawFishId: 'trout',
      foodId: 'roasted_trout',
      name: 'Truta assada',
      description: 'Truta de rio assada lentamente até a pele ficar crocante.',
      requiredLevel: 20,
      durationSeconds: 5,
      experience: 13,
      healAmount: 18,
    ),
    _CookingSpec(
      tier: 4,
      rawFishId: 'salmon',
      foodId: 'roasted_salmon',
      name: 'Salmão assado',
      description: 'Salmão vigoroso defumado em carvão de madeira negra.',
      requiredLevel: 30,
      durationSeconds: 6,
      experience: 20,
      healAmount: 26,
    ),
    _CookingSpec(
      tier: 5,
      rawFishId: 'tuna',
      foodId: 'roasted_tuna',
      name: 'Atum assado',
      description: 'Posta espessa de atum marcada pelas grelhas da fortaleza.',
      requiredLevel: 40,
      durationSeconds: 8,
      experience: 30,
      healAmount: 38,
    ),
    _CookingSpec(
      tier: 6,
      rawFishId: 'lobster',
      foodId: 'roasted_lobster',
      name: 'Lagosta assada',
      description: 'Carne de lagosta tostada dentro da própria carapaça.',
      requiredLevel: 50,
      durationSeconds: 10,
      experience: 44,
      healAmount: 55,
    ),
    _CookingSpec(
      tier: 7,
      rawFishId: 'swordfish',
      foodId: 'roasted_swordfish',
      name: 'Peixe-espada assado',
      description: 'Corte de peixe-espada servido como alimento de caçadores.',
      requiredLevel: 60,
      durationSeconds: 12,
      experience: 62,
      healAmount: 78,
    ),
    _CookingSpec(
      tier: 8,
      rawFishId: 'shark',
      foodId: 'roasted_shark',
      name: 'Tubarão assado',
      description: 'Carne densa de tubarão tostada para longas expedições.',
      requiredLevel: 70,
      durationSeconds: 15,
      experience: 86,
      healAmount: 110,
    ),
    _CookingSpec(
      tier: 9,
      rawFishId: 'abyssal_eel',
      foodId: 'roasted_abyssal_eel',
      name: 'Enguia abissal assada',
      description:
          'A carne luminosa é selada em brasas negras sem apagar sua energia abissal.',
      requiredLevel: 80,
      durationSeconds: 19,
      experience: 118,
      healAmount: 150,
    ),
    _CookingSpec(
      tier: 10,
      rawFishId: 'runic_leviathan',
      foodId: 'roasted_runic_leviathan',
      name: 'Leviatã rúnico assado',
      description:
          'Um corte colossal assado sobre carvão, com as runas preservadas no espeto.',
      requiredLevel: 90,
      durationSeconds: 24,
      experience: 160,
      healAmount: 210,
    ),
  ];
}

class _CookingSpec {
  final int tier;
  final String rawFishId;
  final String foodId;
  final String name;
  final String description;
  final int requiredLevel;
  final int durationSeconds;
  final double experience;
  final int healAmount;

  const _CookingSpec({
    required this.tier,
    required this.rawFishId,
    required this.foodId,
    required this.name,
    required this.description,
    required this.requiredLevel,
    required this.durationSeconds,
    required this.experience,
    required this.healAmount,
  });
}
