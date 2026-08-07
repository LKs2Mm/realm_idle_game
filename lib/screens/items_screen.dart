import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/features/content/data/combat_drop_catalog.dart';
import 'package:realm_idle_game/features/content/models/active_buffs.dart';
import 'package:realm_idle_game/features/content/models/alchemy.dart';
import 'package:realm_idle_game/features/content/models/combat_drop.dart';
import 'package:realm_idle_game/features/content/models/content_inventory.dart';
import 'package:realm_idle_game/features/content/models/spell.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/processing/data/processing_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/shaft_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';
import 'package:realm_idle_game/features/processing/screens/processing_panel.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/models/game_state.dart';

class ItemsScreen extends StatefulWidget {
  final GameState gameState;
  final EquipmentState equipment;
  final ContentInventory contentInventory;
  final List<EquipmentDefinition> equipmentDefinitions;
  final List<PotionDefinition> potions;
  final List<SpellDefinition> spells;
  final Map<EquipmentWorkshop, int> workshopLevels;
  final Map<String, int> availableMaterials;
  final int availableGold;
  final int alchemyLevel;
  final int magicLevel;
  final ActiveBuffs activeBuffs;
  final String? activeSpellId;
  final ProductionSession? activeProductionSession;
  final int initialTabIndex;
  final HeroClass initialClass;
  final VoidCallback onCancelProduction;
  final ValueChanged<String> onCraftEquipment;
  final ValueChanged<String> onEquipItem;
  final ValueChanged<String> onBrewPotion;
  final ValueChanged<String> onUsePotion;
  final ValueChanged<String> onCraftSpell;
  final ValueChanged<String> onUseSpell;
  final void Function(String recipeId, int quantity) onStartProcessing;
  final ValueChanged<String> onEatFood;

  const ItemsScreen({
    super.key,
    required this.gameState,
    required this.equipment,
    required this.contentInventory,
    required this.equipmentDefinitions,
    required this.potions,
    required this.spells,
    required this.workshopLevels,
    required this.availableMaterials,
    required this.availableGold,
    required this.alchemyLevel,
    required this.magicLevel,
    required this.activeBuffs,
    required this.activeSpellId,
    required this.activeProductionSession,
    this.initialTabIndex = 0,
    this.initialClass = HeroClass.knight,
    required this.onCancelProduction,
    required this.onCraftEquipment,
    required this.onEquipItem,
    required this.onBrewPotion,
    required this.onUsePotion,
    required this.onCraftSpell,
    required this.onUseSpell,
    required this.onStartProcessing,
    required this.onEatFood,
  });

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  late HeroClass _selectedClass;
  EquipmentSlot _selectedSlot = EquipmentSlot.weapon;
  EquipmentMaterial _selectedMaterial = EquipmentMaterial.copper;
  EquipmentRarity _selectedRarity = EquipmentRarity.common;

  @override
  void initState() {
    super.initState();
    _selectedClass = widget.initialClass;
  }

