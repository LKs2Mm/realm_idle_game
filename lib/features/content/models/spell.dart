import 'package:realm_idle_game/features/content/models/content_cost.dart';

enum SpellSchool { flame, frost, storm, blood, voidMagic, warding }

extension SpellSchoolDetails on SpellSchool {
  String get saveKey => switch (this) {
    SpellSchool.flame => 'flame',
    SpellSchool.frost => 'frost',
    SpellSchool.storm => 'storm',
    SpellSchool.blood => 'blood',
    SpellSchool.voidMagic => 'void',
    SpellSchool.warding => 'warding',
  };

  String get displayName => switch (this) {
    SpellSchool.flame => 'Chama Rúnica',
    SpellSchool.frost => 'Geada Sepulcral',
    SpellSchool.storm => 'Tempestade',
    SpellSchool.blood => 'Sangue',
    SpellSchool.voidMagic => 'Vazio',
    SpellSchool.warding => 'Proteção',
  };
}

enum SpellEffectType {
  magicDamage,
  damageOverTime,
  armorPiercing,
  criticalChance,
  attackSpeed,
  defense,
  healing,
  lifeSteal,
  enemyWeakening,
  lootChance,
}

class SpellEffect {
  final SpellEffectType type;
  final double magnitude;
  final int durationSeconds;

  const SpellEffect({
    required this.type,
    required this.magnitude,
    this.durationSeconds = 0,
  });

  bool get isTimed => durationSeconds > 0;
}

class SpellDefinition {
  final String id;
  final String name;
  final String description;
  final String sigil;
  final SpellSchool school;
  final int requiredLevel;
  final int craftDurationMilliseconds;
  final double craftingExperience;
  final ContentCost cost;
  final List<SpellEffect> effects;

  const SpellDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.sigil,
    required this.school,
    required this.requiredLevel,
    required this.craftDurationMilliseconds,
    required this.craftingExperience,
    required this.cost,
    required this.effects,
  });

  double get craftDurationSeconds => craftDurationMilliseconds / 1000;
}
