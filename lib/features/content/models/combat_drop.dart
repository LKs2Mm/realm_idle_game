enum CombatDropRarity { common, uncommon, rare, epic, legendary }

class CombatDropDefinition {
  final String id;
  final String name;
  final String description;
  final String sigil;
  final CombatDropRarity rarity;
  final List<String> sourceEncounterIds;
  final double dropChance;
  final int minimumQuantity;
  final int maximumQuantity;

  const CombatDropDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.sigil,
    required this.rarity,
    required this.sourceEncounterIds,
    required this.dropChance,
    this.minimumQuantity = 1,
    this.maximumQuantity = 1,
  });

  double get averageQuantity => (minimumQuantity + maximumQuantity) / 2;
}
