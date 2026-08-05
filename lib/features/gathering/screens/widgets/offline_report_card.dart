part of '../gathering_screen.dart';

class _OfflineReportCard extends StatelessWidget {
  final GatheringAdvanceResult report;
  final VoidCallback onDismiss;

  const _OfflineReportCard({required this.report, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final collected = report.collectedResources.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.combatBlue.withValues(alpha: 0.12),
      shape: BeveledRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        side: BorderSide(color: AppTheme.combatBlue.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 7, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.nights_stay_outlined,
                  color: AppTheme.combatBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PROGRESSO ENQUANTO VOCÊ ESTAVA FORA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.combatBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'Fechar resumo',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            if (!report.hasRewards)
              Text(
                'Nenhum ciclo foi concluído durante esse período.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              Text(
                '${report.completedCycles} ciclos  •  +${report.totalItems} itens  •  '
                '+${formatXp(report.totalExperience)} XP',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (collected.isNotEmpty) ...[
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in collected)
                      _OfflineResourceChip(
                        resourceId: entry.key,
                        quantity: entry.value,
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OfflineResourceChip extends StatelessWidget {
  final String resourceId;
  final int quantity;

  const _OfflineResourceChip({
    required this.resourceId,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final resource = GatheringResource.byId(resourceId);
    final color = resource?.rarity.color ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '${resource?.name ?? resourceId} ×$quantity',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
