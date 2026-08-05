import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/core/utils/number_formatters.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/models/game_state.dart';

class HeaderWidget extends StatelessWidget {
  final GameState gameState;

  const HeaderWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final maximumHealth = gameState.maxHealth <= 0 ? 1 : gameState.maxHealth;
    final currentHealth = gameState.currentHealth.clamp(0, maximumHealth);
    final healthRatio = (currentHealth / maximumHealth).clamp(0.0, 1.0);
    final healthColor = gameState.isDefeated || healthRatio <= 0.2
        ? AppTheme.combatRed
        : healthRatio <= 0.5
        ? AppTheme.smithingOrange
        : AppTheme.miningGreenLight;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.darkCardRaised, AppTheme.voidBlack],
        ),
        border: Border(bottom: BorderSide(color: AppTheme.bronze, width: 2)),
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 8, 13, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const RunicFrame(
                    opacity: 0.72,
                    cornerLength: 9,
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: MedievalEmblem(
                        assetPath: MedievalAssets.crest,
                        size: 48,
                        semanticLabel: 'Brasão de Realm Idle',
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REALM IDLE',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 22,
                                color: AppTheme.accentYellow,
                                letterSpacing: 2.4,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(1, 2),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${gameState.profile.name.toUpperCase()}  •  ${gameState.activeHeroClass.displayName.toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.brightness_2_outlined,
                    color: AppTheme.bronze,
                    size: 19,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.shield_outlined,
                      label:
                          '${gameState.activeHeroClass.displayName} ${gameState.classLevel(gameState.activeHeroClass)}',
                      color: AppTheme.combatRed,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.monetization_on,
                      label: formatInteger(gameState.gold),
                      color: AppTheme.accentYellow,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.military_tech,
                      label: 'NÍVEL ${gameState.totalLevel}',
                      color: AppTheme.miningGreenLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _HeaderHealthBar(
                currentHealth: currentHealth,
                maximumHealth: maximumHealth,
                color: healthColor,
                defeated: gameState.isDefeated,
              ),
              const SizedBox(height: 5),
              const RunicDivider(height: 20, maxWidth: 178, opacity: 0.76),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderHealthBar extends StatelessWidget {
  final int currentHealth;
  final int maximumHealth;
  final Color color;
  final bool defeated;

  const _HeaderHealthBar({
    required this.currentHealth,
    required this.maximumHealth,
    required this.color,
    required this.defeated,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentHealth / maximumHealth).clamp(0.0, 1.0);
    return Semantics(
      label: defeated ? 'Herói derrotado' : 'Vida do herói',
      value: '$currentHealth de $maximumHealth pontos de vida',
      child: Container(
        key: const ValueKey<String>('global-health-stat'),
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: AppTheme.voidBlack.withValues(alpha: 0.72),
          border: Border.all(color: color.withValues(alpha: 0.48)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Icon(
              defeated ? Icons.heart_broken : Icons.favorite,
              color: color,
              size: 13,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppTheme.darkCardBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '$currentHealth/$maximumHealth HP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: AppTheme.voidBlack.withValues(alpha: 0.72),
        border: Border.all(color: color.withValues(alpha: 0.48)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
