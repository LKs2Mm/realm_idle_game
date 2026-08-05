part of '../gathering_screen.dart';

class _GatheringResourceList extends StatelessWidget {
  final GameState gameState;
  final List<GatheringResource> resources;
  final ValueChanged<GatheringResource> onSelect;

  const _GatheringResourceList({
    required this.gameState,
    required this.resources,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final session = gameState.activeGatheringSession;
    return Column(
      children: [
        for (var index = 0; index < resources.length; index++) ...[
          _GatheringResourceTile(
            gameState: gameState,
            resource: resources[index],
            isActive: session?.resourceId == resources[index].id,
            isQueued: session?.queuedResourceId == resources[index].id,
            hasActiveSession: session != null,
            onSelect: () => onSelect(resources[index]),
          ),
          if (index < resources.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _GatheringResourceTile extends StatelessWidget {
  final GameState gameState;
  final GatheringResource resource;
  final bool isActive;
  final bool isQueued;
  final bool hasActiveSession;
  final VoidCallback onSelect;

  const _GatheringResourceTile({
    required this.gameState,
    required this.resource,
    required this.isActive,
    required this.isQueued,
    required this.hasActiveSession,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !gameState.canGather(resource);
    final canSelect = !isLocked && !isActive && !isQueued;
    final rarityColor = resource.rarity.color;
    final borderColor = isActive || isQueued
        ? resource.discipline.accentColor
        : rarityColor.withValues(alpha: isLocked ? 0.12 : 0.35);
    final actualDuration = gameState.gatheringCycleDurationMilliseconds(
      resource,
    );
    final quantity = gameState.gatheringYieldPerCycle(resource);

    return Semantics(
      button: canSelect,
      enabled: canSelect,
      selected: isActive || isQueued,
      label: isLocked
          ? '${resource.name}, bloqueado até o nível ${resource.requiredLevel}'
          : resource.name,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isActive || isQueued ? 4 : 1,
        clipBehavior: Clip.antiAlias,
        shape: BeveledRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          side: BorderSide(
            color: borderColor,
            width: isActive || isQueued ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: canSelect ? onSelect : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: isLocked ? 0.82 : 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ResourceGlyph(resource: resource, locked: isLocked),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                resource.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              resource.rarity.label,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: rarityColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resource.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: 10, height: 1.25),
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 9,
                          runSpacing: 4,
                          children: [
                            _ResourceMeta(
                              icon: Icons.military_tech_outlined,
                              label: 'Nv. ${resource.requiredLevel}',
                            ),
                            _ResourceMeta(
                              icon: Icons.schedule_outlined,
                              label: _formatDurationMilliseconds(
                                actualDuration,
                              ),
                            ),
                            _ResourceMeta(
                              icon: Icons.auto_awesome_outlined,
                              label:
                                  '+${formatXp(resource.experiencePerCycle)} XP',
                            ),
                            _ResourceMeta(
                              icon: Icons.inventory_2_outlined,
                              label: '×${_formatYield(quantity)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ResourceSelectionStatus(
                    resource: resource,
                    isLocked: isLocked,
                    isActive: isActive,
                    isQueued: isQueued,
                    hasActiveSession: hasActiveSession,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ResourceMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

class _ResourceSelectionStatus extends StatelessWidget {
  final GatheringResource resource;
  final bool isLocked;
  final bool isActive;
  final bool isQueued;
  final bool hasActiveSession;

  const _ResourceSelectionStatus({
    required this.resource,
    required this.isLocked,
    required this.isActive,
    required this.isQueued,
    required this.hasActiveSession,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return _GatheringStatusPill(
        label: 'Nv. ${resource.requiredLevel}',
        color: AppTheme.textSecondary,
        icon: Icons.lock_outline_rounded,
      );
    }
    if (isActive) {
      return _GatheringStatusPill(
        label: 'ATIVO',
        color: resource.discipline.accentColor,
        icon: Icons.play_arrow_rounded,
      );
    }
    if (isQueued) {
      return _GatheringStatusPill(
        label: 'PRÓXIMO',
        color: AppTheme.accentYellow,
        icon: Icons.skip_next_rounded,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasActiveSession
              ? Icons.add_to_queue_rounded
              : Icons.play_circle_outline_rounded,
          color: resource.discipline.accentColor,
          size: 23,
        ),
        const SizedBox(height: 3),
        Text(
          hasActiveSession ? 'Próximo' : 'Iniciar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: resource.discipline.accentColor,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
