part of '../gathering_screen.dart';

extension _GatheringDisciplinePresentation on GatheringDiscipline {
  String get emblemAsset => switch (this) {
    GatheringDiscipline.mining => MedievalAssets.mining,
    GatheringDiscipline.woodcutting => MedievalAssets.woodcutting,
    GatheringDiscipline.fishing => MedievalAssets.fishing,
  };

  Color get accentColor => switch (this) {
    GatheringDiscipline.mining => AppTheme.bronze,
    GatheringDiscipline.woodcutting => AppTheme.miningGreenLight,
    GatheringDiscipline.fishing => AppTheme.combatBlue,
  };

  String get activityLabel => switch (this) {
    GatheringDiscipline.mining => 'Minerando',
    GatheringDiscipline.woodcutting => 'Cortando',
    GatheringDiscipline.fishing => 'Pescando',
  };

  String get emptyInstruction => switch (this) {
    GatheringDiscipline.mining => 'Selecione um minério para começar.',
    GatheringDiscipline.woodcutting => 'Selecione uma árvore para começar.',
    GatheringDiscipline.fishing => 'Selecione uma pesca para começar.',
  };

  String get itemFolder => switch (this) {
    GatheringDiscipline.mining => 'minerios',
    GatheringDiscipline.woodcutting => 'madeiras',
    GatheringDiscipline.fishing => 'peixes',
  };
}

extension _GatheringResourcePresentation on GatheringResource {
  String get itemAsset =>
      MedievalAssets.gatheringItemAsset(discipline.itemFolder, id);
}

extension _GatheringRarityPresentation on GatheringRarity {
  Color get color => switch (this) {
    GatheringRarity.common => AppTheme.textSecondary,
    GatheringRarity.uncommon => AppTheme.miningGreenLight,
    GatheringRarity.rare => AppTheme.accentYellow,
    GatheringRarity.epic => AppTheme.combatBlue,
    GatheringRarity.legendary => AppTheme.combatRed,
    GatheringRarity.magical => const Color(0xFF8D668F),
  };

  String get label => switch (this) {
    GatheringRarity.common => 'Comum',
    GatheringRarity.uncommon => 'Incomum',
    GatheringRarity.rare => 'Raro',
    GatheringRarity.epic => 'Épico',
    GatheringRarity.legendary => 'Lendário',
    GatheringRarity.magical => 'Mágico',
  };
}

class _GatheringSectionHeader extends StatelessWidget {
  final String title;
  final String? detail;
  final Color color;

  const _GatheringSectionHeader({
    required this.title,
    required this.color,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RunicGlyph(size: 10, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (detail != null) ...[
          const Spacer(),
          Flexible(
            child: Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }
}

class _GatheringStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _GatheringStatusPill({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceGlyph extends StatelessWidget {
  final GatheringResource resource;
  final bool locked;
  final double size;

  const _ResourceGlyph({
    required this.resource,
    this.locked = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked ? AppTheme.textSecondary : resource.rarity.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.voidBlack,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MedievalEmblem(
            assetPath: resource.itemAsset,
            size: size,
            muted: locked,
            semanticLabel: resource.name,
          ),
          if (locked) ...[
            ColoredBox(color: AppTheme.voidBlack.withValues(alpha: 0.5)),
            Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.textSecondary,
              size: size * 0.42,
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDurationMilliseconds(int milliseconds) {
  if (milliseconds < 60000) {
    final seconds = milliseconds / 1000;
    final decimals = milliseconds % 1000 == 0 ? 0 : 2;
    return '${seconds.toStringAsFixed(decimals).replaceAll('.', ',')}s';
  }
  final minutes = milliseconds ~/ 60000;
  final remainderSeconds = (milliseconds % 60000) ~/ 1000;
  return remainderSeconds == 0
      ? '${minutes}min'
      : '${minutes}min ${remainderSeconds}s';
}

String _formatYield(double value) {
  final decimals = value == value.roundToDouble() ? 0 : 2;
  return value.toStringAsFixed(decimals).replaceAll('.', ',');
}

String _formatDecimal(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');
