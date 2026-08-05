import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/core/utils/number_formatters.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/processing/data/processing_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/shaft_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';
import 'package:realm_idle_game/features/tools/data/tool_catalog.dart';
import 'package:realm_idle_game/features/tools/models/tool_models.dart';
import 'package:realm_idle_game/models/game_state.dart';

class ToolsScreen extends StatefulWidget {
  final GameState gameState;
  final VoidCallback onStateChanged;
  final GatheringDiscipline initialDiscipline;

  const ToolsScreen({
    super.key,
    required this.gameState,
    required this.onStateChanged,
    this.initialDiscipline = GatheringDiscipline.mining,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late GatheringDiscipline _selectedDiscipline;

  @override
  void initState() {
    super.initState();
    _selectedDiscipline = widget.initialDiscipline;
  }

  void _selectDiscipline(GatheringDiscipline discipline) {
    if (_selectedDiscipline == discipline) return;
    setState(() => _selectedDiscipline = discipline);
  }

  void _performAction(
    ToolActionResult Function() action, {
    required String successMessage,
  }) {
    final result = action();
    if (!mounted) return;

    if (result == ToolActionResult.success) {
      setState(() {});
      widget.onStateChanged();
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          result == ToolActionResult.success
              ? successMessage
              : _toolActionError(result),
        ),
      ),
    );
  }

  void _acquire(ToolDefinition tool) {
    _performAction(
      () => widget.gameState.acquireTool(tool.id),
      successMessage: '${tool.name} foi fabricada.',
    );
  }

  void _equip(ToolDefinition tool) {
    _performAction(
      () => widget.gameState.equipTool(tool.id),
      successMessage: '${tool.name} foi equipada.',
    );
  }

