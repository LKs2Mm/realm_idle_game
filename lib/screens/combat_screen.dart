import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/core/utils/number_formatters.dart';
import 'package:realm_idle_game/features/content/data/combat_drop_catalog.dart';
import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/features/combat/models/combat_session.dart';
import 'package:realm_idle_game/features/combat/services/combat_service.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/processing/data/cooking_recipe_catalog.dart';
import 'package:realm_idle_game/models/auto_eat_settings.dart';
import 'package:realm_idle_game/models/game_state.dart';

class CombatScreen extends StatefulWidget {
  final GameState gameState;
  final CombatService service;
  final CombatAdvanceResult? offlineReport;
  final VoidCallback onDismissOfflineReport;
  final VoidCallback onStateChanged;
  final ValueChanged<HeroClass> onManageEquipment;

  const CombatScreen({
    super.key,
    required this.gameState,
    required this.service,
    required this.offlineReport,
    required this.onDismissOfflineReport,
    required this.onStateChanged,
    required this.onManageEquipment,
  });

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  void _selectEncounter(CombatEncounter encounter) {
    widget.service.selectEncounter(encounter.id);
    if (mounted) setState(() {});
  }

  void _stopCombat() {
    widget.service.stop();
    if (mounted) setState(() {});
  }

  void _selectHeroClass(HeroClass heroClass) {
    if (widget.gameState.activeHeroClass == heroClass) return;
    widget.gameState.selectHeroClass(heroClass);
    widget.onStateChanged();
    if (mounted) setState(() {});
  }

  void _setAutoEatEnabled(bool enabled) {
    widget.gameState.setAutoEatEnabled(enabled);
    widget.onStateChanged();
    if (mounted) setState(() {});
  }

  void _setAutoEatThreshold(int percent) {
    widget.gameState.setAutoEatThreshold(percent);
    widget.onStateChanged();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('combat-screen-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CombatHeader(gameState: widget.gameState),
          const SizedBox(height: 8),
          const RunicDivider(height: 26, maxWidth: 230, opacity: 0.72),
          const SizedBox(height: 14),
          _HeroClassSelector(
            gameState: widget.gameState,
            onSelect: _selectHeroClass,
            onManageEquipment: widget.onManageEquipment,
          ),
          if (widget.offlineReport != null) ...[
            const SizedBox(height: 14),
            _CombatOfflineReportCard(
              report: widget.offlineReport!,
              onDismiss: widget.onDismissOfflineReport,
            ),
          ],
          const SizedBox(height: 14),
          _CombatActivityCard(gameState: widget.gameState, onStop: _stopCombat),
          const SizedBox(height: 14),
          _AutoEatCard(
            gameState: widget.gameState,
            onEnabledChanged: _setAutoEatEnabled,
            onThresholdChanged: _setAutoEatThreshold,
          ),
          const SizedBox(height: 20),
          const _CombatNotice(),
          const SizedBox(height: 20),
          const _CombatSectionHeader(
            title: 'CAÇADAS',
            detail: 'Escolha um inimigo',
          ),
          const SizedBox(height: 8),
          _EncounterList(
            gameState: widget.gameState,
            onSelect: _selectEncounter,
          ),
        ],
      ),
    );
  }
}

class _CombatHeader extends StatelessWidget {
  final GameState gameState;

