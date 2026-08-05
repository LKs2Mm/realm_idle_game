import 'package:realm_idle_game/features/content/models/content_cost.dart';

enum BuffType {
  attackPower,
  defense,
  gatheringSpeed,
  gatheringYield,
  combatSpeed,
  goldGain,
  lootChance,
  experienceGain,
}

extension BuffTypeDetails on BuffType {
  String get saveKey => switch (this) {
    BuffType.attackPower => 'attackPower',
    BuffType.defense => 'defense',
    BuffType.gatheringSpeed => 'gatheringSpeed',
    BuffType.gatheringYield => 'gatheringYield',
    BuffType.combatSpeed => 'combatSpeed',
    BuffType.goldGain => 'goldGain',
    BuffType.lootChance => 'lootChance',
    BuffType.experienceGain => 'experienceGain',
  };

  String get displayName => switch (this) {
    BuffType.attackPower => 'Ataque',
    BuffType.defense => 'Defesa',
    BuffType.gatheringSpeed => 'Velocidade de coleta',
    BuffType.gatheringYield => 'Rendimento de coleta',
    BuffType.combatSpeed => 'Velocidade de combate',
    BuffType.goldGain => 'Ouro recebido',
    BuffType.lootChance => 'Chance de saque',
    BuffType.experienceGain => 'Experiência recebida',
  };

  static BuffType? fromSaveKey(String key) {
    for (final value in BuffType.values) {
      if (value.saveKey == key) return value;
    }
    return null;
  }
}

class PotionDefinition {
  final String id;
  final String name;
  final String description;
  final String sigil;
  final int requiredLevel;
  final int craftDurationMilliseconds;
  final double craftingExperience;
  final int durationSeconds;
  final double potency;
  final BuffType buffType;
  final ContentCost cost;

  const PotionDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.sigil,
    required this.requiredLevel,
    required this.craftDurationMilliseconds,
    required this.craftingExperience,
    required this.durationSeconds,
    required this.potency,
    required this.buffType,
    required this.cost,
  });

  double get multiplier => 1 + potency;
  double get craftDurationSeconds => craftDurationMilliseconds / 1000;
}
