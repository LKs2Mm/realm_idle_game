part of '../gathering_screen.dart';

class _DisciplineSelector extends StatelessWidget {
  final GatheringDiscipline selected;
  final ValueChanged<GatheringDiscipline> onSelected;

  const _DisciplineSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tipo de colheita',
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
                child: _DisciplineSegment(
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

class _DisciplineSegment extends StatelessWidget {
  final GatheringDiscipline discipline;
  final bool selected;
  final VoidCallback onTap;

  const _DisciplineSegment({
    required this.discipline,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = discipline.accentColor;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: selected
                  ? Border.all(color: color.withValues(alpha: 0.7))
                  : null,
            ),
            child: RunicFrame(
              color: color,
              opacity: selected ? 0.82 : 0,
              cornerLength: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MedievalEmblem(
                    assetPath: discipline.emblemAsset,
                    size: 30,
                    muted: !selected,
                    semanticLabel: discipline.displayName,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    discipline.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.05,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : AppTheme.textSecondary,
                    ),
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