  void _upgrade(ToolDefinition tool) {
    _performAction(
      () => widget.gameState.upgradeTool(tool.id),
      successMessage: '${tool.name} foi melhorada.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tools = ToolCatalog.forDiscipline(_selectedDiscipline);
    final equipped = widget.gameState.equippedToolDefinition(
      _selectedDiscipline,
    );
    final color = _disciplineColor(_selectedDiscipline);

    return SingleChildScrollView(
      key: const PageStorageKey<String>('tools-screen-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ToolsHeader(
            discipline: _selectedDiscipline,
            gold: widget.gameState.gold,
          ),
          const SizedBox(height: 12),
          const _NoExperienceNotice(),
          const SizedBox(height: 14),
          _ToolDisciplineSelector(
            selected: _selectedDiscipline,
            onSelected: _selectDiscipline,
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'EQUIPADA',
            detail: _selectedDiscipline.displayName,
            color: color,
          ),
          const SizedBox(height: 8),
          _EquippedToolCard(
            gameState: widget.gameState,
            tool: equipped,
            onUpgrade: () => _upgrade(equipped),
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'ARSENAL',
            detail: '${tools.length} ferramentas',
            color: color,
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < tools.length; index++) ...[
            _ToolArsenalCard(
              gameState: widget.gameState,
              tool: tools[index],
              equippedToolId: equipped.id,
              onAcquire: () => _acquire(tools[index]),
              onEquip: () => _equip(tools[index]),
              onUpgrade: () => _upgrade(tools[index]),
            ),
            if (index < tools.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ToolsHeader extends StatelessWidget {
  final GatheringDiscipline discipline;
  final int gold;

  const _ToolsHeader({required this.discipline, required this.gold});

  @override
  Widget build(BuildContext context) {
    final color = _disciplineColor(discipline);
    return Row(
      children: [
        MedievalEmblem(
          assetPath: _disciplineAsset(discipline),
          size: 44,
          semanticLabel: 'Ferramentas de ${discipline.displayName}',
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ferramentas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.accentYellow,
                  fontSize: 24,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Equipe bônus passivos para a Colheita.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.voidBlack.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withValues(alpha: 0.62)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on,
                size: 15,
                color: AppTheme.accentYellow,
              ),
              const SizedBox(width: 4),
              Text(
                formatInteger(gold),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.accentYellow,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoExperienceNotice extends StatelessWidget {
  const _NoExperienceNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.bronze.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.bronze.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: RunicGlyph(size: 11, opacity: 0.9),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Fabricar, equipar e melhorar não concede XP. '
              'Moedas de ouro vêm do Combate; os materiais, da Colheita. '
              'Os bônus são aplicados automaticamente aos próximos ciclos.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolDisciplineSelector extends StatelessWidget {
  final GatheringDiscipline selected;
  final ValueChanged<GatheringDiscipline> onSelected;

  const _ToolDisciplineSelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tipo de ferramenta',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.darkCardRaised, AppTheme.voidBlack],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppTheme.darkCardBorder),
        ),
        child: Row(
          children: [
            for (final discipline in GatheringDiscipline.values)
              Expanded(
                child: _ToolDisciplineSegment(
                  discipline: discipline,
                  selected: selected == discipline,
                  onTap: () => onSelected(discipline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToolDisciplineSegment extends StatelessWidget {
  final GatheringDiscipline discipline;
  final bool selected;
  final VoidCallback onTap;

  const _ToolDisciplineSegment({
    required this.discipline,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _disciplineColor(discipline);
    final content = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
        border: selected
            ? Border.all(color: color.withValues(alpha: 0.68))
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_disciplineIcon(discipline), size: 25, color: color),
          const SizedBox(height: 5),
          Text(
            _disciplineToolLabel(discipline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: _disciplineToolLabel(discipline),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('tools-discipline-${discipline.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: selected
              ? RunicFrame(color: color, opacity: 0.58, child: content)
              : content,
        ),
      ),
    );
  }
}

class _EquippedToolCard extends StatelessWidget {
  final GameState gameState;
  final ToolDefinition tool;
  final VoidCallback onUpgrade;

  const _EquippedToolCard({
    required this.gameState,
    required this.tool,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final owned = gameState.ownedTool(tool.id);
    final upgradeLevel = owned?.upgradeLevel ?? 0;
    final upgradeCost = tool.upgradeCostFor(upgradeLevel);
    final canAfford =
        upgradeCost != null && gameState.canAffordToolCost(upgradeCost);
    final color = _disciplineColor(tool.discipline);

    return Card(
      key: const ValueKey<String>('equipped-tool-card'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: color, width: 1.5),
      ),
      child: RunicFrame(
        color: color,
        opacity: 0.62,
        cornerLength: 13,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.13), AppTheme.darkCard],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToolIdentityRow(
                tool: tool,
                upgradeLevel: upgradeLevel,
                status: 'EQUIPADA',
                statusColor: color,
              ),
              const SizedBox(height: 13),
              _ToolStats(tool: tool, upgradeLevel: upgradeLevel),
              const SizedBox(height: 12),
              _UpgradePreview(tool: tool, upgradeLevel: upgradeLevel),
              const SizedBox(height: 12),
              _UpgradeButton(
                key: ValueKey<String>('tool-upgrade-${tool.id}-featured'),
                tool: tool,
                upgradeLevel: upgradeLevel,
                cost: upgradeCost,
                canAfford: canAfford,
                onPressed: onUpgrade,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolArsenalCard extends StatelessWidget {
  final GameState gameState;
  final ToolDefinition tool;
  final String equippedToolId;
  final VoidCallback onAcquire;
  final VoidCallback onEquip;
  final VoidCallback onUpgrade;

  const _ToolArsenalCard({
    required this.gameState,
    required this.tool,
    required this.equippedToolId,
    required this.onAcquire,
    required this.onEquip,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final owned = gameState.ownedTool(tool.id);
    final isOwned = owned != null;
    final isEquipped = equippedToolId == tool.id;
    final skillLevel = gameState.skillLevelFor(tool.discipline);
    final isLevelLocked = skillLevel < tool.requiredSkillLevel;
    final canAcquire =
        !isOwned &&
        !isLevelLocked &&
        gameState.canAffordToolCost(tool.purchaseCost);
    final upgradeLevel = owned?.upgradeLevel ?? 0;
    final upgradeCost = isOwned ? tool.upgradeCostFor(upgradeLevel) : null;
    final canUpgrade =
        upgradeCost != null &&
        !isLevelLocked &&
        gameState.canAffordToolCost(upgradeCost);
    final color = _disciplineColor(tool.discipline);

    final status = _toolStatus(
      isOwned: isOwned,
      isEquipped: isEquipped,
      isLevelLocked: isLevelLocked,
      canAcquire: canAcquire,
    );

    final card = Card(
      key: ValueKey<String>('tool-card-${tool.id}'),
      margin: EdgeInsets.zero,
      elevation: isEquipped ? 4 : 1,
      clipBehavior: Clip.antiAlias,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(
          color: isEquipped
              ? color
              : AppTheme.darkCardBorder.withValues(
                  alpha: isLevelLocked ? 0.55 : 1,
                ),
          width: isEquipped ? 1.5 : 1,
        ),
      ),
      child: AnimatedOpacity(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        opacity: isLevelLocked ? 0.62 : 1,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ToolIdentityRow(
                tool: tool,
                upgradeLevel: upgradeLevel,
                status: status.label,
                statusColor: status.color,
                muted: isLevelLocked,
              ),
              const SizedBox(height: 11),
              Text(
                tool.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 11),
              _ToolStats(tool: tool, upgradeLevel: upgradeLevel),
              const SizedBox(height: 11),
              if (!isOwned)
                _PurchaseDetails(
                  tool: tool,
                  skillLevel: skillLevel,
                  isLevelLocked: isLevelLocked,
                  canAfford: gameState.canAffordToolCost(tool.purchaseCost),
                )
              else
                _UpgradePreview(tool: tool, upgradeLevel: upgradeLevel),
              const SizedBox(height: 11),
              if (!isOwned)
                _AcquireButton(
                  key: ValueKey<String>('tool-acquire-${tool.id}'),
                  tool: tool,
                  isLevelLocked: isLevelLocked,
                  canAcquire: canAcquire,
                  onPressed: onAcquire,
                )
              else
                Row(
                  children: [
                    if (!isEquipped) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          key: ValueKey<String>('tool-equip-${tool.id}'),
                          onPressed: isLevelLocked ? null : onEquip,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 17,
                          ),
                          label: const Text('Equipar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: _UpgradeButton(
                        key: ValueKey<String>('tool-upgrade-${tool.id}'),
                        tool: tool,
                        upgradeLevel: upgradeLevel,
                        cost: upgradeCost,
                        canAfford: canUpgrade,
                        onPressed: onUpgrade,
                        compact: true,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );

    if (!isEquipped) return card;
    return RunicFrame(color: color, opacity: 0.48, child: card);
  }
}

class _ToolIdentityRow extends StatelessWidget {
  final ToolDefinition tool;
  final int upgradeLevel;
  final String status;
  final Color statusColor;
  final bool muted;

  const _ToolIdentityRow({
    required this.tool,
    required this.upgradeLevel,
    required this.status,
    required this.statusColor,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MedievalEmblem(
          assetPath: MedievalAssets.toolAsset(tool.id),
          size: 46,
          muted: muted,
          semanticLabel: tool.name,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Tier ${tool.tier + 1}  •  Melhoria $upgradeLevel/${tool.maxUpgradeLevel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _StatusPill(label: status, color: statusColor),
      ],
    );
  }
}

class _ToolStats extends StatelessWidget {
  final ToolDefinition tool;
  final int upgradeLevel;

  const _ToolStats({required this.tool, required this.upgradeLevel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCell(
            icon: Icons.speed_rounded,
            label: 'Velocidade',
            value: '${_formatMultiplier(tool.speedForUpgrade(upgradeLevel))}×',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCell(
            icon: Icons.inventory_2_outlined,
            label: 'Rendimento',
            value: '${_formatMultiplier(tool.yieldForUpgrade(upgradeLevel))}×',
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.darkCardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.bronze),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 9),
                ),
                Text(
                  value,
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseDetails extends StatelessWidget {
  final ToolDefinition tool;
  final int skillLevel;
  final bool isLevelLocked;
  final bool canAfford;

  const _PurchaseDetails({
    required this.tool,
    required this.skillLevel,
    required this.isLevelLocked,
    required this.canAfford,
  });

  @override
  Widget build(BuildContext context) {
    final costColor = canAfford ? AppTheme.textPrimary : AppTheme.combatRed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLevelLocked
                  ? Icons.lock_outline_rounded
                  : Icons.military_tech_outlined,
              size: 15,
              color: isLevelLocked
                  ? AppTheme.textSecondary
                  : AppTheme.miningGreenLight,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                isLevelLocked
                    ? 'Requer ${tool.discipline.displayName} Nível ${tool.requiredSkillLevel} '
                          '(atual: $skillLevel)'
                    : 'Requisito de habilidade atendido',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.handyman_outlined, size: 15, color: costColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Custo: ${_formatCost(tool.purchaseCost)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: costColor, fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UpgradePreview extends StatelessWidget {
  final ToolDefinition tool;
  final int upgradeLevel;

  const _UpgradePreview({required this.tool, required this.upgradeLevel});

  @override
  Widget build(BuildContext context) {
    final cost = tool.upgradeCostFor(upgradeLevel);
    if (cost == null) {
      return Text(
        'Melhoria máxima alcançada.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.accentYellow,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final nextLevel = upgradeLevel + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Próxima melhoria',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_formatMultiplier(tool.speedForUpgrade(upgradeLevel))}× → '
          '${_formatMultiplier(tool.speedForUpgrade(nextLevel))}× velocidade  •  '
          '${_formatMultiplier(tool.yieldForUpgrade(upgradeLevel))}× → '
          '${_formatMultiplier(tool.yieldForUpgrade(nextLevel))}× rendimento',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          'Custo: ${_formatCost(cost)}  •  aplicada no próximo ciclo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _AcquireButton extends StatelessWidget {
  final ToolDefinition tool;
  final bool isLevelLocked;
  final bool canAcquire;
  final VoidCallback onPressed;

  const _AcquireButton({
    super.key,
    required this.tool,
    required this.isLevelLocked,
    required this.canAcquire,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = isLevelLocked
        ? 'Requer Nível ${tool.requiredSkillLevel}'
        : canAcquire
        ? 'Fabricar'
        : 'Ouro ou materiais insuficientes';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canAcquire ? onPressed : null,
        icon: Icon(
          isLevelLocked ? Icons.lock_outline_rounded : Icons.handyman_outlined,
          size: 17,
        ),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final ToolDefinition tool;
  final int upgradeLevel;
  final ToolCost? cost;
  final bool canAfford;
  final VoidCallback onPressed;
  final bool compact;

  const _UpgradeButton({
    super.key,
    required this.tool,
    required this.upgradeLevel,
    required this.cost,
    required this.canAfford,
    required this.onPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMax = cost == null || upgradeLevel >= tool.maxUpgradeLevel;
    final label = isMax
        ? 'MÁXIMO'
        : canAfford
        ? 'Melhorar +${upgradeLevel + 1}'
        : compact
        ? 'Faltam recursos'
        : 'Ouro ou materiais insuficientes';

    return ElevatedButton.icon(
      onPressed: !isMax && canAfford ? onPressed : null,
      icon: Icon(
        isMax ? Icons.workspace_premium_outlined : Icons.upgrade_rounded,
        size: 17,
      ),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String detail;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RunicGlyph(size: 9, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.62)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

({String label, Color color}) _toolStatus({
  required bool isOwned,
  required bool isEquipped,
  required bool isLevelLocked,
  required bool canAcquire,
}) {
  if (isEquipped) return (label: 'EQUIPADA', color: AppTheme.accentYellow);
  if (isOwned) return (label: 'POSSUÍDA', color: AppTheme.miningGreenLight);
  if (isLevelLocked) return (label: 'BLOQUEADA', color: AppTheme.textSecondary);
  if (canAcquire) return (label: 'DISPONÍVEL', color: AppTheme.accentYellow);
  return (label: 'CUSTO PENDENTE', color: AppTheme.textSecondary);
}

String _toolActionError(ToolActionResult result) => switch (result) {
  ToolActionResult.success => 'Ação concluída.',
  ToolActionResult.unknownTool => 'Ferramenta desconhecida.',
  ToolActionResult.alreadyOwned => 'Essa ferramenta já foi fabricada.',
  ToolActionResult.notOwned => 'Você ainda não possui essa ferramenta.',
  ToolActionResult.wrongDiscipline =>
    'Essa ferramenta não serve para esta atividade.',
  ToolActionResult.skillLevelRequired =>
    'Seu nível de habilidade ainda é insuficiente.',
  ToolActionResult.insufficientGold => 'Moedas de ouro insuficientes.',
  ToolActionResult.insufficientResources => 'Recursos insuficientes.',
  ToolActionResult.maxUpgradeReached => 'A ferramenta já está no nível máximo.',
};

Color _disciplineColor(GatheringDiscipline discipline) => switch (discipline) {
  GatheringDiscipline.mining => AppTheme.bronze,
  GatheringDiscipline.woodcutting => AppTheme.miningGreenLight,
  GatheringDiscipline.fishing => AppTheme.combatBlue,
};

String _disciplineAsset(GatheringDiscipline discipline) => switch (discipline) {
  GatheringDiscipline.mining => MedievalAssets.mining,
  GatheringDiscipline.woodcutting => MedievalAssets.woodcutting,
  GatheringDiscipline.fishing => MedievalAssets.fishing,
};

IconData _disciplineIcon(GatheringDiscipline discipline) =>
    switch (discipline) {
      GatheringDiscipline.mining => Icons.hardware_outlined,
      GatheringDiscipline.woodcutting => Icons.park_outlined,
      GatheringDiscipline.fishing => Icons.phishing_rounded,
    };

String _disciplineToolLabel(GatheringDiscipline discipline) =>
    switch (discipline) {
      GatheringDiscipline.mining => 'Picaretas',
      GatheringDiscipline.woodcutting => 'Machados',
      GatheringDiscipline.fishing => 'Varas',
    };

String _formatCost(ToolCost cost) {
  final parts = <String>[];
  if (cost.gold > 0) {
    final currency = cost.gold == 1 ? 'moeda de ouro' : 'moedas de ouro';
    parts.add('${formatInteger(cost.gold)} $currency');
  }
  for (final entry in cost.resources.entries) {
    parts.add('${entry.value}× ${_resourceDisplayName(entry.key)}');
  }
  return parts.isEmpty ? 'Sem custo' : parts.join('  •  ');
}

String _resourceDisplayName(String resourceId) {
  final resource = GatheringResource.byId(resourceId);
  if (resource != null) return resource.name;
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

String _formatMultiplier(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');
