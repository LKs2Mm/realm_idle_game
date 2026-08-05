import 'package:realm_idle_game/models/skill.dart';

class CombatReward {
  final String encounterId;
  final int victories;
  final int gold;
  final double experience;
  final Map<String, int> loot;

  /// Health actually removed while resolving this reward batch.
  ///
  /// The value comes from the game state instead of being recomputed by the
  /// service, so armor, buffs and future mitigation rules remain authoritative.
  final int damageTaken;

  /// Whether this reward batch left the hero without health.
  final bool wasDefeated;

  const CombatReward({
    required this.encounterId,
    required this.victories,
    required this.gold,
    required this.experience,
    this.loot = const {},
    this.damageTaken = 0,
    this.wasDefeated = false,
  });
}

class CombatEncounter {
  final String id;
  final String name;
  final String description;
  final int requiredAttackLevel;
  final int cycleDurationMilliseconds;
  final int goldPerVictory;
  final double experiencePerVictory;

  /// Base incoming damage associated with one completed victory.
  ///
  /// GameState remains responsible for applying mitigation and returning the
  /// actual damage through [CombatReward.damageTaken].
  final int damagePerVictory;
  final String sigil;

  const CombatEncounter({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredAttackLevel,
    required this.cycleDurationMilliseconds,
    required this.goldPerVictory,
    required this.experiencePerVictory,
    this.damagePerVictory = 0,
    required this.sigil,
  });

  double get cycleSeconds => cycleDurationMilliseconds / 1000;

  double get goldPerMinute =>
      goldPerVictory * 60000 / cycleDurationMilliseconds;

  double get experiencePerMinute => Skill.normalizeExperience(
    experiencePerVictory * 60000 / cycleDurationMilliseconds,
  );

  double get damagePerMinute =>
      damagePerVictory * 60000 / cycleDurationMilliseconds;

  static const List<CombatEncounter> all = [
    CombatEncounter(
      id: 'grave_rat',
      name: 'Rato Sepulcral',
      description: 'Roedor faminto marcado pelas runas das catacumbas.',
      requiredAttackLevel: 1,
      cycleDurationMilliseconds: 4000,
      goldPerVictory: 2,
      experiencePerVictory: 3,
      damagePerVictory: 1,
      sigil: 'ᚱ',
    ),
    CombatEncounter(
      id: 'rune_cultist',
      name: 'Cultista Rúnico',
      description: 'Devoto encapuzado que alimenta símbolos proibidos.',
      requiredAttackLevel: 10,
      cycleDurationMilliseconds: 6000,
      goldPerVictory: 10,
      experiencePerVictory: 8,
      damagePerVictory: 2,
      sigil: 'ᚲ',
    ),
    CombatEncounter(
      id: 'crypt_wolf',
      name: 'Lobo da Cripta',
      description: 'Fera espectral que guarda os túmulos esquecidos.',
      requiredAttackLevel: 20,
      cycleDurationMilliseconds: 8000,
      goldPerVictory: 40,
      experiencePerVictory: 20,
      damagePerVictory: 4,
      sigil: 'ᛉ',
    ),
    CombatEncounter(
      id: 'hollow_knight',
      name: 'Cavaleiro Oco',
      description: 'Armadura sem alma, presa a um juramento ancestral.',
      requiredAttackLevel: 40,
      cycleDurationMilliseconds: 12000,
      goldPerVictory: 160,
      experiencePerVictory: 50,
      damagePerVictory: 7,
      sigil: 'ᛏ',
    ),
    CombatEncounter(
      id: 'abyss_wyrm',
      name: 'Serpe do Abismo',
      description: 'Criatura de escamas negras nascida sob a fortaleza.',
      requiredAttackLevel: 60,
      cycleDurationMilliseconds: 15000,
      goldPerVictory: 500,
      experiencePerVictory: 100,
      damagePerVictory: 11,
      sigil: 'ᛇ',
    ),
    CombatEncounter(
      id: 'rune_lord',
      name: 'Lorde das Runas',
      description: 'Soberano profano que grava destinos em pedra e sangue.',
      requiredAttackLevel: 80,
      cycleDurationMilliseconds: 18000,
      goldPerVictory: 1500,
      experiencePerVictory: 180,
      damagePerVictory: 16,
      sigil: 'ᛟ',
    ),
  ];

  static CombatEncounter? byId(String id) {
    for (final encounter in all) {
      if (encounter.id == id) return encounter;
    }
    return null;
  }
}
