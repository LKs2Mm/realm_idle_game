import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/core/utils/number_formatters.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_session.dart';
import 'package:realm_idle_game/features/gathering/services/gathering_service.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/widgets/animated_xp_progress.dart';

part 'widgets/activity_card.dart';
part 'widgets/discipline_overview_card.dart';
part 'widgets/discipline_selector.dart';
part 'widgets/gathering_shared.dart';
part 'widgets/inventory_summary_card.dart';
part 'widgets/offline_report_card.dart';
part 'widgets/resource_list.dart';

class GatheringScreen extends StatefulWidget {
  final GameState gameState;
  final GatheringService service;
  final GatheringAdvanceResult? offlineReport;
  final VoidCallback onDismissOfflineReport;
  final GatheringDiscipline? initialDiscipline;
  final ValueChanged<GatheringDiscipline>? onOpenTools;

  const GatheringScreen({
    super.key,
    required this.gameState,
    required this.service,
    required this.offlineReport,
    required this.onDismissOfflineReport,
    this.initialDiscipline,
    this.onOpenTools,
  });

  @override
  State<GatheringScreen> createState() => _GatheringScreenState();
}

class _GatheringScreenState extends State<GatheringScreen> {
  late GatheringDiscipline _selectedDiscipline;

  @override
  void initState() {
    super.initState();
    final session = widget.gameState.activeGatheringSession;
    final activeResource = session == null
        ? null
        : GatheringResource.byId(session.resourceId);
    _selectedDiscipline =
        widget.initialDiscipline ??
        activeResource?.discipline ??
        GatheringDiscipline.mining;
  }

  void _selectDiscipline(GatheringDiscipline discipline) {
    if (_selectedDiscipline == discipline) return;
    setState(() => _selectedDiscipline = discipline);
  }

  void _selectResource(GatheringResource resource) {
    widget.service.selectResource(resource.id);
    if (mounted) setState(() {});
  }

  void _stopGathering() {
    widget.service.stop();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final resources = GatheringResource.forDiscipline(_selectedDiscipline);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MedievalEmblem(
                assetPath: _selectedDiscipline.emblemAsset,
                size: 42,
                semanticLabel: _selectedDiscipline.displayName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Colheita',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 24,
                            color: AppTheme.accentYellow,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Escolha uma atividade; a coleta continuará sozinha.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const RunicDivider(height: 26, maxWidth: 230, opacity: 0.68),
          if (widget.offlineReport != null) ...[
            const SizedBox(height: 14),
            _OfflineReportCard(
              report: widget.offlineReport!,
              onDismiss: widget.onDismissOfflineReport,
            ),
          ],
          const SizedBox(height: 14),
          _GatheringActivityCard(
            gameState: widget.gameState,
            fallbackDiscipline: _selectedDiscipline,
            onStop: _stopGathering,
          ),
          const SizedBox(height: 18),
          _DisciplineSelector(
            selected: _selectedDiscipline,
            onSelected: _selectDiscipline,
          ),
          const SizedBox(height: 14),
          _DisciplineOverviewCard(
            gameState: widget.gameState,
            discipline: _selectedDiscipline,
            onOpenTools: widget.onOpenTools,
          ),
          const SizedBox(height: 22),
          _GatheringSectionHeader(
            title: 'RECURSOS',
            detail: '${resources.length} recursos no total',
            color: _selectedDiscipline.accentColor,
          ),
          const SizedBox(height: 8),
          _GatheringResourceList(
            gameState: widget.gameState,
            resources: resources,
            onSelect: _selectResource,
          ),
          const SizedBox(height: 22),
          _GatheringInventorySummaryCard(
            gameState: widget.gameState,
            discipline: _selectedDiscipline,
          ),
        ],
      ),
    );
  }
}
