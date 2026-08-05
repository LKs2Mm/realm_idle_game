part of '../gathering_screen.dart';

class _DisciplineOverviewCard extends StatelessWidget {
  final GameState gameState;
  final GatheringDiscipline discipline;
  final ValueChanged<GatheringDiscipline>? onOpenTools;

  const _DisciplineOverviewCard({
    required this.gameState,
    required this.discipline,
    this.onOpenTools,
  });

  @override
  Widget build(BuildContext context) {
    final skill = gameState.skills[discipline.skillId];
    final level = skill?.level ?? 1;
    final experience = skill?.experience ?? 0.0;
    final experienceToNextLevel = skill?.experienceToNextLevel ?? 100;
    final color = discipline.accentColor;

    final tool = gameState.equippedToolDefinition(discipline);
    final ownedTool = gameState.ownedTool(tool.id);
    final upgradeLevel = ownedTool?.upgradeLevel ?? 0;
    final toolName = tool.name;
    final toolDetails =
        '${_formatDecimal(tool.speedForUpgrade(upgradeLevel))}× velocidade  •  '
        '${_formatDecimal(tool.yieldForUpgrade(upgradeLevel))}× rendimento  •  '
        '+$upgradeLevel/${tool.maxUpgradeLevel}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                MedievalEmblem(
                  assetPath: discipline.emblemAsset,
                  size: 40,
                  semanticLabel: discipline.displayName,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discipline.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedXpText(
                        skillId: discipline.skillId,
                        level: level,
                        experience: experience,
                        experienceToNextLevel: experienceToNextLevel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Semantics(
                    label: 'Nível $level',
                    child: ExcludeSemantics(
                      child: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 360),
                        child: Text(
                          'NÍVEL $level',
                          key: ValueKey('${discipline.skillId}:$level'),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            AnimatedXpProgress(
              skillId: discipline.skillId,
              level: level,
              experience: experience,
              experienceToNextLevel: experienceToNextLevel,
              color: color,
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppTheme.darkCardBorder),
            const SizedBox(height: 13),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenTools == null
                    ? null
                    : () => onOpenTools!(discipline),
                borderRadius: BorderRadius.circular(3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.smithingOrange.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: AppTheme.smithingOrange.withValues(
                              alpha: 0.42,
                            ),
                          ),
                        ),
                        child: Icon(
                          discipline == GatheringDiscipline.fishing
                              ? Icons.phishing_rounded
                              : Icons.handyman_outlined,
                          size: 20,
                          color: AppTheme.smithingOrange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              toolName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              toolDetails,
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
                      Icon(
                        onOpenTools == null
                            ? Icons.build_outlined
                            : Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
