import 'package:realm_idle_game/features/content/models/world_region.dart';

abstract final class WorldRegionCatalog {
  static const List<WorldRegion> all = [
    WorldRegion(
      id: 'ashen_crossroads',
      name: 'Encruzilhada das Cinzas',
      lore:
          'Sob uma lua sem calor, viajantes acendem fogueiras com madeira '
          'de cada reino perdido. As estradas terminam aqui, mas as runas '
          'gravadas nas pedras insistem que este é apenas o começo.',
      sigil: 'ᚱ',
      primaryColorValue: 0xFF24201D,
      accentColorValue: 0xFF9A6A42,
      requirement: RegionRequirement(),
      enemyIds: ['grave_rat'],
      workshops: [WorkshopType.forge, WorkshopType.alchemyLaboratory],
    ),
    WorldRegion(
      id: 'whispering_woods',
      name: 'Bosque dos Sussurros',
      lore:
          'Galhos retorcidos repetem nomes que ninguém pronunciou. Entre '
          'raízes marcadas, artesãos e agentes do Véu trabalham longe dos '
          'olhos da coroa.',
      sigil: 'ᛇ',
      primaryColorValue: 0xFF14231C,
      accentColorValue: 0xFF5E8A62,
      requirement: RegionRequirement(
        requiredCombatLevel: 10,
        requiredSkillLevels: {'woodcutting': 10},
        prerequisiteRegionId: 'ashen_crossroads',
      ),
      enemyIds: ['grave_rat', 'rune_cultist'],
      workshops: [WorkshopType.artisanWorkshop, WorkshopType.shadowAtelier],
    ),
    WorldRegion(
      id: 'drowned_coast',
      name: 'Costa dos Afogados',
      lore:
          'Sinos submersos dobram sob marés negras. Pescadores recolhem '
          'relíquias nos anzóis enquanto alquimistas destilam o sal que '
          'escorre das tumbas inundadas.',
      sigil: 'ᛚ',
      primaryColorValue: 0xFF10242B,
      accentColorValue: 0xFF4D8491,
      requirement: RegionRequirement(
        requiredCombatLevel: 20,
        requiredSkillLevels: {'fishing': 20},
        prerequisiteRegionId: 'whispering_woods',
      ),
      enemyIds: ['rune_cultist', 'crypt_wolf'],
      workshops: [WorkshopType.artisanWorkshop, WorkshopType.alchemyLaboratory],
    ),
    WorldRegion(
      id: 'hollow_crypts',
      name: 'Criptas Ocas',
      lore:
          'Corredores sem fim guardam juramentos que sobreviveram aos seus '
          'donos. No coração da necrópole, o Véu e o Arcanista negociam '
          'segredos à luz de velas violetas.',
      sigil: 'ᛞ',
      primaryColorValue: 0xFF211B29,
      accentColorValue: 0xFF80628F,
      requirement: RegionRequirement(
        requiredCombatLevel: 30,
        requiredSkillLevels: {'mining': 30},
        prerequisiteRegionId: 'drowned_coast',
      ),
      enemyIds: ['crypt_wolf', 'hollow_knight'],
      workshops: [WorkshopType.shadowAtelier, WorkshopType.arcanistSanctum],
    ),
    WorldRegion(
      id: 'obsidian_bastion',
      name: 'Bastião de Obsidiana',
      lore:
          'As muralhas foram fundidas em uma única noite e jamais '
          'refletiram o amanhecer. Martelos ainda ecoam na forja onde '
          'cavaleiros selam metal com votos de sangue.',
      sigil: 'ᛏ',
      primaryColorValue: 0xFF19191D,
      accentColorValue: 0xFF8E3F39,
      requirement: RegionRequirement(
        requiredCombatLevel: 40,
        requiredSkillLevels: {'mining': 40},
        prerequisiteRegionId: 'hollow_crypts',
      ),
      enemyIds: ['hollow_knight'],
      workshops: [WorkshopType.forge],
    ),
    WorldRegion(
      id: 'abyssal_reaches',
      name: 'Confins Abissais',
      lore:
          'Pontes de osso cruzam um oceano imóvel sob a terra. Cada '
          'escama arrancada das serpentes carrega um fragmento daquela '
          'escuridão paciente.',
      sigil: 'ᚺ',
      primaryColorValue: 0xFF0E1822,
      accentColorValue: 0xFF316C78,
      requirement: RegionRequirement(
        requiredCombatLevel: 60,
        requiredSkillLevels: {'fishing': 50, 'mining': 60},
        prerequisiteRegionId: 'obsidian_bastion',
      ),
      enemyIds: ['hollow_knight', 'abyss_wyrm'],
      workshops: [WorkshopType.alchemyLaboratory, WorkshopType.artisanWorkshop],
    ),
    WorldRegion(
      id: 'runic_wastes',
      name: 'Ermos Rúnicos',
      lore:
          'Símbolos colossais queimam sobre a planície devastada. Magos '
          'ouvem ali a gramática do mundo; assassinos escutam apenas os '
          'intervalos silenciosos entre uma palavra e outra.',
      sigil: 'ᛟ',
      primaryColorValue: 0xFF251C31,
      accentColorValue: 0xFF9A65BC,
      requirement: RegionRequirement(
        requiredCombatLevel: 80,
        requiredSkillLevels: {'mining': 80, 'woodcutting': 50},
        prerequisiteRegionId: 'abyssal_reaches',
      ),
      enemyIds: ['abyss_wyrm', 'rune_lord'],
      workshops: [WorkshopType.arcanistSanctum, WorkshopType.shadowAtelier],
    ),
    WorldRegion(
      id: 'eclipse_throne',
      name: 'Trono do Eclipse',
      lore:
          'Acima das nuvens mortas, cinco oficinas cercam um trono vazio. '
          'Dizem que quem dominar cada ofício poderá gravar uma nova runa '
          'no céu — ou apagar a última.',
      sigil: 'ᛝ',
      primaryColorValue: 0xFF160F1B,
      accentColorValue: 0xFFC29A52,
      requirement: RegionRequirement(
        requiredCombatLevel: 100,
        requiredSkillLevels: {'mining': 100, 'woodcutting': 50, 'fishing': 50},
        prerequisiteRegionId: 'runic_wastes',
      ),
      enemyIds: ['rune_lord'],
      workshops: WorkshopType.values,
    ),
  ];

  static WorldRegion? byId(String id) {
    for (final region in all) {
      if (region.id == id) return region;
    }
    return null;
  }

  static List<WorldRegion> unlockedBy({
    required int combatLevel,
    Map<String, int> skillLevels = const {},
    Set<String> completedRegionIds = const {},
  }) {
    return all
        .where(
          (region) => region.requirement.isMet(
            combatLevel: combatLevel,
            skillLevels: skillLevels,
            completedRegionIds: completedRegionIds,
          ),
        )
        .toList(growable: false);
  }
}
