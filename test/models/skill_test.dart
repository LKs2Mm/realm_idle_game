import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/models/skill.dart';

void main() {
  Skill mining({double experience = 0.0}) => Skill(
    id: 'mining',
    name: 'Mineração',
    category: SkillCategory.gathering,
    experience: experience,
  );

  test('keeps XP precise to one decimal place', () {
    final skill = mining();

    skill.addExperience(5.6);
    skill.addExperience(1.3);

    expect(skill.experience, 6.9);
    expect(skill.progressPercentage, closeTo(0.138, 0.000001));
  });

  test('levels up exactly at the threshold without decimal residue', () {
    final skill = mining(experience: 49.4);

    skill.addExperience(0.6);

    expect(skill.level, 2);
    expect(skill.experience, 0.0);
    expect(skill.experienceToNextLevel, 80);
  });

  test('carries decimal XP through multiple level-ups', () {
    final skill = mining();

    skill.addExperience(135.6);

    expect(skill.level, 3);
    expect(skill.experience, 5.6);
    expect(skill.experienceToNextLevel, 130);
  });

  test('ignores invalid and negative XP rewards', () {
    final skill = mining();

    skill.addExperience(-1);
    skill.addExperience(double.infinity);
    skill.addExperience(double.nan);

    expect(skill.experience, 0.0);
    expect(skill.level, 1);
  });

  test('serializes and restores decimal XP', () {
    final restored = Skill.fromJson({...mining(experience: 5.6).toJson()});

    expect(restored.experience, 5.6);
    expect(restored.experienceToNextLevel, 50);
  });

  test('the level curve grows strictly through level 100', () {
    for (var level = 1; level < 100; level++) {
      expect(
        Skill.experienceRequiredForLevel(level + 1),
        greaterThan(Skill.experienceRequiredForLevel(level)),
      );
    }
    expect(Skill.experienceRequiredForLevel(100), 100040);
    expect(Skill.totalExperienceToReachLevel(100), 3287460);
  });
}
