import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';

/// Hastes talhadas pelo Artesão a partir de cada tora de madeira. Servem de
/// segundo insumo (ao lado da barra de metal) para o arco e a aljava do
/// Arqueiro e para o cajado do Mago — ver `EquipmentMaterialDetails.shaftWoodId`.
abstract final class ShaftRecipeCatalog {
  static final List<ShaftRecipe> all = List.unmodifiable(
    GatheringResource.forDiscipline(
      GatheringDiscipline.woodcutting,
    ).map(_buildRecipe),
  );

  static ShaftRecipe? byId(String id) {
    for (final recipe in all) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  static ShaftRecipe? forWood(String woodResourceId) {
    for (final recipe in all) {
      if (recipe.woodId == woodResourceId) return recipe;
    }
    return null;
  }

  static List<ShaftRecipe> unlockedAt(int craftingLevel) => List.unmodifiable(
    all.where((recipe) => recipe.isUnlockedAt(craftingLevel)),
  );

  static String shaftNameFor(String woodResourceId) =>
      _shaftNames[woodResourceId] ?? 'Haste desconhecida';

  static const Map<String, String> _shaftNames = {
    'normal_log': 'Haste Comum',
    'oak_log': 'Haste de Carvalho',
    'willow_log': 'Haste de Salgueiro',
    'maple_log': 'Haste de Bordo',
    'mahogany_log': 'Haste de Mogno',
    'yew_log': 'Haste de Teixo',
    'magic_log': 'Haste Mágica',
    'ancient_log': 'Haste Ancestral',
  };

  static ShaftRecipe _buildRecipe(GatheringResource wood) {
    final tier =
        GatheringResource.forDiscipline(
          GatheringDiscipline.woodcutting,
        ).indexOf(wood) +
        1;
    final shaftName = shaftNameFor(wood.id);
    final requiredLevel = tier == 1 ? 1 : (tier - 1) * 10;

    return ShaftRecipe(
      id: 'carve_${wood.id}_shaft',
      name: 'Talhar $shaftName',
      description:
          'Talha ${wood.name.toLowerCase()} em hastes firmes, prontas para '
          'arcos, flechas e cajados.',
      tier: tier,
      cost: ProcessingCost({wood.id: 2}),
      output: ProcessingOutput(
        resourceId: woodShaftIdFor(wood.id),
        quantity: 3,
      ),
      durationMilliseconds: (3 + tier * 2) * 1000,
      experience: 4 + tier * tier * 2.4,
      requiredLevel: requiredLevel,
      wood: wood,
    );
  }
}
