import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/features/content/models/world_region.dart';

class MapsScreen extends StatelessWidget {
  final List<WorldRegion> regions;
  final String? selectedRegionId;
  final int combatLevel;
  final Map<String, int> skillLevels;
  final Set<String> completedRegionIds;
  final ValueChanged<String> onSelectRegion;

  const MapsScreen({
    super.key,
    required this.regions,
    required this.selectedRegionId,
    required this.combatLevel,
    required this.skillLevels,
    required this.completedRegionIds,
    required this.onSelectRegion,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedCount = regions
        .where(
          (region) => region.requirement.isMet(
            combatLevel: combatLevel,
            skillLevels: skillLevels,
            completedRegionIds: completedRegionIds,
          ),
        )
        .length;

    return SingleChildScrollView(
      key: const PageStorageKey<String>('maps-screen-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MapsHeader(
            combatLevel: combatLevel,
            unlockedCount: unlockedCount,
            regionCount: regions.length,
          ),
          const SizedBox(height: 8),
          const RunicDivider(height: 24, maxWidth: 220),
          const SizedBox(height: 8),
          const _WorldMapBanner(),
          const SizedBox(height: 14),
          _MapNotice(selectedRegionId: selectedRegionId),
          const SizedBox(height: 18),
          _SectionTitle(detail: '$unlockedCount de ${regions.length} abertas'),
          const SizedBox(height: 9),
          if (regions.isEmpty)
            const _EmptyRegions()
          else
            for (var index = 0; index < regions.length; index++) ...[
              _RegionCard(
                region: regions[index],
                regions: regions,
                isSelected: selectedRegionId == regions[index].id,
                isUnlocked: regions[index].requirement.isMet(
                  combatLevel: combatLevel,
                  skillLevels: skillLevels,
                  completedRegionIds: completedRegionIds,
                ),
                onSelect: onSelectRegion,
              ),
              if (index < regions.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _MapsHeader extends StatelessWidget {
  final int combatLevel;
  final int unlockedCount;
  final int regionCount;

  const _MapsHeader({
    required this.combatLevel,
    required this.unlockedCount,
    required this.regionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const _MapSeal(),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mapas',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.miningGreenLight,
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Regiões, lendas e oficinas do reino fragmentado.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final combatMetric = _HeaderMetric(
              icon: Icons.shield_outlined,
              label: 'Nível de combate',
              value: '$combatLevel',
              color: AppTheme.combatRed,
            );
            final regionsMetric = _HeaderMetric(
              icon: Icons.explore_outlined,
              label: 'Regiões abertas',
              value: '$unlockedCount / $regionCount',
              color: AppTheme.miningGreenLight,
            );

            if (constraints.maxWidth < 340) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  combatMetric,
                  const SizedBox(height: 8),
                  regionsMetric,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: combatMetric),
                const SizedBox(width: 8),
                Expanded(child: regionsMetric),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MapSeal extends StatelessWidget {
  const _MapSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.miningGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.miningGreenLight.withValues(alpha: 0.52),
        ),
      ),
      child: const Icon(
        Icons.map_outlined,
        color: AppTheme.miningGreenLight,
        size: 25,
      ),
    );
  }
}

class _WorldMapBanner extends StatelessWidget {
  const _WorldMapBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('maps-world-banner'),
      height: 108,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.miningGreenLight.withValues(alpha: 0.42),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            MedievalAssets.worldMap,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.none,
            cacheHeight: 324,
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.voidBlack.withValues(alpha: 0.08),
                  AppTheme.voidBlack.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          Positioned(
            left: 11,
            right: 11,
            bottom: 9,
            child: Text(
              'CARTOGRAFIA DO REINO',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.miningGreenLight,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 55),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  final String? selectedRegionId;

  const _MapNotice({required this.selectedRegionId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.miningGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.miningGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: RunicGlyph(size: 11, color: AppTheme.miningGreenLight),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              selectedRegionId == null
                  ? 'Escolha uma região aberta para estabelecer seu destino.'
                  : 'A região destacada é o destino atual. A escolha não altera seus caminhos de classe.',
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

class _SectionTitle extends StatelessWidget {
  final String detail;

  const _SectionTitle({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.public, size: 16, color: AppTheme.miningGreenLight),
        const SizedBox(width: 7),
        Text(
          'REGIÕES',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.miningGreenLight,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _RegionCard extends StatelessWidget {
  final WorldRegion region;
  final List<WorldRegion> regions;
  final bool isSelected;
  final bool isUnlocked;
  final ValueChanged<String> onSelect;

  const _RegionCard({
    required this.region,
    required this.regions,
    required this.isSelected,
    required this.isUnlocked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final primary = _regionColor(region.primaryColorValue);
    final accent = _regionColor(region.accentColorValue);

    return Card(
      key: ValueKey<String>('region-${region.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(
          color: isSelected
              ? accent
              : (isUnlocked ? primary : AppTheme.darkCardBorder),
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        onTap: isUnlocked ? () => onSelect(region.id) : null,
        child: RunicFrame(
          color: isUnlocked ? accent : AppTheme.textSecondary,
          opacity: isSelected ? 0.72 : 0.36,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: isUnlocked ? 0.13 : 0.04),
                  AppTheme.darkCard,
                  AppTheme.voidBlack.withValues(alpha: 0.75),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RegionSigil(
                      sigil: region.sigil,
                      color: isUnlocked ? accent : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isUnlocked
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            region.lore,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: _RegionStatus(
                    isSelected: isSelected,
                    isUnlocked: isUnlocked,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 11),
                if (!isUnlocked)
                  _RequirementPanel(region: region, regions: regions)
                else if (region.workshops.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final workshop in region.workshops)
                        _WorkshopChip(workshop: workshop, color: accent),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionSigil extends StatelessWidget {
  final String sigil;
  final Color color;

  const _RegionSigil({required this.sigil, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.46)),
      ),
      child: Text(
        sigil,
        style: TextStyle(
          color: color,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _RegionStatus extends StatelessWidget {
  final bool isSelected;
  final bool isUnlocked;
  final Color color;

  const _RegionStatus({
    required this.isSelected,
    required this.isUnlocked,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final label = isSelected ? 'ATUAL' : (isUnlocked ? 'IR' : 'BLOQUEADA');
    final icon = isSelected
        ? Icons.location_on_outlined
        : (isUnlocked ? Icons.arrow_forward_rounded : Icons.lock_outline);
    final statusColor = isUnlocked ? color : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: statusColor.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementPanel extends StatelessWidget {
  final WorldRegion region;
  final List<WorldRegion> regions;

  const _RequirementPanel({required this.region, required this.regions});

  @override
  Widget build(BuildContext context) {
    final requirement = region.requirement;
    final labels = <String>[
      if (requirement.requiredCombatLevel > 1)
        'Combate ${requirement.requiredCombatLevel}',
      for (final entry in requirement.requiredSkillLevels.entries)
        '${_skillName(entry.key)} ${entry.value}',
      if (requirement.prerequisiteRegionId != null)
        'Concluir ${_regionName(requirement.prerequisiteRegionId!, regions)}',
    ];

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.darkCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              labels.isEmpty ? 'Requisito oculto' : labels.join('  •  '),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkshopChip extends StatelessWidget {
  final WorkshopType workshop;
  final Color color;

  const _WorkshopChip({required this.workshop, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: workshop.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MedievalEmblem(
              assetPath: MedievalAssets.workshopAsset(
                _workshopAssetKey(workshop),
              ),
              size: 13,
              semanticLabel: workshop.displayName,
            ),
            const SizedBox(width: 4),
            Text(
              workshop.displayName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRegions extends StatelessWidget {
  const _EmptyRegions();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Nenhuma região foi registrada neste mapa.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _regionColor(int value) {
  final argb = value <= 0xFFFFFF ? 0xFF000000 | value : value;
  return Color(argb);
}

String _regionName(String id, List<WorldRegion> regions) {
  for (final region in regions) {
    if (region.id == id) return region.name;
  }
  return id;
}

String _skillName(String id) => switch (id) {
  'mining' => 'Mineração',
  'woodcutting' => 'Corte de madeira',
  'fishing' => 'Pesca',
  'attack' => 'Ataque',
  'defense' => 'Defesa',
  'magic' => 'Magia',
  _ => id,
};

String _workshopAssetKey(WorkshopType workshop) => switch (workshop) {
  WorkshopType.forge => 'blacksmith',
  WorkshopType.artisanWorkshop => 'artisan',
  WorkshopType.arcanistSanctum => 'arcanist',
  WorkshopType.shadowAtelier => 'veil_guild',
  WorkshopType.alchemyLaboratory => 'alchemy_lab',
};
