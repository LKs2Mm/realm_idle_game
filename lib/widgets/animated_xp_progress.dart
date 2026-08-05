import 'package:flutter/material.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/utils/number_formatters.dart';

class AnimatedXpProgress extends StatelessWidget {
  final String skillId;
  final int level;
  final double experience;
  final int experienceToNextLevel;
  final Color color;
  final double minHeight;

  const AnimatedXpProgress({
    super.key,
    required this.skillId,
    required this.level,
    required this.experience,
    required this.experienceToNextLevel,
    required this.color,
    this.minHeight = 6,
  });

  double get _progress {
    if (experienceToNextLevel <= 0) return 0;
    return (experience / experienceToNextLevel).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);

    return Semantics(
      label: 'Progresso de experiência',
      value: '${formatXp(experience)} de $experienceToNextLevel XP',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('$skillId:$level'),
            tween: Tween<double>(begin: progress, end: progress),
            duration: duration,
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: animatedProgress,
                  minHeight: minHeight,
                  color: color,
                  backgroundColor: AppTheme.darkCardBorder,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AnimatedXpText extends StatelessWidget {
  final String skillId;
  final int level;
  final double experience;
  final int experienceToNextLevel;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const AnimatedXpText({
    super.key,
    required this.skillId,
    required this.level,
    required this.experience,
    required this.experienceToNextLevel,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);

    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('$skillId:$level'),
        tween: Tween<double>(begin: experience, end: experience),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, animatedExperience, child) {
          return Text(
            '${formatXp(animatedExperience)} / $experienceToNextLevel XP',
            maxLines: maxLines,
            overflow: overflow,
            style: style,
          );
        },
      ),
    );
  }
}
