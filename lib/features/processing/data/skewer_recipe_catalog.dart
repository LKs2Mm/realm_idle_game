import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';

abstract final class SkewerRecipeCatalog {
  static final SkewerRecipe recipe = _buildRecipe();

  static final List<SkewerRecipe> all = List.unmodifiable([recipe]);

  static SkewerRecipe? byId(String id) => id == recipe.id ? recipe : null;

  static SkewerRecipe _buildRecipe() {
    final normalLog = GatheringResource.byId('normal_log');
    if (normalLog == null ||
        normalLog.discipline != GatheringDiscipline.woodcutting) {
      throw StateError('Tronco comum indisponível para fabricar espetos.');
    }
    return SkewerRecipe(
      id: 'carve_wooden_skewers',
      name: 'Entalhar espetos rústicos',
      description:
          'Divide um tronco comum em hastes firmes para cozinhar sobre carvão.',
      wood: normalLog,
      cost: ProcessingCost({normalLog.id: 1}),
      output: const ProcessingOutput(
        resourceId: ProcessingResourceIds.woodenSkewer,
        quantity: 5,
      ),
      durationMilliseconds: 3000,
      experience: 4,
      requiredLevel: 1,
    );
  }
}
