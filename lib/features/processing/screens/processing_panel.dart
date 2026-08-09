import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/processing/data/processing_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/models/game_state.dart';

class ProcessingPanel extends StatefulWidget {
  final GameState gameState;
  final void Function(String recipeId, int quantity) onStartProcessing;
  final ValueChanged<String> onEatFood;
  final VoidCallback onCancelProduction;

  const ProcessingPanel({
    super.key,
    required this.gameState,
    required this.onStartProcessing,
    required this.onEatFood,
    required this.onCancelProduction,
  });

  @override
  State<ProcessingPanel> createState() => _ProcessingPanelState();
}

class _ProcessingPanelState extends State<ProcessingPanel> {
  ProcessingKind _selectedKind = ProcessingKind.smelting;
  int _batchQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;
    final recipes = ProcessingRecipeCatalog.forKind(_selectedKind);
    final session = state.activeProductionSession;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: _HealthHeader(
            currentHealth: state.currentHealth,
            maximumHealth: state.maxHealth,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _ProcessingControls(
            selectedKind: _selectedKind,
            batchQuantity: _batchQuantity,
            onKindChanged: (kind) => setState(() => _selectedKind = kind),
            onBatchChanged: (quantity) =>
                setState(() => _batchQuantity = quantity),
          ),
        ),
        if (session != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: _ActiveProcessingPanel(
              session: session,
              onCancel: widget.onCancelProduction,
            ),
          ),
        const RunicDivider(height: 18, maxWidth: 180, opacity: 0.48),
        Expanded(
          child: ListView.separated(
            key: PageStorageKey<String>(
              'processing-recipe-list-${_selectedKind.saveKey}',
            ),
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 28),
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _ProcessingRecipeCard(
                recipe: recipe,
                batchQuantity: _batchQuantity,
                gameState: state,
                onStart: widget.onStartProcessing,
                onEatFood: widget.onEatFood,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HealthHeader extends StatelessWidget {
  final int currentHealth;
  final int maximumHealth;

  const _HealthHeader({
    required this.currentHealth,
    required this.maximumHealth,
  });

  @override
  Widget build(BuildContext context) {
    final safeMaximum = maximumHealth <= 0 ? 1 : maximumHealth;
    final safeCurrent = currentHealth.clamp(0, safeMaximum);
    final progress = safeCurrent / safeMaximum;
    return Card(
      key: const ValueKey<String>('processing-health'),
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: AppTheme.combatRed,
        opacity: 0.46,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _ProcessingSeal(
                    icon: Icons.local_fire_department_outlined,
                    color: AppTheme.combatRed,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FOGO, FERRO E PROVISÕES',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.combatRed,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.65,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Processamento do refúgio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _CompactChip(
                    label: '$safeCurrent / $safeMaximum HP',
                    color: AppTheme.combatRed,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  key: const ValueKey<String>('processing-health-progress'),
                  value: progress,
                  minHeight: 6,
                  color: AppTheme.combatRed,
                  backgroundColor: AppTheme.voidBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingControls extends StatelessWidget {
  final ProcessingKind selectedKind;
  final int batchQuantity;
  final ValueChanged<ProcessingKind> onKindChanged;
  final ValueChanged<int> onBatchChanged;

  const _ProcessingControls({
    required this.selectedKind,
    required this.batchQuantity,
    required this.onKindChanged,
    required this.onBatchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'OFÍCIO',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.accentYellow,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final kind in ProcessingKind.values) ...[
                ChoiceChip(
                  key: ValueKey<String>('processing-kind-${kind.saveKey}'),
                  selected: selectedKind == kind,
                  onSelected: (_) => onKindChanged(kind),
                  avatar: Icon(_kindIcon(kind), size: 15),
                  label: Text(kind.displayName),
                ),
                if (kind != ProcessingKind.values.last)
                  const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: Text(
                'TAMANHO DO LOTE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.55,
                ),
              ),
            ),
            for (final quantity in const [1, 5, 10]) ...[
              ChoiceChip(
                key: ValueKey<String>('processing-quantity-$quantity'),
                selected: batchQuantity == quantity,
                onSelected: (_) => onBatchChanged(quantity),
                label: Text('×$quantity'),
                visualDensity: VisualDensity.compact,
              ),
              if (quantity != 10) const SizedBox(width: 5),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActiveProcessingPanel extends StatelessWidget {
  final ProductionSession session;
  final VoidCallback onCancel;

  const _ActiveProcessingPanel({required this.session, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final color = _productionKindColor(session.kind);
    return Card(
      key: const ValueKey<String>('processing-active-session'),
      margin: EdgeInsets.zero,
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.35),
      child: RunicFrame(
        color: color,
        opacity: 0.62,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: color, size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${session.kind.displayName} • lote ×${session.quantity}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _formatDuration(session.timeRemainingMilliseconds),
                    key: const ValueKey<String>('processing-session-remaining'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  key: const ValueKey<String>('processing-session-progress'),
                  value: session.progress,
                  minHeight: 6,
                  color: color,
                  backgroundColor: AppTheme.voidBlack,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'A fila da oficina está ocupada.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: const ValueKey<String>('processing-cancel-production'),
                    onPressed: onCancel,
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcessingRecipeCard extends StatelessWidget {
  final ProcessingRecipe recipe;
  final int batchQuantity;
  final GameState gameState;
  final void Function(String recipeId, int quantity) onStart;
  final ValueChanged<String> onEatFood;

  const _ProcessingRecipeCard({
    required this.recipe,
    required this.batchQuantity,
    required this.gameState,
    required this.onStart,
    required this.onEatFood,
  });

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(recipe.kind);
    final cookingRecipe = recipe is CookingRecipe
        ? recipe as CookingRecipe
        : null;
    final skill = gameState.skills[recipe.skillId];
    final skillLevel = skill?.level ?? 1;
    final inventory = gameState.gatheringInventory.resources;
    final scaledCost = recipe.cost.multipliedBy(batchQuantity);
    final unlocked = recipe.isUnlockedAt(skillLevel);
    final affordable = recipe.cost.canAfford(inventory, batches: batchQuantity);
    final queueAvailable = gameState.activeProductionSession == null;
    final canStart = unlocked && affordable && queueAvailable;
    final outputQuantity = recipe.output.forBatches(batchQuantity);
    final ownedOutput = cookingRecipe != null
        ? gameState.contentInventory.quantityOfConsumable(cookingRecipe.foodId)
        : gameState.gatheringInventory.quantityOf(recipe.output.resourceId);

    return Card(
      key: ValueKey<String>('processing-card-${recipe.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: color.withValues(alpha: 0.52)),
      ),
      child: RunicFrame(
        color: color,
        opacity: 0.42,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProcessingSeal(
                    icon: _kindIcon(recipe.kind),
                    color: color,
                    imageAsset: _processedGoodAsset(recipe),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NÍVEL ${recipe.tier} • ${skill?.name ?? recipe.skillId} ${recipe.requiredLevel}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: unlocked ? color : AppTheme.combatRed,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          recipe.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  _CompactChip(label: '×$ownedOutput', color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recipe.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _CompactChip(
                    label:
                        '${_formatDuration(recipe.durationMilliseconds * batchQuantity)} no lote',
                    color: AppTheme.textSecondary,
                  ),
                  _CompactChip(
                    label:
                        '${_formatExperience(recipe.experience * batchQuantity)} XP',
                    color: AppTheme.accentYellow,
                  ),
                  _CompactChip(label: 'Produz ×$outputQuantity', color: color),
                  if (cookingRecipe != null)
                    _CompactChip(
                      label: '+${cookingRecipe.healAmount} HP cada',
                      color: AppTheme.combatRed,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'CUSTO DO LOTE • estoque / necessário',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.45,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in scaledCost.entries)
                    _CostChip(
                      key: ValueKey<String>(
                        'processing-cost-${recipe.id}-${entry.key}',
                      ),
                      name: _resourceName(entry.key),
                      owned: gameState.gatheringInventory.quantityOf(entry.key),
                      needed: entry.value,
                    ),
                ],
              ),
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: ValueKey<String>('processing-start-${recipe.id}'),
                  onPressed: canStart
                      ? () => onStart(recipe.id, batchQuantity)
                      : null,
                  icon: Icon(_kindIcon(recipe.kind), size: 17),
                  label: Text(
                    _startLabel(
                      queueAvailable: queueAvailable,
                      unlocked: unlocked,
                      affordable: affordable,
                      requiredLevel: recipe.requiredLevel,
                      quantity: batchQuantity,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (cookingRecipe != null) ...[
                const SizedBox(height: 7),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: ValueKey<String>(
                      'processing-eat-${cookingRecipe.foodId}',
                    ),
                    onPressed:
                        ownedOutput > 0 &&
                            gameState.currentHealth < gameState.maxHealth
                        ? () => onEatFood(cookingRecipe.foodId)
                        : null,
                    icon: const Icon(Icons.restaurant_outlined, size: 17),
                    label: Text(
                      _eatLabel(
                        owned: ownedOutput,
                        needsHealing:
                            gameState.currentHealth < gameState.maxHealth,
                        healAmount: cookingRecipe.healAmount,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  final String name;
  final int owned;
  final int needed;

  const _CostChip({
    super.key,
    required this.name,
    required this.owned,
    required this.needed,
  });

  @override
  Widget build(BuildContext context) {
    final available = owned >= needed;
    final color = available ? AppTheme.miningGreenLight : AppTheme.combatRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$name  $owned / $needed',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompactChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CompactChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProcessingSeal extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? imageAsset;

  const _ProcessingSeal({
    required this.icon,
    required this.color,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: imageAsset == null
          ? Icon(icon, color: color, size: 21)
          : ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                imageAsset!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(icon, color: color, size: 21),
              ),
            ),
    );
  }
}

String _startLabel({
  required bool queueAvailable,
  required bool unlocked,
  required bool affordable,
  required int requiredLevel,
  required int quantity,
}) {
  if (!queueAvailable) return 'Fila ocupada';
  if (!unlocked) return 'Requer nível $requiredLevel';
  if (!affordable) return 'Materiais insuficientes';
  return 'Iniciar lote ×$quantity';
}

String _eatLabel({
  required int owned,
  required bool needsHealing,
  required int healAmount,
}) {
  if (owned <= 0) return 'Nenhuma porção pronta';
  if (!needsHealing) return 'Vida cheia';
  return 'Consumir • +$healAmount HP';
}

String _resourceName(String resourceId) {
  final gatheringResource = GatheringResource.byId(resourceId);
  if (gatheringResource != null) return gatheringResource.name;
  return switch (resourceId) {
    ProcessingResourceIds.coal => 'Carvão',
    ProcessingResourceIds.woodenSkewer => 'Espeto de madeira',
    _ => _titleFromId(resourceId),
  };
}

String _titleFromId(String id) {
  return id
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDuration(int milliseconds) {
  final totalSeconds = (milliseconds / 1000).ceil().clamp(0, 604800);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  if (minutes > 0) return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  return '${seconds}s';
}

String _formatExperience(double experience) {
  final rounded = experience.roundToDouble();
  return experience == rounded
      ? rounded.toInt().toString()
      : experience.toStringAsFixed(1);
}

String? _processedGoodAsset(ProcessingRecipe recipe) => switch (recipe) {
  SmeltingRecipe() ||
  ArcaneRefiningRecipe() => MedievalAssets.gatheringItemAsset(
    'barras',
    recipe.output.resourceId,
  ),
  SkewerRecipe() => MedievalAssets.gatheringItemAsset('barras', 'wooden_skewer'),
  CookingRecipe() => MedievalAssets.gatheringItemAsset(
    'comidas',
    recipe.output.resourceId,
  ),
  _ => null,
};

Color _kindColor(ProcessingKind kind) => switch (kind) {
  ProcessingKind.smelting => AppTheme.smithingOrange,
  ProcessingKind.arcaneRefining => AppTheme.combatBlue,
  ProcessingKind.cooking => AppTheme.miningGreenLight,
  ProcessingKind.woodworking => AppTheme.accentYellow,
};

IconData _kindIcon(ProcessingKind kind) => switch (kind) {
  ProcessingKind.smelting => Icons.local_fire_department_outlined,
  ProcessingKind.arcaneRefining => Icons.diamond_outlined,
  ProcessingKind.cooking => Icons.outdoor_grill_outlined,
  ProcessingKind.woodworking => Icons.hardware_outlined,
};

Color _productionKindColor(ProductionKind kind) => switch (kind) {
  ProductionKind.equipment ||
  ProductionKind.smelting ||
  ProductionKind.woodworking => AppTheme.smithingOrange,
  ProductionKind.cooking || ProductionKind.potion => AppTheme.miningGreenLight,
  ProductionKind.spell || ProductionKind.arcaneRefining => AppTheme.combatBlue,
};