  const _CombatHeader({required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const MedievalEmblem(
              assetPath: MedievalAssets.crest,
              size: 45,
              semanticLabel: 'Brasão de combate',
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Combate',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.accentYellow,
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Escolha uma caçada; a batalha continuará sozinha.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HeaderMetric(
                icon: Icons.shield_outlined,
                label: 'Nível de combate',
                value: '${gameState.combatLevel}',
                color: AppTheme.combatRed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HeaderMetric(
                icon: Icons.monetization_on_outlined,
                label: 'Saldo',
                value: '${formatInteger(gameState.gold)} ouro',
                color: AppTheme.accentYellow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _CombatHealthBar(
          currentHealth: gameState.currentHealth,
          maxHealth: gameState.maxHealth,
          defeated: gameState.isDefeated,
        ),
      ],
    );
  }
}

class _HeroClassSelector extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<HeroClass> onSelect;
  final ValueChanged<HeroClass> onManageEquipment;

  const _HeroClassSelector({
    required this.gameState,
    required this.onSelect,
    required this.onManageEquipment,
  });

  @override
  Widget build(BuildContext context) {
    final activeClass = gameState.activeHeroClass;
    final activeColor = activeClass.combatColor;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: activeColor.withValues(alpha: 0.72)),
      ),
      child: RunicFrame(
        color: activeColor,
        opacity: 0.58,
        cornerLength: 14,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activeColor.withValues(alpha: 0.1),
                AppTheme.darkCard,
                AppTheme.voidBlack.withValues(alpha: 0.72),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RunicGlyph(size: 12, color: activeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAMINHOS DE GUERRA',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: activeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Troque livremente: nenhuma classe é permanente.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _RegionPill(
                      regionName: gameState.selectedRegionName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  // Leave a physical-pixel safety gutter for fractional DPRs.
                  final tileWidth = (constraints.maxWidth - spacing - 0.5) / 2;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final heroClass in HeroClass.values)
                        SizedBox(
                          width: tileWidth,
                          child: _HeroClassTile(
                            heroClass: heroClass,
                            isActive: heroClass == activeClass,
                            masteryLevel: gameState.classLevel(heroClass),
                            equipmentPower: gameState.equipmentPowerFor(
                              heroClass,
                            ),
                            onTap: () => heroClass == activeClass
                                ? onManageEquipment(heroClass)
                                : onSelect(heroClass),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 15,
                      color: activeColor,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Cada vitória automática concede maestria ao caminho '
                        '${activeClass.displayName}. Você pode mudar antes da '
                        'próxima batalha sem perder progresso. Toque na classe '
                        'ativa para equipar arma, armadura e '
                        '${activeClass == HeroClass.mage ? 'magias ' : ''}'
                        'peça por peça.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          height: 1.32,
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

class _RegionPill extends StatelessWidget {
  final String regionName;

  const _RegionPill({required this.regionName});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: AppTheme.darkCardBorder.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 12,
            color: AppTheme.accentYellow,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              regionName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.accentYellow,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroClassTile extends StatelessWidget {
  final HeroClass heroClass;
  final bool isActive;
  final int masteryLevel;
  final int equipmentPower;
  final VoidCallback onTap;

  const _HeroClassTile({
    required this.heroClass,
    required this.isActive,
    required this.masteryLevel,
    required this.equipmentPower,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = heroClass.combatColor;

    return Semantics(
      button: true,
      selected: isActive,
      label:
          '${heroClass.displayName}, maestria nível $masteryLevel, '
          'poder de equipamento $equipmentPower'
          '${isActive ? ', toque para gerenciar equipamento' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('combat-class-${heroClass.saveKey}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 170),
            constraints: const BoxConstraints(minHeight: 108),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.13)
                  : AppTheme.voidBlack.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isActive
                    ? color.withValues(alpha: 0.92)
                    : AppTheme.darkCardBorder.withValues(alpha: 0.62),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.16),
                        blurRadius: 9,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: color.withValues(alpha: 0.42),
                        ),
                      ),
                      child: MedievalEmblem(
                        assetPath: MedievalAssets.classAsset(
                          heroClass.saveKey,
                        ),
                        size: 30,
                        muted: !isActive,
                        semanticLabel: heroClass.displayName,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        heroClass.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive ? color : AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (isActive)
                      Icon(Icons.check_circle_rounded, size: 14, color: color),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  heroClass.signatureWeapon,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ClassMetric(
                        label: 'MAESTRIA',
                        value: 'Nv. $masteryLevel',
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _ClassMetric(
                        label: 'SET',
                        value: '$equipmentPower',
                        color: AppTheme.accentYellow,
                      ),
                    ),
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

class _ClassMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ClassMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.48)),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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

class _CombatHealthBar extends StatelessWidget {
  final int currentHealth;
  final int maxHealth;
  final bool defeated;

  const _CombatHealthBar({
    required this.currentHealth,
    required this.maxHealth,
    required this.defeated,
  });

  @override
  Widget build(BuildContext context) {
    final safeMaximum = maxHealth <= 0 ? 1 : maxHealth;
    final safeCurrent = currentHealth.clamp(0, safeMaximum);
    final ratio = (safeCurrent / safeMaximum).clamp(0.0, 1.0);
    final color = defeated || ratio <= 0.2
        ? AppTheme.combatRed
        : ratio <= 0.5
        ? AppTheme.smithingOrange
        : AppTheme.miningGreenLight;

    return Semantics(
      label: defeated ? 'Herói derrotado' : 'Vida do herói',
      value: '$safeCurrent de $safeMaximum pontos de vida',
      child: Container(
        key: const ValueKey<String>('combat-health-bar'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.voidBlack.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  defeated ? Icons.heart_broken : Icons.favorite,
                  size: 15,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  defeated ? 'DERROTADO' : 'VIDA',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
                const Spacer(),
                Text(
                  '$safeCurrent / $safeMaximum HP',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 7,
                backgroundColor: AppTheme.darkCardBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CombatNotice extends StatelessWidget {
  const _CombatNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.combatRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.combatRed.withValues(alpha: 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: RunicGlyph(
              size: 12,
              color: AppTheme.combatRed,
              opacity: 0.95,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Sem ataques por clique. Ouro e XP são entregues somente quando '
              'uma batalha automática termina; ao perder toda a vida, a '
              'caçada é encerrada.',
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

class _CombatActivityCard extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onStop;

  const _CombatActivityCard({required this.gameState, required this.onStop});

  @override
  Widget build(BuildContext context) {
    if (gameState.isDefeated) {
      return _DefeatedCombatActivityCard(
        currentHealth: gameState.currentHealth,
        maxHealth: gameState.maxHealth,
      );
    }

    final session = gameState.activeCombatSession;
    final encounter = session == null
        ? null
        : CombatEncounter.byId(session.encounterId);
    if (session == null || encounter == null) {
      return const _EmptyCombatActivityCard();
    }

    final queued = session.queuedEncounterId == null
        ? null
        : CombatEncounter.byId(session.queuedEncounterId!);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: AppTheme.combatRed, width: 1.5),
      ),
      child: RunicFrame(
        color: AppTheme.combatRed,
        opacity: 0.64,
        cornerLength: 14,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.combatRed.withValues(alpha: 0.13),
                AppTheme.darkCard,
                AppTheme.voidBlack.withValues(alpha: 0.78),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _EncounterSigil(encounter: encounter, size: 48),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAÇADA ATIVA',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.combatRed,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          encounter.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const _CombatStatusPill(
                    label: 'ATIVO',
                    color: AppTheme.combatRed,
                    icon: Icons.gavel_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CombatCycleProgress(session: session),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 7,
                children: [
                  _RewardChip(
                    icon: Icons.monetization_on_outlined,
                    label: '+${formatInteger(encounter.goldPerVictory)} ouro',
                    color: AppTheme.accentYellow,
                  ),
                  _RewardChip(
                    icon: Icons.auto_awesome_outlined,
                    label: '+${formatXp(encounter.experiencePerVictory)} XP',
                    color: AppTheme.combatBlue,
                  ),
                  _RewardChip(
                    icon: Icons.heart_broken_outlined,
                    label: '-${encounter.damagePerVictory} HP',
                    color: AppTheme.combatRed,
                  ),
                  _RewardChip(
                    icon: Icons.schedule_outlined,
                    label: _formatDurationMilliseconds(
                      encounter.cycleDurationMilliseconds,
                    ),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              if (queued != null) ...[
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: AppTheme.accentYellow.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.skip_next_rounded,
                        size: 16,
                        color: AppTheme.accentYellow,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Próxima caçada: ${queued.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey<String>('combat-stop'),
                onPressed: onStop,
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Encerrar caçada'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.combatRed,
                  side: BorderSide(
                    color: AppTheme.combatRed.withValues(alpha: 0.62),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AutoEatCard extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onThresholdChanged;

  const _AutoEatCard({
    required this.gameState,
    required this.onEnabledChanged,
    required this.onThresholdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final settings = gameState.autoEatSettings;
    final bestFoodId = gameState.bestOwnedFoodId;
    final bestFoodName = bestFoodId == null
        ? null
        : CookingRecipeCatalog.byFoodId(bestFoodId)?.name;

    return Card(
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: AppTheme.miningGreenLight,
        opacity: 0.42,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                key: const ValueKey<String>('combat-auto-eat-enabled'),
                contentPadding: EdgeInsets.zero,
                value: settings.enabled,
                onChanged: onEnabledChanged,
                title: const Text('Comer automaticamente'),
                subtitle: Text(
                  bestFoodName == null
                      ? 'Sem refeições no inventário ainda.'
                      : 'Vai usar: $bestFoodName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: const Icon(
                  Icons.restaurant_outlined,
                  color: AppTheme.miningGreenLight,
                ),
              ),
              if (settings.enabled)
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        label: 'Limiar de vida pra comer automaticamente',
                        value: '${settings.thresholdPercent}%',
                        child: Slider(
                          key: const ValueKey<String>(
                            'combat-auto-eat-threshold',
                          ),
                          value: settings.thresholdPercent.toDouble(),
                          min: AutoEatSettings.minThresholdPercent.toDouble(),
                          max: AutoEatSettings.maxThresholdPercent.toDouble(),
                          divisions:
                              (AutoEatSettings.maxThresholdPercent -
                                  AutoEatSettings.minThresholdPercent) ~/
                              5,
                          onChanged: (value) =>
                              onThresholdChanged(value.round()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${settings.thresholdPercent}%',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefeatedCombatActivityCard extends StatelessWidget {
  final int currentHealth;
  final int maxHealth;

  const _DefeatedCombatActivityCard({
    required this.currentHealth,
    required this.maxHealth,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey<String>('combat-defeated-state'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: AppTheme.combatRed, width: 1.5),
      ),
      child: RunicFrame(
        color: AppTheme.combatRed,
        opacity: 0.78,
        cornerLength: 15,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.combatRed.withValues(alpha: 0.18),
                AppTheme.darkCard,
                AppTheme.voidBlack,
              ],
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.voidBlack.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.combatRed.withValues(alpha: 0.7),
                  ),
                ),
                child: const Icon(
                  Icons.heart_broken,
                  color: AppTheme.combatRed,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DERROTADO',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.combatRed,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$currentHealth / $maxHealth HP',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'As runas silenciaram e a caçada foi encerrada. '
                      'Recupere sua vida antes de enfrentar outro inimigo.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.35),
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

class _EmptyCombatActivityCard extends StatelessWidget {
  const _EmptyCombatActivityCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: RunicFrame(
        color: AppTheme.darkCardBorder,
        opacity: 0.5,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.voidBlack.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.darkCardBorder),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.textSecondary,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nenhuma caçada ativa',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Escolha um inimigo abaixo para iniciar o combate automático.',
                      style: Theme.of(context).textTheme.bodySmall,
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

class _CombatCycleProgress extends StatefulWidget {
  final CombatSession session;

  const _CombatCycleProgress({required this.session});

  @override
  State<_CombatCycleProgress> createState() => _CombatCycleProgressState();
}

class _CombatCycleProgressState extends State<_CombatCycleProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late CombatSession _trackedSession;
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
  void didUpdateWidget(covariant _CombatCycleProgress oldWidget) {
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
      label: 'Progresso da batalha',
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
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.combatRed,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                '${(normalizedProgress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.combatRed,
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
              Flexible(
                child: Text(
                  '${_formatDurationMilliseconds(remainingMilliseconds)} restantes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EncounterList extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<CombatEncounter> onSelect;

  const _EncounterList({required this.gameState, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final session = gameState.activeCombatSession;
    return Column(
      children: [
        for (var index = 0; index < CombatEncounter.all.length; index++) ...[
          _EncounterTile(
            gameState: gameState,
            encounter: CombatEncounter.all[index],
            isActive: session?.encounterId == CombatEncounter.all[index].id,
            isQueued:
                session?.queuedEncounterId == CombatEncounter.all[index].id,
            hasActiveSession: session != null,
            onSelect: () => onSelect(CombatEncounter.all[index]),
          ),
          if (index < CombatEncounter.all.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EncounterTile extends StatelessWidget {
  final GameState gameState;
  final CombatEncounter encounter;
  final bool isActive;
  final bool isQueued;
  final bool hasActiveSession;
  final VoidCallback onSelect;

  const _EncounterTile({
    required this.gameState,
    required this.encounter,
    required this.isActive,
    required this.isQueued,
    required this.hasActiveSession,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !gameState.canFight(encounter);
    final defeated = gameState.isDefeated;
    final canSelect = !defeated && !isLocked && !isActive && !isQueued;
    final highlighted = isActive || isQueued;
    final highlightColor = isQueued
        ? AppTheme.accentYellow
        : AppTheme.combatRed;

    return Semantics(
      button: canSelect,
      enabled: canSelect,
      selected: highlighted,
      label: defeated
          ? '${encounter.name}, indisponível enquanto o herói está derrotado'
          : isLocked
          ? '${encounter.name}, bloqueado até o nível ${encounter.requiredAttackLevel}'
          : encounter.name,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: highlighted ? 4 : 1,
        clipBehavior: Clip.antiAlias,
        shape: BeveledRectangleBorder(
          borderRadius: AppTheme.panelRadius,
          side: BorderSide(
            color: highlighted
                ? highlightColor
                : AppTheme.darkCardBorder.withValues(
                    alpha: isLocked ? 0.48 : 1,
                  ),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey<String>('combat-encounter-${encounter.id}'),
          onTap: canSelect ? onSelect : null,
          child: AnimatedOpacity(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            opacity: isLocked || defeated ? 0.62 : 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _EncounterSigil(
                    encounter: encounter,
                    size: 45,
                    muted: isLocked,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          encounter.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          encounter.description,
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
                            _EncounterMeta(
                              icon: Icons.shield_outlined,
                              label: 'Nv. ${encounter.requiredAttackLevel}',
                            ),
                            _EncounterMeta(
                              icon: Icons.schedule_outlined,
                              label: _formatDurationMilliseconds(
                                encounter.cycleDurationMilliseconds,
                              ),
                            ),
                            _EncounterMeta(
                              icon: Icons.monetization_on_outlined,
                              label:
                                  '+${formatInteger(encounter.goldPerVictory)} ouro',
                              color: AppTheme.accentYellow,
                            ),
                            _EncounterMeta(
                              icon: Icons.auto_awesome_outlined,
                              label:
                                  '+${formatXp(encounter.experiencePerVictory)} XP',
                              color: AppTheme.combatBlue,
                            ),
                            _EncounterMeta(
                              icon: Icons.heart_broken_outlined,
                              label: '-${encounter.damagePerVictory} HP',
                              color: AppTheme.combatRed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EncounterSelectionStatus(
                    encounter: encounter,
                    isLocked: isLocked,
                    isActive: isActive,
                    isQueued: isQueued,
                    hasActiveSession: hasActiveSession,
                    defeated: defeated,
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

class _EncounterSigil extends StatelessWidget {
  final CombatEncounter encounter;
  final double size;
  final bool muted;

  const _EncounterSigil({
    required this.encounter,
    required this.size,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (muted ? AppTheme.textSecondary : AppTheme.combatRed)
              .withValues(alpha: 0.48),
        ),
      ),
      child: MedievalEmblem(
        assetPath: MedievalAssets.enemyAsset(encounter.id),
        size: size,
        muted: muted,
        semanticLabel: encounter.name,
      ),
    );
  }
}

class _EncounterSelectionStatus extends StatelessWidget {
  final CombatEncounter encounter;
  final bool isLocked;
  final bool isActive;
  final bool isQueued;
  final bool hasActiveSession;
  final bool defeated;

  const _EncounterSelectionStatus({
    required this.encounter,
    required this.isLocked,
    required this.isActive,
    required this.isQueued,
    required this.hasActiveSession,
    required this.defeated,
  });

  @override
  Widget build(BuildContext context) {
    if (defeated) {
      return const _CombatStatusPill(
        label: 'SEM VIDA',
        color: AppTheme.combatRed,
        icon: Icons.heart_broken_outlined,
      );
    }
    if (isLocked) {
      return _CombatStatusPill(
        label: 'Nv. ${encounter.requiredAttackLevel}',
        color: AppTheme.textSecondary,
        icon: Icons.lock_outline_rounded,
      );
    }
    if (isActive) {
      return const _CombatStatusPill(
        label: 'ATIVO',
        color: AppTheme.combatRed,
        icon: Icons.gavel_rounded,
      );
    }
    if (isQueued) {
      return const _CombatStatusPill(
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
          color: AppTheme.combatRed,
          size: 23,
        ),
        const SizedBox(height: 3),
        Text(
          hasActiveSession ? 'Próximo' : 'Iniciar',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.combatRed,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CombatStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CombatStatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EncounterMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _EncounterMeta({
    required this.icon,
    required this.label,
    this.color = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, fontSize: 9),
          ),
        ),
      ],
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.23)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
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

class _CombatSectionHeader extends StatelessWidget {
  final String title;
  final String detail;

  const _CombatSectionHeader({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const RunicGlyph(size: 10, color: AppTheme.combatRed),
        const SizedBox(width: 7),
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.combatRed,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppTheme.darkCardBorder.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
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

class _CombatOfflineReportCard extends StatelessWidget {
  final CombatAdvanceResult report;
  final VoidCallback onDismiss;

  const _CombatOfflineReportCard({
    required this.report,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final victories = report.victoriesByEncounter.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final loot =
        report.lootEarned.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) {
            final firstName = CombatDropCatalog.byId(a.key)?.name ?? a.key;
            final secondName = CombatDropCatalog.byId(b.key)?.name ?? b.key;
            return firstName.compareTo(secondName);
          });

    return Card(
      margin: EdgeInsets.zero,
      color: AppTheme.combatBlue.withValues(alpha: 0.1),
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: AppTheme.combatBlue.withValues(alpha: 0.64)),
      ),
      child: RunicFrame(
        color: AppTheme.combatBlue,
        opacity: 0.48,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 10, 7, 12),
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
                      'RELATÓRIO DA CAÇADA',
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
                    tooltip: 'Fechar relatório',
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
                  'Nenhuma batalha foi concluída durante esse período.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else ...[
                Text(
                  '${report.completedVictories} vitórias  •  '
                  '+${formatInteger(report.goldEarned)} ouro  •  '
                  '+${formatXp(report.experienceEarned)} XP',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (report.damageTaken > 0 || report.wasDefeated) ...[
                  const SizedBox(height: 8),
                  Container(
                    key: const ValueKey<String>('combat-report-damage'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.combatRed.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppTheme.combatRed.withValues(alpha: 0.34),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          report.wasDefeated
                              ? Icons.heart_broken
                              : Icons.favorite_border,
                          size: 15,
                          color: AppTheme.combatRed,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Dano sofrido: -${report.damageTaken} HP'
                            '${report.wasDefeated ? ' • você foi derrotado' : ''}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.combatRed,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (victories.isNotEmpty) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final entry in victories)
                        _OfflineVictoryChip(
                          encounterId: entry.key,
                          victories: entry.value,
                        ),
                    ],
                  ),
                ],
                if (loot.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      const RunicGlyph(size: 9, color: AppTheme.accentYellow),
                      const SizedBox(width: 6),
                      Text(
                        'ESPÓLIOS ENCONTRADOS',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentYellow,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final entry in loot)
                        _OfflineLootChip(
                          dropId: entry.key,
                          quantity: entry.value,
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineLootChip extends StatelessWidget {
  final String dropId;
  final int quantity;

  const _OfflineLootChip({required this.dropId, required this.quantity});

  @override
  Widget build(BuildContext context) {
    final drop = CombatDropCatalog.byId(dropId);
    final name = drop?.name ?? _humanizeIdentifier(dropId);
    final sigil = drop?.sigil ?? 'ᛁ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accentYellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.accentYellow.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sigil,
            style: const TextStyle(
              color: AppTheme.accentYellow,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$name ×$quantity',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineVictoryChip extends StatelessWidget {
  final String encounterId;
  final int victories;

  const _OfflineVictoryChip({
    required this.encounterId,
    required this.victories,
  });

  @override
  Widget build(BuildContext context) {
    final encounter = CombatEncounter.byId(encounterId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.combatRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        '${encounter?.name ?? encounterId} ×$victories',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.combatRed,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

extension _HeroClassCombatPresentation on HeroClass {
  Color get combatColor => switch (this) {
    HeroClass.knight => AppTheme.combatBlue,
    HeroClass.assassin => const Color(0xFF9A719F),
    HeroClass.mage => const Color(0xFF58AAA8),
    HeroClass.archer => AppTheme.miningGreenLight,
  };

  String get signatureWeapon => switch (this) {
    HeroClass.knight => 'Espada e escudo',
    HeroClass.assassin => 'Adagas gêmeas',
    HeroClass.mage => 'Bastão rúnico',
    HeroClass.archer => 'Arco longo e aljava',
  };
}

String _humanizeIdentifier(String value) {
  final words = value
      .split('_')
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return value;
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}

String _formatDurationMilliseconds(int milliseconds) {
  if (milliseconds <= 0) return '0s';
  if (milliseconds < 1000) return '${milliseconds}ms';
  if (milliseconds % 1000 == 0) return '${milliseconds ~/ 1000}s';
  final seconds = milliseconds / 1000;
  return '${seconds.toStringAsFixed(1).replaceAll('.', ',')}s';
}
