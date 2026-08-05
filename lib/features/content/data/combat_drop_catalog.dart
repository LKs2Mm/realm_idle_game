import 'package:realm_idle_game/features/content/models/combat_drop.dart';

abstract final class CombatDropCatalog {
  static const List<CombatDropDefinition> all = [
    CombatDropDefinition(
      id: 'grave_dust',
      name: 'Pó sepulcral',
      description: 'Cinza fria recolhida dos túneis onde os mortos caminham.',
      sigil: 'ᛞ',
      rarity: CombatDropRarity.common,
      sourceEncounterIds: ['grave_rat'],
      dropChance: 0.65,
      minimumQuantity: 1,
      maximumQuantity: 3,
    ),
    CombatDropDefinition(
      id: 'tarnished_fang',
      name: 'Presa maculada',
      description: 'Uma presa escurecida por anos de fome nas catacumbas.',
      sigil: 'ᚾ',
      rarity: CombatDropRarity.uncommon,
      sourceEncounterIds: ['grave_rat', 'crypt_wolf'],
      dropChance: 0.28,
    ),
    CombatDropDefinition(
      id: 'cultist_cloth',
      name: 'Tecido do cultista',
      description: 'Retalho marcado por cera, sangue e orações proibidas.',
      sigil: 'ᚱ',
      rarity: CombatDropRarity.common,
      sourceEncounterIds: ['rune_cultist'],
      dropChance: 0.58,
      minimumQuantity: 1,
      maximumQuantity: 2,
    ),
    CombatDropDefinition(
      id: 'rune_ink',
      name: 'Tinta rúnica',
      description: 'Pigmento vivo usado para fixar símbolos sobre matéria.',
      sigil: 'ᚨ',
      rarity: CombatDropRarity.rare,
      sourceEncounterIds: ['rune_cultist', 'rune_lord'],
      dropChance: 0.18,
    ),
    CombatDropDefinition(
      id: 'crypt_leather',
      name: 'Couro da cripta',
      description: 'Couro espectral que permanece flexível mesmo sob geada.',
      sigil: 'ᛇ',
      rarity: CombatDropRarity.uncommon,
      sourceEncounterIds: ['crypt_wolf'],
      dropChance: 0.48,
      minimumQuantity: 1,
      maximumQuantity: 2,
    ),
    CombatDropDefinition(
      id: 'ectoplasm',
      name: 'Ectoplasma velado',
      description: 'Resíduo de uma alma incapaz de abandonar sua vigília.',
      sigil: 'ᛉ',
      rarity: CombatDropRarity.rare,
      sourceEncounterIds: ['crypt_wolf', 'hollow_knight'],
      dropChance: 0.16,
    ),
    CombatDropDefinition(
      id: 'hollow_steel',
      name: 'Aço oco',
      description: 'Metal sem brilho arrancado de uma armadura sem alma.',
      sigil: 'ᛏ',
      rarity: CombatDropRarity.rare,
      sourceEncounterIds: ['hollow_knight'],
      dropChance: 0.38,
      minimumQuantity: 1,
      maximumQuantity: 2,
    ),
    CombatDropDefinition(
      id: 'oath_shard',
      name: 'Estilhaço de juramento',
      description: 'Fragmento que ainda murmura uma promessa esquecida.',
      sigil: 'ᛃ',
      rarity: CombatDropRarity.epic,
      sourceEncounterIds: ['hollow_knight'],
      dropChance: 0.12,
    ),
    CombatDropDefinition(
      id: 'abyssal_scale',
      name: 'Escama abissal',
      description: 'Escama negra cuja superfície parece absorver a luz.',
      sigil: 'ᛚ',
      rarity: CombatDropRarity.epic,
      sourceEncounterIds: ['abyss_wyrm'],
      dropChance: 0.32,
      minimumQuantity: 1,
      maximumQuantity: 2,
    ),
    CombatDropDefinition(
      id: 'void_ichor',
      name: 'Ícor do vazio',
      description: 'Fluido impossível que se move contra a gravidade.',
      sigil: 'ᚺ',
      rarity: CombatDropRarity.epic,
      sourceEncounterIds: ['abyss_wyrm', 'rune_lord'],
      dropChance: 0.10,
    ),
    CombatDropDefinition(
      id: 'runic_core',
      name: 'Núcleo rúnico',
      description: 'Coração mineral carregado com linguagem primordial.',
      sigil: 'ᛟ',
      rarity: CombatDropRarity.legendary,
      sourceEncounterIds: ['rune_lord'],
      dropChance: 0.08,
    ),
    CombatDropDefinition(
      id: 'lord_sigil',
      name: 'Sigilo do lorde',
      description: 'Marca soberana capaz de selar artefatos ancestrais.',
      sigil: 'ᛝ',
      rarity: CombatDropRarity.legendary,
      sourceEncounterIds: ['rune_lord'],
      dropChance: 0.025,
    ),
  ];

  static CombatDropDefinition? byId(String id) {
    for (final drop in all) {
      if (drop.id == id) return drop;
    }
    return null;
  }

  static List<CombatDropDefinition> forEncounter(String encounterId) {
    return all
        .where((drop) => drop.sourceEncounterIds.contains(encounterId))
        .toList(growable: false);
  }
}
