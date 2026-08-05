enum WorkshopType {
  forge,
  artisanWorkshop,
  arcanistSanctum,
  shadowAtelier,
  alchemyLaboratory,
}

extension WorkshopTypeDetails on WorkshopType {
  String get displayName => switch (this) {
    WorkshopType.forge => 'Forja do Ferreiro',
    WorkshopType.artisanWorkshop => 'Oficina do Artesão',
    WorkshopType.arcanistSanctum => 'Santuário do Arcanista',
    WorkshopType.shadowAtelier => 'Ateliê do Véu',
    WorkshopType.alchemyLaboratory => 'Laboratório de Alquimia',
  };

  String get description => switch (this) {
    WorkshopType.forge => 'Forja armas, escudos e armaduras de cavaleiro.',
    WorkshopType.artisanWorkshop =>
      'Talha arcos, flechas e proteções leves de arqueiro.',
    WorkshopType.arcanistSanctum =>
      'Tecelagem arcana para cajados, vestes e magias.',
    WorkshopType.shadowAtelier =>
      'Bancada clandestina para lâminas e trajes de assassino.',
    WorkshopType.alchemyLaboratory =>
      'Destila ingredientes de coleta e espólios de combate.',
  };
}

class RegionRequirement {
  final int requiredCombatLevel;
  final Map<String, int> requiredSkillLevels;
  final String? prerequisiteRegionId;

  const RegionRequirement({
    this.requiredCombatLevel = 1,
    this.requiredSkillLevels = const {},
    this.prerequisiteRegionId,
  });

  bool isMet({
    required int combatLevel,
    Map<String, int> skillLevels = const {},
    Set<String> completedRegionIds = const {},
  }) {
    if (combatLevel < requiredCombatLevel) return false;
    if (prerequisiteRegionId != null &&
        !completedRegionIds.contains(prerequisiteRegionId)) {
      return false;
    }
    for (final entry in requiredSkillLevels.entries) {
      if ((skillLevels[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }
}

class WorldRegion {
  final String id;
  final String name;
  final String lore;
  final String sigil;
  final int primaryColorValue;
  final int accentColorValue;
  final RegionRequirement requirement;
  final List<String> enemyIds;
  final List<WorkshopType> workshops;

  const WorldRegion({
    required this.id,
    required this.name,
    required this.lore,
    required this.sigil,
    required this.primaryColorValue,
    required this.accentColorValue,
    required this.requirement,
    required this.enemyIds,
    required this.workshops,
  });
}
