import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/models/skill.dart';
import 'package:realm_idle_game/widgets/animated_xp_progress.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final Color categoryColor;
  final VoidCallback? onTap;

  const SkillCard({
    super.key,
    required this.skill,
    required this.categoryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: BeveledRectangleBorder(
        borderRadius: AppTheme.panelRadius,
        side: BorderSide(color: categoryColor.withValues(alpha: 0.5), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkCardRaised,
                AppTheme.darkCard,
                AppTheme.voidBlack.withValues(alpha: 0.92),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      skill.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontSize: 14, color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _SkillVisual(skill: skill, categoryColor: categoryColor),
                ],
              ),
              const Spacer(),
              Text(
                'Nível ${skill.level}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              AnimatedXpProgress(
                skillId: skill.id,
                level: skill.level,
                experience: skill.experience,
                experienceToNextLevel: skill.experienceToNextLevel,
                color: categoryColor,
              ),
              const SizedBox(height: 6),
              AnimatedXpText(
                skillId: skill.id,
                level: skill.level,
                experience: skill.experience,
                experienceToNextLevel: skill.experienceToNextLevel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillVisual extends StatelessWidget {
  final Skill skill;
  final Color categoryColor;

  const _SkillVisual({required this.skill, required this.categoryColor});

  @override
  Widget build(BuildContext context) {
    final asset = MedievalAssets.forSkill(skill.id);
    if (asset != null) {
      return MedievalEmblem(
        assetPath: asset,
        size: 38,
        semanticLabel: skill.name,
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.voidBlack.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: categoryColor.withValues(alpha: 0.72)),
      ),
      child: Icon(
        _skillIcon(skill.id, skill.category),
        color: categoryColor,
        size: 19,
      ),
    );
  }

  // Só cai aqui quando MedievalAssets.forSkill() não tem arte própria pra
  // essa skill (hoje: attack/defense/magic/cooking) — as demais já têm um
  // retrato de oficina/classe reaproveitado (ver forSkill).
  IconData _skillIcon(String skillId, SkillCategory category) {
    return switch (skillId) {
      'attack' => Icons.sports_martial_arts,
      'defense' => Icons.shield_outlined,
      'magic' => Icons.auto_fix_high,
      _ => switch (category) {
        SkillCategory.gathering => Icons.grass,
        SkillCategory.processing => Icons.build,
        SkillCategory.combat => Icons.sports_mma,
        SkillCategory.divinity => Icons.star,
      },
    };
  }
}
