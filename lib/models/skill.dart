enum SkillCategory { gathering, processing, combat, divinity }

class Skill {
  static const int experiencePrecision = 10;
  static const double maximumStoredExperience = 1000000000000;

  final String id;
  final String name;
  final SkillCategory category;
  int level;
  double experience;
  int experienceToNextLevel;

  Skill({
    required this.id,
    required this.name,
    required this.category,
    this.level = 1,
    this.experience = 0.0,
    int? experienceToNextLevel,
  }) : experienceToNextLevel =
           experienceToNextLevel ?? experienceRequiredForLevel(level) {
    if (level < 1) level = 1;
    if (!experience.isFinite || experience < 0) experience = 0;
    experience = normalizeExperience(experience);
    _applyLevelUps();
  }

  double get progressPercentage {
    if (experienceToNextLevel <= 0) return 0;
    return experience / experienceToNextLevel;
  }

  void addExperience(double amount) {
    if (!amount.isFinite || amount <= 0) return;
    experience = normalizeExperience(experience + amount);
    _applyLevelUps();
  }

  void _applyLevelUps() {
    while (experience >= experienceToNextLevel) {
      experience = normalizeExperience(experience - experienceToNextLevel);
      level++;
      experienceToNextLevel = experienceRequiredForLevel(level);
    }
  }

  static int experienceRequiredForLevel(int level) {
    final offset = (level < 1 ? 1 : level) - 1;
    return 100 + (40 * offset) + (10 * offset * offset);
  }

  static int totalExperienceToReachLevel(int targetLevel) {
    var total = 0;
    for (var level = 1; level < targetLevel; level++) {
      total += experienceRequiredForLevel(level);
    }
    return total;
  }

  static double normalizeExperience(double value) {
    if (!value.isFinite || value <= 0) return 0.0;
    final bounded = value > maximumStoredExperience
        ? maximumStoredExperience
        : value;
    return (bounded * experiencePrecision).roundToDouble() /
        experiencePrecision;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.index,
      'level': level,
      'experience': experience,
      'experienceToNextLevel': experienceToNextLevel,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    final levelValue = json['level'];
    final parsedLevel = levelValue is num && levelValue.isFinite
        ? levelValue.toInt().clamp(1, 1000000)
        : 1;
    final experienceValue = json['experience'];
    final parsedExperience = experienceValue is num && experienceValue.isFinite
        ? experienceValue.toDouble().clamp(0, double.maxFinite).toDouble()
        : 0.0;
    final categoryValue = json['category'];
    final categoryIndex = categoryValue is num
        ? categoryValue.toInt().clamp(0, SkillCategory.values.length - 1)
        : 0;

    return Skill(
      id: json['id'] is String ? json['id'] as String : 'unknown',
      name: json['name'] is String ? json['name'] as String : 'Habilidade',
      category: SkillCategory.values[categoryIndex],
      level: parsedLevel,
      experience: parsedExperience,
      experienceToNextLevel: experienceRequiredForLevel(parsedLevel),
    );
  }
}