  EquipmentDefinition? get _previewDefinition {
    for (final definition in widget.equipmentDefinitions) {
      if (definition.heroClass == _selectedClass &&
          definition.slot == _selectedSlot &&
          definition.material == _selectedMaterial &&
          definition.rarity == _selectedRarity) {
        return definition;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final equipmentCount = widget.equipment.inventory.items.values.fold<int>(
      0,
      (sum, quantity) => sum + quantity,
    );
    final materialCount = widget.availableMaterials.entries
        .where(
          (entry) =>
              entry.value > 0 &&
              (GatheringResource.byId(entry.key) != null ||
                  CombatDropCatalog.byId(entry.key) != null ||
                  ProcessingRecipeCatalog.producing(entry.key).isNotEmpty),
        )
        .fold<int>(0, (sum, entry) => sum + entry.value);

    return DefaultTabController(
      length: 7,
      initialIndex: widget.initialTabIndex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: _ItemsHeader(
              equipmentCount: equipmentCount,
              consumableCount: widget.contentInventory.totalConsumables,
              spellCount: widget.contentInventory.totalSpells,
              materialCount: materialCount,
            ),
          ),
          const RunicDivider(height: 22, maxWidth: 210),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: AppTheme.darkCardBorder,
            labelColor: AppTheme.accentYellow,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: const [
              Tab(
                key: ValueKey<String>('items-tab-equipped'),
                text: 'Equipados',
              ),
              Tab(key: ValueKey<String>('items-tab-arsenal'), text: 'Arsenal'),
              Tab(
                key: ValueKey<String>('items-tab-workshops'),
                text: 'Oficinas',
              ),
              Tab(key: ValueKey<String>('items-tab-alchemy'), text: 'Alquimia'),
              Tab(
                key: ValueKey<String>('items-tab-grimoire'),
                text: 'Grimório',
              ),
              Tab(
                key: ValueKey<String>('items-tab-processing'),
                text: 'Processamento',
              ),
              Tab(
                key: ValueKey<String>('items-tab-materials'),
                text: 'Materiais',
              ),
            ],
          ),
          if (widget.activeProductionSession != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ActiveProductionPanel(
                session: widget.activeProductionSession!,
                onCancel: widget.onCancelProduction,
              ),
            ),
          Expanded(
            child: TabBarView(
              children: [
                _EquippedTab(
                  equipment: widget.equipment,
                  definitions: widget.equipmentDefinitions,
                  selectedClass: _selectedClass,
                  onClassChanged: _selectClass,
                ),
                _ArsenalTab(
                  equipment: widget.equipment,
                  selectedClass: _selectedClass,
                  selectedSlot: _selectedSlot,
                  selectedMaterial: _selectedMaterial,
                  selectedRarity: _selectedRarity,
                  definition: _previewDefinition,
                  workshopLevels: widget.workshopLevels,
                  availableGold: widget.availableGold,
                  availableMaterials: widget.availableMaterials,
                  onClassChanged: _selectClass,
                  onSlotChanged: (value) =>
                      setState(() => _selectedSlot = value),
                  onMaterialChanged: (value) =>
                      setState(() => _selectedMaterial = value),
                  onRarityChanged: (value) =>
                      setState(() => _selectedRarity = value),
                  onCraft: widget.onCraftEquipment,
                  onEquip: widget.onEquipItem,
                ),
                _WorkshopsTab(levels: widget.workshopLevels),
                _AlchemyTab(
                  potions: widget.potions,
                  inventory: widget.contentInventory,
                  availableMaterials: widget.availableMaterials,
                  alchemyLevel: widget.alchemyLevel,
                  activeBuffs: widget.activeBuffs,
                  onBrew: widget.onBrewPotion,
                  onUse: widget.onUsePotion,
                ),
                _GrimoireTab(
                  spells: widget.spells,
                  inventory: widget.contentInventory,
                  availableMaterials: widget.availableMaterials,
                  magicLevel: widget.magicLevel,
                  activeSpellId: widget.activeSpellId,
                  onCraft: widget.onCraftSpell,
                  onUse: widget.onUseSpell,
                ),
                ProcessingPanel(
                  gameState: widget.gameState,
                  onStartProcessing: widget.onStartProcessing,
                  onEatFood: widget.onEatFood,
                  onCancelProduction: widget.onCancelProduction,
                ),
                _MaterialsTab(materials: widget.availableMaterials),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectClass(HeroClass heroClass) {
    if (heroClass == _selectedClass) return;
    setState(() => _selectedClass = heroClass);
  }
}

class _ActiveProductionPanel extends StatelessWidget {
  final ProductionSession session;
  final VoidCallback onCancel;

  const _ActiveProductionPanel({required this.session, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final percent = (session.progress * 100).round();
    return Container(
      key: const ValueKey<String>('items-active-production'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.smithingOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.smithingOrange.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 17,
                color: AppTheme.smithingOrange,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${session.kind.displayName} • $percent%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.smithingOrange,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _formatRemaining(session.timeRemainingMilliseconds),
                key: const ValueKey<String>('items-production-remaining'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: session.progress,
              minHeight: 5,
              color: AppTheme.smithingOrange,
              backgroundColor: AppTheme.voidBlack,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Os custos reservados serão devolvidos.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 9),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const ValueKey<String>('items-cancel-production'),
                onPressed: onCancel,
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatRemaining(int milliseconds) {
  final totalSeconds = (milliseconds / 1000).ceil().clamp(0, 8640000);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

class _ItemsHeader extends StatelessWidget {
  final int equipmentCount;
  final int consumableCount;
  final int spellCount;
  final int materialCount;

  const _ItemsHeader({
    required this.equipmentCount,
    required this.consumableCount,
    required this.spellCount,
    required this.materialCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.accentYellow.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: AppTheme.accentYellow.withValues(alpha: 0.5),
            ),
          ),
          child: const Icon(
            Icons.backpack_outlined,
            color: AppTheme.accentYellow,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Itens',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentYellow,
                  fontSize: 24,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$equipmentCount equipamentos  •  $materialCount materiais  •  '
                '$consumableCount poções  •  $spellCount magias',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedievalSceneBanner extends StatelessWidget {
  final String assetPath;
  final String label;
  final Color color;

  const _MedievalSceneBanner({
    super.key,
    required this.assetPath,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
            cacheHeight: 228,
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.voidBlack.withValues(alpha: 0.04),
                  AppTheme.voidBlack.withValues(alpha: 0.84),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 7,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassSelector extends StatelessWidget {
  final HeroClass selected;
  final ValueChanged<HeroClass> onChanged;

  const _ClassSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PRÉVIA DE CLASSE • escolha livre, sem compromisso permanente',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.combatBlue,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final heroClass in HeroClass.values) ...[
                ChoiceChip(
                  key: ValueKey<String>('items-class-${heroClass.saveKey}'),
                  selected: selected == heroClass,
                  onSelected: (_) => onChanged(heroClass),
                  avatar: MedievalEmblem(
                    assetPath: MedievalAssets.classAsset(heroClass.saveKey),
                    size: 16,
                    semanticLabel: heroClass.displayName,
                  ),
                  label: Text(heroClass.displayName),
                ),
                if (heroClass != HeroClass.values.last)
                  const SizedBox(width: 7),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EquippedTab extends StatelessWidget {
  final EquipmentState equipment;
  final List<EquipmentDefinition> definitions;
  final HeroClass selectedClass;
  final ValueChanged<HeroClass> onClassChanged;

  const _EquippedTab({
    required this.equipment,
    required this.definitions,
    required this.selectedClass,
    required this.onClassChanged,
  });

  @override
  Widget build(BuildContext context) {
    final byId = {
      for (final definition in definitions) definition.id: definition,
    };
    return SingleChildScrollView(
      key: const PageStorageKey<String>('items-equipped-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ClassSelector(selected: selectedClass, onChanged: onClassChanged),
          const SizedBox(height: 16),
          for (final slot in EquipmentSlot.values) ...[
            _EquippedSlotCard(
              slot: slot,
              definition:
                  byId[equipment.loadouts.equippedId(selectedClass, slot)],
            ),
            if (slot != EquipmentSlot.values.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _EquippedSlotCard extends StatelessWidget {
  final EquipmentSlot slot;
  final EquipmentDefinition? definition;

  const _EquippedSlotCard({required this.slot, required this.definition});

  @override
  Widget build(BuildContext context) {
    final item = definition;
    final color = item == null
        ? AppTheme.textSecondary
        : _rarityColor(item.rarity);
    final auraIntensity = item?.visuals.auraIntensity ?? 0;
    return Card(
      key: ValueKey<String>('equipped-slot-${slot.saveKey}'),
      margin: EdgeInsets.zero,
      elevation: _auraElevation(auraIntensity),
      shadowColor: color.withValues(alpha: _auraShadowOpacity(auraIntensity)),
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(
          color: color.withValues(alpha: item == null ? 0.22 : 0.82),
          width: item == null ? 1 : _rarityBorderWidth(item.visuals.borderTier),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            _ItemSeal(
              icon: _slotIcon(slot),
              color: color,
              size: 40,
              imageAsset: item == null
                  ? null
                  : MedievalAssets.equipmentAsset(
                      item.heroClass.saveKey,
                      slot.saveKey,
                    ),
              imageTint: item == null
                  ? null
                  : Color(0xFF000000 | item.material.tintRgb),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.displayName.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item?.name ?? 'Espaço vazio',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: item == null
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (item != null)
              Text(
                '${item.stats.powerScore} poder',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArsenalTab extends StatelessWidget {
  final EquipmentState equipment;
  final HeroClass selectedClass;
  final EquipmentSlot selectedSlot;
  final EquipmentMaterial selectedMaterial;
  final EquipmentRarity selectedRarity;
  final EquipmentDefinition? definition;
  final Map<EquipmentWorkshop, int> workshopLevels;
  final int availableGold;
  final Map<String, int> availableMaterials;
  final ValueChanged<HeroClass> onClassChanged;
  final ValueChanged<EquipmentSlot> onSlotChanged;
  final ValueChanged<EquipmentMaterial> onMaterialChanged;
  final ValueChanged<EquipmentRarity> onRarityChanged;
  final ValueChanged<String> onCraft;
  final ValueChanged<String> onEquip;

  const _ArsenalTab({
    required this.equipment,
    required this.selectedClass,
    required this.selectedSlot,
    required this.selectedMaterial,
    required this.selectedRarity,
    required this.definition,
    required this.workshopLevels,
    required this.availableGold,
    required this.availableMaterials,
    required this.onClassChanged,
    required this.onSlotChanged,
    required this.onMaterialChanged,
    required this.onRarityChanged,
    required this.onCraft,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('items-arsenal-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MedievalSceneBanner(
            key: ValueKey<String>('items-armory-banner'),
            assetPath: MedievalAssets.classArmory,
            label: 'ARSENAL DAS QUATRO CLASSES',
            color: AppTheme.combatBlue,
          ),
          const SizedBox(height: 12),
          _ClassSelector(selected: selectedClass, onChanged: onClassChanged),
          const SizedBox(height: 14),
          _PreviewFilters(
            slot: selectedSlot,
            material: selectedMaterial,
            rarity: selectedRarity,
            onSlotChanged: onSlotChanged,
            onMaterialChanged: onMaterialChanged,
            onRarityChanged: onRarityChanged,
          ),
          const SizedBox(height: 14),
          if (definition == null)
            const _EmptyPanel(
              icon: Icons.search_off,
              message: 'Esta combinação ainda não existe no arsenal.',
            )
          else
            _EquipmentPreviewCard(
              definition: definition!,
              equipment: equipment,
              workshopLevel: workshopLevels[definition!.workshop] ?? 1,
              availableGold: availableGold,
              availableMaterials: availableMaterials,
              onCraft: onCraft,
              onEquip: onEquip,
            ),
        ],
      ),
    );
  }
}

class _PreviewFilters extends StatelessWidget {
  final EquipmentSlot slot;
  final EquipmentMaterial material;
  final EquipmentRarity rarity;
  final ValueChanged<EquipmentSlot> onSlotChanged;
  final ValueChanged<EquipmentMaterial> onMaterialChanged;
  final ValueChanged<EquipmentRarity> onRarityChanged;

  const _PreviewFilters({
    required this.slot,
    required this.material,
    required this.rarity,
    required this.onSlotChanged,
    required this.onMaterialChanged,
    required this.onRarityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField<EquipmentSlot>(
              key: const ValueKey<String>('items-slot-filter'),
              initialValue: slot,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Espaço'),
              items: [
                for (final value in EquipmentSlot.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(value.displayName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onSlotChanged(value);
              },
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<EquipmentMaterial>(
              key: const ValueKey<String>('items-material-filter'),
              initialValue: material,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Material'),
              items: [
                for (final value in EquipmentMaterial.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(value.displayName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onMaterialChanged(value);
              },
            ),
            const SizedBox(height: 9),
            DropdownButtonFormField<EquipmentRarity>(
              key: const ValueKey<String>('items-rarity-filter'),
              initialValue: rarity,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Raridade'),
              items: [
                for (final value in EquipmentRarity.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(value.displayName),
                  ),
              ],
              onChanged: (value) {
                if (value != null) onRarityChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentPreviewCard extends StatelessWidget {
  final EquipmentDefinition definition;
  final EquipmentState equipment;
  final int workshopLevel;
  final int availableGold;
  final Map<String, int> availableMaterials;
  final ValueChanged<String> onCraft;
  final ValueChanged<String> onEquip;

  const _EquipmentPreviewCard({
    required this.definition,
    required this.equipment,
    required this.workshopLevel,
    required this.availableGold,
    required this.availableMaterials,
    required this.onCraft,
    required this.onEquip,
  });

  @override
  Widget build(BuildContext context) {
    final color = _rarityColor(definition.rarity);
    final quantity = equipment.inventory.itemQuantity(definition.id);
    final isEquipped =
        equipment.loadouts.equippedId(definition.heroClass, definition.slot) ==
        definition.id;
    final canCraft =
        workshopLevel >= definition.requiredWorkshopLevel &&
        definition.cost.canAfford(
          availableGold: availableGold,
          availableResources: availableMaterials,
        );

    return Card(
      key: ValueKey<String>('equipment-preview-${definition.id}'),
      margin: EdgeInsets.zero,
      elevation: _auraElevation(definition.visuals.auraIntensity),
      shadowColor: color.withValues(
        alpha: _auraShadowOpacity(definition.visuals.auraIntensity),
      ),
      clipBehavior: Clip.antiAlias,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(
          color: color,
          width: _rarityBorderWidth(definition.visuals.borderTier),
        ),
      ),
      child: RunicFrame(
        color: color,
        opacity: 0.65,
        cornerLength: 14,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ItemSeal(
                    icon: _slotIcon(definition.slot),
                    color: color,
                    size: 48,
                    imageAsset: MedievalAssets.equipmentAsset(
                      definition.heroClass.saveKey,
                      definition.slot.saveKey,
                    ),
                    imageTint: Color(0xFF000000 | definition.material.tintRgb),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${definition.material.displayName} • ${definition.rarity.displayName}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          definition.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  _QuantityPill(quantity: quantity, color: color),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                definition.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 11),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _InfoChip(
                    label: '${definition.stats.powerScore} poder',
                    color: color,
                  ),
                  if (definition.stats.physicalPower > 0)
                    _InfoChip(
                      label: 'Físico +${definition.stats.physicalPower}',
                      color: AppTheme.combatRed,
                    ),
                  if (definition.stats.arcanePower > 0)
                    _InfoChip(
                      label: 'Arcano +${definition.stats.arcanePower}',
                      color: AppTheme.combatBlue,
                    ),
                  if (definition.stats.defense > 0)
                    _InfoChip(
                      label: 'Defesa +${definition.stats.defense}',
                      color: AppTheme.miningGreenLight,
                    ),
                  if (definition.stats.vitality > 0)
                    _InfoChip(
                      label: 'Vitalidade +${definition.stats.vitality}',
                      color: AppTheme.miningGreen,
                    ),
                  if (definition.stats.precision > 0)
                    _InfoChip(
                      label: 'Precisão +${definition.stats.precision}',
                      color: AppTheme.accentYellow,
                    ),
                  if (definition.stats.evasion > 0)
                    _InfoChip(
                      label: 'Evasão +${definition.stats.evasion}',
                      color: AppTheme.textPrimary,
                    ),
                  _InfoChip(
                    label: '${definition.craftDurationSeconds}s',
                    color: AppTheme.textSecondary,
                  ),
                  _InfoChip(
                    label:
                        '${definition.workshop.displayName} Nv. ${definition.requiredWorkshopLevel}',
                    color: AppTheme.smithingOrange,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _EquipmentCostWrap(cost: definition.cost),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    key: ValueKey<String>('equipment-craft-${definition.id}'),
                    onPressed: canCraft ? () => onCraft(definition.id) : null,
                    icon: const Icon(Icons.handyman_outlined, size: 17),
                    label: const Text('Fabricar'),
                  ),
                  OutlinedButton.icon(
                    key: ValueKey<String>('equipment-equip-${definition.id}'),
                    onPressed: quantity > 0 && !isEquipped
                        ? () => onEquip(definition.id)
                        : null,
                    icon: Icon(
                      isEquipped ? Icons.check_rounded : Icons.shield_outlined,
                      size: 17,
                    ),
                    label: Text(isEquipped ? 'Equipado' : 'Equipar'),
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

class _WorkshopsTab extends StatelessWidget {
  final Map<EquipmentWorkshop, int> levels;

  const _WorkshopsTab({required this.levels});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const PageStorageKey<String>('items-workshops-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: EquipmentWorkshop.values.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _MedievalSceneBanner(
            key: ValueKey<String>('items-workshop-banner'),
            assetPath: MedievalAssets.workshopHall,
            label: 'SALÃO DOS MESTRES ARTESÃOS',
            color: AppTheme.smithingOrange,
          );
        }
        final workshop = EquipmentWorkshop.values[index - 1];
        final heroClass = HeroClass.values.firstWhere(
          (heroClass) => heroClass.workshop == workshop,
        );
        return Card(
          key: ValueKey<String>('workshop-${workshop.saveKey}'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.smithingOrange.withValues(alpha: 0.45),
                    ),
                  ),
                  child: MedievalEmblem(
                    assetPath: MedievalAssets.workshopAsset(workshop.saveKey),
                    size: 42,
                    semanticLabel: workshop.displayName,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workshop.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        workshop.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${heroClass.displayName} • Nível ${levels[workshop] ?? 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.smithingOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlchemyTab extends StatelessWidget {
  final List<PotionDefinition> potions;
  final ContentInventory inventory;
  final Map<String, int> availableMaterials;
  final int alchemyLevel;
  final ActiveBuffs activeBuffs;
  final ValueChanged<String> onBrew;
  final ValueChanged<String> onUse;

  const _AlchemyTab({
    required this.potions,
    required this.inventory,
    required this.availableMaterials,
    required this.alchemyLevel,
    required this.activeBuffs,
    required this.onBrew,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final potionById = {for (final potion in potions) potion.id: potion};
    final buffs =
        activeBuffs.activeByType.values
            .where((buff) => buff.isActiveAt(now))
            .toList(growable: false)
          ..sort(
            (left, right) => left.expiresAtEpochMilliseconds.compareTo(
              right.expiresAtEpochMilliseconds,
            ),
          );

    return ListView(
      key: const PageStorageKey<String>('items-alchemy-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        const _MedievalSceneBanner(
          key: ValueKey<String>('items-alchemy-banner'),
          assetPath: MedievalAssets.alchemyLab,
          label: 'LABORATÓRIO DE ALQUIMIA',
          color: AppTheme.miningGreenLight,
        ),
        const SizedBox(height: 14),
        _ActiveBuffsPanel(buffs: buffs, potionById: potionById, builtAt: now),
        const SizedBox(height: 14),
        Text(
          'RECEITAS DO LABORATÓRIO',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.miningGreenLight,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        if (potions.isEmpty)
          const _EmptyPanel(
            icon: Icons.science_outlined,
            message: 'Nenhuma receita alquímica foi descoberta.',
          )
        else
          for (var index = 0; index < potions.length; index++) ...[
            Builder(
              builder: (context) {
                final potion = potions[index];
                final quantity = inventory.quantityOfConsumable(potion.id);
                final canBrew =
                    alchemyLevel >= potion.requiredLevel &&
                    potion.cost.canAfford(availableMaterials);
                return _ContentCard(
                  key: ValueKey<String>('potion-${potion.id}'),
                  sigil: potion.sigil,
                  title: potion.name,
                  subtitle: potion.description,
                  detail:
                      '${potion.buffType.displayName} +${(potion.potency * 100).round()}% • ${potion.durationSeconds}s',
                  cost: potion.cost.materials,
                  quantity: quantity,
                  primaryLabel: 'Preparar',
                  primaryKey: 'potion-brew-${potion.id}',
                  onPrimary: canBrew ? () => onBrew(potion.id) : null,
                  secondaryLabel: 'Usar',
                  secondaryKey: 'potion-use-${potion.id}',
                  onSecondary: quantity > 0 ? () => onUse(potion.id) : null,
                  color: AppTheme.miningGreenLight,
                );
              },
            ),
            if (index != potions.length - 1) const SizedBox(height: 9),
          ],
      ],
    );
  }
}

class _GrimoireTab extends StatelessWidget {
  final List<SpellDefinition> spells;
  final ContentInventory inventory;
  final Map<String, int> availableMaterials;
  final int magicLevel;
  final String? activeSpellId;
  final ValueChanged<String> onCraft;
  final ValueChanged<String> onUse;

  const _GrimoireTab({
    required this.spells,
    required this.inventory,
    required this.availableMaterials,
    required this.magicLevel,
    required this.activeSpellId,
    required this.onCraft,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    SpellDefinition? activeSpell;
    for (final spell in spells) {
      if (spell.id == activeSpellId) {
        activeSpell = spell;
        break;
      }
    }

    return ListView(
      key: const PageStorageKey<String>('items-grimoire-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _ActiveSpellPanel(
          spell: activeSpell,
          hasUnresolvedLink: activeSpellId != null && activeSpell == null,
        ),
        const SizedBox(height: 14),
        Text(
          'INSCRIÇÕES DO ARCANISTA',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.combatBlue,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 8),
        if (spells.isEmpty)
          const _EmptyPanel(
            icon: Icons.menu_book_outlined,
            message: 'Nenhuma magia foi inscrita no grimório.',
          )
        else
          for (var index = 0; index < spells.length; index++) ...[
            Builder(
              builder: (context) {
                final spell = spells[index];
                final quantity = inventory.quantityOfSpell(spell.id);
                final canCraft =
                    magicLevel >= spell.requiredLevel &&
                    spell.cost.canAfford(availableMaterials);
                final isLinked = spell.id == activeSpellId;
                return _ContentCard(
                  key: ValueKey<String>('spell-${spell.id}'),
                  sigil: spell.sigil,
                  title: spell.name,
                  subtitle: spell.description,
                  detail:
                      '${spell.school.displayName} • Magia Nv. ${spell.requiredLevel}'
                      '${isLinked ? ' • VINCULADA' : ''}',
                  cost: spell.cost.materials,
                  quantity: quantity,
                  primaryLabel: 'Inscrever',
                  primaryKey: 'spell-craft-${spell.id}',
                  onPrimary: canCraft ? () => onCraft(spell.id) : null,
                  secondaryLabel: 'Usar',
                  secondaryKey: 'spell-use-${spell.id}',
                  onSecondary: quantity > 0 ? () => onUse(spell.id) : null,
                  color: isLinked ? AppTheme.accentYellow : AppTheme.combatBlue,
                );
              },
            ),
            if (index != spells.length - 1) const SizedBox(height: 9),
          ],
      ],
    );
  }
}

class _ActiveBuffsPanel extends StatelessWidget {
  final List<ActiveBuff> buffs;
  final Map<String, PotionDefinition> potionById;
  final DateTime builtAt;

  const _ActiveBuffsPanel({
    required this.buffs,
    required this.potionById,
    required this.builtAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey<String>('items-active-buffs'),
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: AppTheme.miningGreenLight,
        opacity: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 18,
                    color: AppTheme.miningGreenLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'EFEITOS ALQUÍMICOS ATIVOS',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.miningGreenLight,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  _QuantityPill(
                    quantity: buffs.length,
                    color: AppTheme.miningGreenLight,
                  ),
                ],
              ),
              const SizedBox(height: 9),
              if (buffs.isEmpty)
                Text(
                  'Nenhum elixir percorre suas veias neste momento.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                for (var index = 0; index < buffs.length; index++) ...[
                  _ActiveBuffRow(
                    key: ValueKey<String>(
                      'active-buff-${buffs[index].type.saveKey}',
                    ),
                    buff: buffs[index],
                    potion: potionById[buffs[index].sourcePotionId],
                    builtAt: builtAt,
                  ),
                  if (index != buffs.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(
                        height: 1,
                        color: AppTheme.miningGreenLight.withValues(alpha: 0.2),
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

class _ActiveBuffRow extends StatelessWidget {
  final ActiveBuff buff;
  final PotionDefinition? potion;
  final DateTime builtAt;

  const _ActiveBuffRow({
    super.key,
    required this.buff,
    required this.potion,
    required this.builtAt,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = buff.remainingAt(builtAt);
    final potency = (buff.potency * 100).round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SigilSeal(
          sigil: potion?.sigil ?? 'ᛟ',
          color: AppTheme.miningGreenLight,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                potion?.name ?? 'Elixir sem registro',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${buff.type.displayName} +$potency%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.miningGreenLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _InfoChip(
          label: _formatRemaining(remaining.inMilliseconds),
          color: AppTheme.miningGreenLight,
        ),
      ],
    );
  }
}

class _ActiveSpellPanel extends StatelessWidget {
  final SpellDefinition? spell;
  final bool hasUnresolvedLink;

  const _ActiveSpellPanel({
    required this.spell,
    required this.hasUnresolvedLink,
  });

  @override
  Widget build(BuildContext context) {
    final linked = spell;
    final title =
        linked?.name ??
        (hasUnresolvedLink
            ? 'Vínculo rúnico corrompido'
            : 'Nenhuma magia vinculada');
    final description =
        linked?.description ??
        (hasUnresolvedLink
            ? 'O sigilo ativo não consta mais nos registros do arcanista.'
            : 'Vincule uma inscrição conhecida para levá-la ao combate.');
    return Card(
      key: const ValueKey<String>('items-active-spell'),
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: linked == null ? AppTheme.textSecondary : AppTheme.accentYellow,
        opacity: linked == null ? 0.3 : 0.62,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SigilSeal(
                sigil: linked?.sigil ?? 'ᚱ',
                color: linked == null
                    ? AppTheme.textSecondary
                    : AppTheme.accentYellow,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linked == null
                          ? 'SEM VÍNCULO RÚNICO'
                          : 'VÍNCULO RÚNICO ATIVO • ${linked.school.displayName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: linked == null
                            ? AppTheme.textSecondary
                            : AppTheme.accentYellow,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  final Map<String, int> materials;

  const _MaterialsTab({required this.materials});

  @override
  Widget build(BuildContext context) {
    final owned = <_OwnedMaterial>[];
    for (final entry in materials.entries) {
      if (entry.value <= 0) continue;
      final resource = GatheringResource.byId(entry.key);
      if (resource != null) {
        owned.add(_OwnedMaterial.fromGathering(resource, entry.value));
        continue;
      }
      final drop = CombatDropCatalog.byId(entry.key);
      if (drop != null) {
        owned.add(_OwnedMaterial.fromDrop(drop, entry.value));
        continue;
      }
      final producers = ProcessingRecipeCatalog.producing(entry.key);
      if (producers.isNotEmpty) {
        owned.add(_OwnedMaterial.fromProcessed(producers.first, entry.value));
      }
    }
    owned.sort((left, right) {
      final groupOrder = left.groupOrder.compareTo(right.groupOrder);
      return groupOrder != 0 ? groupOrder : left.name.compareTo(right.name);
    });
    final totalUnits = owned.fold<int>(
      0,
      (sum, material) => sum + material.quantity,
    );
    final gatheringTypes = owned
        .where((material) => material.groupOrder == 0)
        .length;
    final processedTypes = owned
        .where((material) => material.groupOrder == 1)
        .length;
    final dropTypes = owned
        .where((material) => material.groupOrder == 2)
        .length;

    return ListView(
      key: const PageStorageKey<String>('items-materials-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        Card(
          key: const ValueKey<String>('items-materials-summary'),
          margin: EdgeInsets.zero,
          child: RunicFrame(
            color: AppTheme.smithingOrange,
            opacity: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const _ItemSeal(
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.smithingOrange,
                    size: 44,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESERVAS DO REFÚGIO',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.smithingOrange,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${owned.length} tipos • $totalUnits unidades',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$gatheringTypes de coleta • $processedTypes refinados • $dropTypes de combate',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (owned.isEmpty)
          const _EmptyPanel(
            icon: Icons.inventory_2_outlined,
            message:
                'As reservas estão vazias. Colete recursos e derrote criaturas para obter materiais.',
          )
        else
          for (var index = 0; index < owned.length; index++) ...[
            _MaterialCard(material: owned[index]),
            if (index != owned.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _OwnedMaterial {
  final String id;
  final String name;
  final String description;
  final String category;
  final int quantity;
  final int groupOrder;
  final IconData? icon;
  final String? sigil;
  final Color color;

  const _OwnedMaterial({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.quantity,
    required this.groupOrder,
    required this.icon,
    required this.sigil,
    required this.color,
  });

  factory _OwnedMaterial.fromGathering(
    GatheringResource resource,
    int quantity,
  ) {
    return _OwnedMaterial(
      id: resource.id,
      name: resource.name,
      description: resource.description,
      category: 'COLETA • ${resource.discipline.displayName.toUpperCase()}',
      quantity: quantity,
      groupOrder: 0,
      icon: _gatheringIcon(resource.discipline),
      sigil: null,
      color: _gatheringRarityColor(resource.rarity),
    );
  }

  factory _OwnedMaterial.fromDrop(CombatDropDefinition drop, int quantity) {
    return _OwnedMaterial(
      id: drop.id,
      name: drop.name,
      description: drop.description,
      category: 'SAQUE • ${_dropRarityName(drop.rarity).toUpperCase()}',
      quantity: quantity,
      groupOrder: 2,
      icon: null,
      sigil: drop.sigil,
      color: _dropRarityColor(drop.rarity),
    );
  }

  factory _OwnedMaterial.fromProcessed(ProcessingRecipe recipe, int quantity) {
    final name = switch (recipe) {
      SmeltingRecipe(:final material) =>
        'Barra de ${material.displayName.toLowerCase()}',
      ArcaneRefiningRecipe() => 'Lingote arcano',
      SkewerRecipe() => 'Espeto de madeira',
      ShaftRecipe(:final wood) => ShaftRecipeCatalog.shaftNameFor(wood.id),
      _ => recipe.name,
    };
    final color = switch (recipe.kind) {
      ProcessingKind.smelting => AppTheme.smithingOrange,
      ProcessingKind.arcaneRefining => AppTheme.combatBlue,
      ProcessingKind.cooking => AppTheme.combatRed,
      ProcessingKind.woodworking => AppTheme.miningGreenLight,
    };
    final icon = switch (recipe.kind) {
      ProcessingKind.smelting => Icons.local_fire_department_outlined,
      ProcessingKind.arcaneRefining => Icons.diamond_outlined,
      ProcessingKind.cooking => Icons.outdoor_grill_outlined,
      ProcessingKind.woodworking => Icons.carpenter_outlined,
    };
    return _OwnedMaterial(
      id: recipe.output.resourceId,
      name: name,
      description: recipe.description,
      category: 'OFÍCIO • ${recipe.kind.displayName.toUpperCase()}',
      quantity: quantity,
      groupOrder: 1,
      icon: icon,
      sigil: null,
      color: color,
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final _OwnedMaterial material;

  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey<String>('material-${material.id}'),
      margin: EdgeInsets.zero,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: material.color.withValues(alpha: 0.46)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (material.sigil != null)
              _SigilSeal(sigil: material.sigil!, color: material.color)
            else
              _ItemSeal(
                icon: material.icon ?? Icons.category_outlined,
                color: material.color,
                size: 42,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: material.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    material.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    material.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _QuantityPill(quantity: material.quantity, color: material.color),
          ],
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String sigil;
  final String title;
  final String subtitle;
  final String detail;
  final Map<String, int> cost;
  final int quantity;
  final String primaryLabel;
  final String primaryKey;
  final VoidCallback? onPrimary;
  final String secondaryLabel;
  final String secondaryKey;
  final VoidCallback? onSecondary;
  final Color color;

  const _ContentCard({
    super.key,
    required this.sigil,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.cost,
    required this.quantity,
    required this.primaryLabel,
    required this.primaryKey,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.secondaryKey,
    required this.onSecondary,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: color,
        opacity: 0.42,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SigilSeal(sigil: sigil, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _QuantityPill(quantity: quantity, color: color),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _ResourceCostWrap(resources: cost),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    key: ValueKey<String>(primaryKey),
                    onPressed: onPrimary,
                    child: Text(primaryLabel),
                  ),
                  OutlinedButton(
                    key: ValueKey<String>(secondaryKey),
                    onPressed: onSecondary,
                    child: Text(secondaryLabel),
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

class _EquipmentCostWrap extends StatelessWidget {
  final EquipmentCost cost;

  const _EquipmentCostWrap({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _InfoChip(label: '${cost.gold} ouro', color: AppTheme.accentYellow),
        for (final entry in cost.resources.entries)
          _InfoChip(
            label: '${_materialDisplayName(entry.key)} ×${entry.value}',
            color: AppTheme.smithingOrange,
          ),
      ],
    );
  }
}

class _ResourceCostWrap extends StatelessWidget {
  final Map<String, int> resources;

  const _ResourceCostWrap({required this.resources});

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return Text('Sem custo', style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in resources.entries)
          _InfoChip(
            label: '${_materialDisplayName(entry.key)} ×${entry.value}',
            color: AppTheme.smithingOrange,
          ),
      ],
    );
  }
}

String _materialDisplayName(String resourceId) {
  final gathering = GatheringResource.byId(resourceId);
  if (gathering != null) return gathering.name;
  final drop = CombatDropCatalog.byId(resourceId);
  if (drop != null) return drop.name;
  final producers = ProcessingRecipeCatalog.producing(resourceId);
  if (producers.isEmpty) return resourceId;
  return switch (producers.first) {
    SmeltingRecipe(:final material) =>
      'Barra de ${material.displayName.toLowerCase()}',
    ArcaneRefiningRecipe() => 'Lingote arcano',
    SkewerRecipe() => 'Espeto de madeira',
    ShaftRecipe(:final wood) => ShaftRecipeCatalog.shaftNameFor(wood.id),
    final recipe => recipe.name,
  };
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

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

class _QuantityPill extends StatelessWidget {
  final int quantity;
  final Color color;

  const _QuantityPill({required this.quantity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        '×$quantity',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItemSeal extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String? imageAsset;
  final Color? imageTint;

  const _ItemSeal({
    required this.icon,
    required this.color,
    required this.size,
    this.imageAsset,
    this.imageTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: imageAsset == null
          ? Icon(icon, color: color, size: size * 0.5)
          : ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.asset(
                imageAsset!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.none,
                color: imageTint,
                colorBlendMode: imageTint == null ? null : BlendMode.modulate,
                // Cobre classes cuja arte-base ainda não foi gerada (ex.:
                // knight em `gathering/equipamentos/`) — volta pro ícone
                // genérico em vez de estourar erro de asset ausente.
                errorBuilder: (context, error, stackTrace) =>
                    Icon(icon, color: color, size: size * 0.5),
              ),
            ),
    );
  }
}

class _SigilSeal extends StatelessWidget {
  final String sigil;
  final Color color;

  const _SigilSeal({required this.sigil, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        sigil,
        style: TextStyle(
          color: color,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPanel({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _auraElevation(double intensity) =>
    (intensity.clamp(0, 1) * 8).toDouble();

double _auraShadowOpacity(double intensity) =>
    (0.12 + (intensity.clamp(0, 1) * 0.58)).clamp(0, 0.7).toDouble();

double _rarityBorderWidth(int tier) =>
    (1 + (tier.clamp(0, 9) * 0.15)).clamp(1, 2.35).toDouble();

Color _rarityColor(EquipmentRarity rarity) =>
    Color(0xFF000000 | rarity.accentRgb);

Color _gatheringRarityColor(GatheringRarity rarity) => switch (rarity) {
  GatheringRarity.common => AppTheme.textSecondary,
  GatheringRarity.uncommon => AppTheme.miningGreenLight,
  GatheringRarity.rare => AppTheme.combatBlue,
  GatheringRarity.epic => const Color(0xFF9271BB),
  GatheringRarity.legendary => AppTheme.accentYellow,
  GatheringRarity.magical => const Color(0xFF4EB6B1),
};

Color _dropRarityColor(CombatDropRarity rarity) => switch (rarity) {
  CombatDropRarity.common => AppTheme.textSecondary,
  CombatDropRarity.uncommon => AppTheme.miningGreenLight,
  CombatDropRarity.rare => AppTheme.combatBlue,
  CombatDropRarity.epic => const Color(0xFF9271BB),
  CombatDropRarity.legendary => AppTheme.accentYellow,
};

String _dropRarityName(CombatDropRarity rarity) => switch (rarity) {
  CombatDropRarity.common => 'Comum',
  CombatDropRarity.uncommon => 'Incomum',
  CombatDropRarity.rare => 'Raro',
  CombatDropRarity.epic => 'Épico',
  CombatDropRarity.legendary => 'Lendário',
};

IconData _gatheringIcon(GatheringDiscipline discipline) => switch (discipline) {
  GatheringDiscipline.mining => Icons.diamond_outlined,
  GatheringDiscipline.woodcutting => Icons.forest_outlined,
  GatheringDiscipline.fishing => Icons.water_outlined,
};

IconData _slotIcon(EquipmentSlot slot) => switch (slot) {
  EquipmentSlot.head => Icons.face_retouching_natural,
  EquipmentSlot.body => Icons.checkroom_outlined,
  EquipmentSlot.legs => Icons.airline_seat_legroom_normal,
  EquipmentSlot.feet => Icons.ice_skating_outlined,
  EquipmentSlot.weapon => Icons.gavel_outlined,
  EquipmentSlot.offhand => Icons.shield_outlined,
};
