import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';
import 'package:realm_idle_game/widgets/animated_xp_progress.dart';
import 'package:realm_idle_game/widgets/skill_card.dart';

class SkillsScreen extends StatelessWidget {
  final GameState gameState;
  final ValueChanged<String>? onOpenSkill;

  const SkillsScreen({super.key, required this.gameState, this.onOpenSkill});

  static const _classPaths = <_ClassPath>[
    _ClassPath(
      heroClass: HeroClass.knight,
      skillId: 'knight_mastery',
      epithet: 'Juramento de Ferro',
      icon: Icons.shield_outlined,
      color: Color(0xFF98A8AD),
    ),
    _ClassPath(
      heroClass: HeroClass.assassin,
      skillId: 'assassin_mastery',
      epithet: 'Pacto do Véu',
      icon: Icons.visibility_off_outlined,
      color: Color(0xFF9B5966),
    ),
    _ClassPath(
      heroClass: HeroClass.mage,
      skillId: 'mage_mastery',
      epithet: 'Círculo Arcano',
      icon: Icons.auto_fix_high,
      color: Color(0xFF78A9B4),
    ),
    _ClassPath(
      heroClass: HeroClass.archer,
      skillId: 'archer_mastery',
      epithet: 'Olho da Mata',
      icon: Icons.adjust,
      color: Color(0xFF82956B),
    ),
  ];

  Map<SkillCategory, List<Skill>> get _skillsByCategory {
    final grouped = <SkillCategory, List<Skill>>{
      for (final category in SkillCategory.values) category: [],
    };
    for (final skill in gameState.skills.values) {
      grouped[skill.category]!.add(skill);
    }
    return grouped;
  }

  Color _categoryColor(SkillCategory category) => switch (category) {
    SkillCategory.gathering => AppTheme.miningGreen,
    SkillCategory.processing => AppTheme.smithingOrange,
    SkillCategory.combat => AppTheme.combatRed,
    SkillCategory.divinity => AppTheme.combatBlue,
  };

  String _categoryTitle(SkillCategory category) => switch (category) {
    SkillCategory.gathering => 'COLHEITA',
    SkillCategory.processing => 'PRODUÇÃO',
    SkillCategory.combat => 'COMBATE',
    SkillCategory.divinity => 'DIVINDADE',
  };

  @override
  Widget build(BuildContext context) {
    final populatedCategories = _skillsByCategory.entries.where(
      (entry) => entry.value.isNotEmpty,
    );
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler.scale(1);
    final compactGrid = mediaQuery.size.width < 400 || textScale > 1.15;
    final columnCount = compactGrid ? 2 : 3;
    final tileHeight = textScale > 1.15 ? 178.0 : 154.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HABILIDADES', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Toda perícia cresce pelo tempo dedicado à sua atividade — nunca '
            'por toques ou atalhos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _ClassArmoryBanner(activeClass: gameState.activeHeroClass),
          const SizedBox(height: 12),
          Text(
            'CAMINHOS DE COMBATE',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.combatRed,
              letterSpacing: 1,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in _classPaths)
                    SizedBox(
                      width: itemWidth,
                      child: _ClassMasterySeal(
                        path: path,
                        skill: gameState.skills[path.skillId],
                        active: gameState.activeHeroClass == path.heroClass,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          for (final entry in populatedCategories) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _categoryTitle(entry.key),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _categoryColor(entry.key),
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: tileHeight,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) => SkillCard(
                skill: entry.value[index],
                categoryColor: _categoryColor(entry.key),
                onTap: onOpenSkill == null
                    ? null
                    : () => onOpenSkill!(entry.value[index].id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ClassArmoryBanner extends StatelessWidget {
  final HeroClass activeClass;

  const _ClassArmoryBanner({required this.activeClass});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Os quatro caminhos podem ser treinados livremente.',
      child: Container(
        key: const ValueKey<String>('skills-class-armory-banner'),
        height: 142,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.voidBlack,
          borderRadius: AppTheme.panelRadius,
          border: Border.all(
            color: AppTheme.accentYellow.withValues(alpha: 0.58),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              MedievalAssets.classArmory,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.none,
              cacheWidth: 900,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: AppTheme.darkCardRaised),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x2608090A),
                    Color(0xB308090A),
                    Color(0xF208090A),
                  ],
                  stops: [0, 0.52, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QUATRO JURAMENTOS, UMA SÓ ALMA',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.accentYellow,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Nenhuma classe aprisiona seu destino. Troque o estilo de '
                    'combate e desenvolva Cavaleiro, Assassino, Mago e Arqueiro.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Juramento em uso: ${activeClass.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.combatBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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

class _ClassMasterySeal extends StatelessWidget {
  final _ClassPath path;
  final Skill? skill;
  final bool active;

  const _ClassMasterySeal({
    required this.path,
    required this.skill,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>('class-mastery-${path.heroClass.saveKey}'),
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            path.color.withValues(alpha: active ? 0.22 : 0.09),
            AppTheme.voidBlack.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: AppTheme.panelRadius,
        border: Border.all(
          color: path.color.withValues(alpha: active ? 0.9 : 0.42),
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: path.color.withValues(alpha: 0.16),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.voidBlack.withValues(alpha: 0.72),
              border: Border.all(color: path.color.withValues(alpha: 0.72)),
              shape: BoxShape.circle,
            ),
            child: Icon(path.icon, size: 18, color: path.color),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  path.heroClass.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Nível ${skill?.level ?? 1}${active ? ' · EM USO' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: active ? path.color : AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: active ? FontWeight.bold : null,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedXpProgress(
                  skillId: path.skillId,
                  level: skill?.level ?? 1,
                  experience: skill?.experience ?? 0,
                  experienceToNextLevel:
                      skill?.experienceToNextLevel ??
                      Skill.experienceRequiredForLevel(1),
                  color: path.color,
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text(
                  path.epithet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassPath {
  final HeroClass heroClass;
  final String skillId;
  final String epithet;
  final IconData icon;
  final Color color;

  const _ClassPath({
    required this.heroClass,
    required this.skillId,
    required this.epithet,
    required this.icon,
    required this.color,
  });
}
