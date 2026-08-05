part of '../gathering_screen.dart';

class _GatheringActivityCard extends StatelessWidget {
  final GameState gameState;
  final GatheringDiscipline fallbackDiscipline;
  final VoidCallback onStop;

  const _GatheringActivityCard({
    required this.gameState,
    required this.fallbackDiscipline,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final session = gameState.activeGatheringSession;
    final resource = session == null
        ? null
        : GatheringResource.byId(session.resourceId);

    if (session == null || resource == null) {
      return _EmptyGatheringActivityCard(discipline: fallbackDiscipline);
    }

    final color = resource.discipline.accentColor;
    final queuedResource = session.queuedResourceId == null
        ? null
        : GatheringResource.byId(session.queuedResourceId!);
    final nextResource = queuedResource ?? resource;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: BeveledRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: RunicFrame(
        color: color,
        opacity: 0.58,
        cornerLength: 13,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.15), AppTheme.darkCard],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ResourceGlyph(resource: resource, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource.discipline.activityLabel.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          resource.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_rounded, size: 17),
                    label: const Text('Parar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.combatRed,
                      side: BorderSide(
                        color: AppTheme.combatRed.withValues(alpha: 0.75),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GatheringCycleProgress(session: session, color: color),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppTheme.darkCardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      queuedResource == null
                          ? Icons.repeat_rounded
                          : Icons.skip_next_rounded,
                      size: 17,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      queuedResource == null ? 'Próximo ciclo:' : 'Próximo:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        nextResource.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _GatheringCycleProgress extends StatefulWidget {
  final GatheringSession session;
  final Color color;

  const _GatheringCycleProgress({required this.session, required this.color});

  @override
  State<_GatheringCycleProgress> createState() =>
      _GatheringCycleProgressState();
}

class _GatheringCycleProgressState extends State<_GatheringCycleProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late GatheringSession _trackedSession;
  var _disableAnimations = false;
  var _dependenciesReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = AlwaysStoppedAnimation(widget.session.progress);
    _trackedSession = widget.session;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (!_dependenciesReady || disableAnimations != _disableAnimations) {
      _dependenciesReady = true;
      _disableAnimations = disableAnimations;
      _syncAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant _GatheringCycleProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(_trackedSession, widget.session)) {
      _trackedSession = widget.session;
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    _controller.stop();
    if (_disableAnimations) {
      _animation = AlwaysStoppedAnimation(widget.session.progress);
      return;
    }

    final remainingMilliseconds = widget.session.timeRemainingMilliseconds
        .clamp(1, 86400000);
    _controller.duration = Duration(milliseconds: remainingMilliseconds);
    _animation = Tween<double>(
      begin: widget.session.progress,
      end: 1,
    ).animate(_controller);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authoritativeProgress = widget.session.progress;
    return Semantics(
      label: 'Progresso da coleta',
      value: '${(authoritativeProgress * 100).round()} por cento',
      child: ExcludeSemantics(
        child: _disableAnimations
            ? _buildIndicator(context, authoritativeProgress)
            : AnimatedBuilder(
                animation: _animation,
                builder: (context, child) =>
                    _buildIndicator(context, _animation.value),
              ),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context, double progress) {
    final normalizedProgress = progress.clamp(0.0, 1.0);
    final remainingMilliseconds =
        ((1 - normalizedProgress) * widget.session.cycleDurationMilliseconds)
            .ceil()
            .clamp(0, widget.session.cycleDurationMilliseconds);

    return RepaintBoundary(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalizedProgress,
              minHeight: 9,
              backgroundColor: AppTheme.darkCardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${(normalizedProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDurationMilliseconds(remainingMilliseconds)} restantes',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyGatheringActivityCard extends StatelessWidget {
  final GatheringDiscipline discipline;

  const _EmptyGatheringActivityCard({required this.discipline});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            MedievalEmblem(
              assetPath: discipline.emblemAsset,
              size: 44,
              muted: true,
              semanticLabel: discipline.displayName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhuma coleta ativa',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${discipline.emptyInstruction} Depois, ela continuará sozinha.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
