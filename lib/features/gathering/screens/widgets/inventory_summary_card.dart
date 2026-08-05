part of '../gathering_screen.dart';

class _GatheringInventorySummaryCard extends StatelessWidget {
  final GameState gameState;
  final GatheringDiscipline discipline;

  const _GatheringInventorySummaryCard({
    required this.gameState,
    required this.discipline,
  });

  @override
  Widget build(BuildContext context) {
    final collected = GatheringResource.forDiscipline(discipline)
        .map(
          (resource) => MapEntry(
            resource,
            gameState.gatheringInventory.quantityOf(resource.id),
          ),
        )
        .where((entry) => entry.value > 0)
        .toList();
    final total = collected.fold<int>(0, (sum, entry) => sum + entry.value);
    final color = discipline.accentColor;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GatheringSectionHeader(
              title: 'COLETADOS',
              detail: '$total no total',
              color: color,
            ),
            const SizedBox(height: 12),
            if (collected.isEmpty)
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: color.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Nenhum recurso desta atividade foi coletado ainda.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              )
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final entry in collected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: entry.key.rarity.color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: entry.key.rarity.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MedievalEmblem(
                            assetPath: entry.key.discipline.emblemAsset,
                            size: 16,
                            semanticLabel: entry.key.discipline.displayName,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            entry.key.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontSize: 10,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '×${entry.value}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: entry.key.rarity.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
