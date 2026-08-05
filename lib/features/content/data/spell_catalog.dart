import 'package:realm_idle_game/features/content/models/content_cost.dart';
import 'package:realm_idle_game/features/content/models/spell.dart';

abstract final class SpellCatalog {
  static const List<SpellDefinition> all = [
    SpellDefinition(
      id: 'runic_ember',
      name: 'Brasa Rúnica',
      description: 'Uma runa incandescente persegue o alvo e marca sua carne.',
      sigil: 'ᚲ',
      school: SpellSchool.flame,
      requiredLevel: 1,
      craftDurationMilliseconds: 4000,
      craftingExperience: 6,
      cost: ContentCost({'rune_essence': 4, 'copper': 2}),
      effects: [
        SpellEffect(type: SpellEffectType.magicDamage, magnitude: 0.08),
      ],
    ),
    SpellDefinition(
      id: 'gravefrost_shard',
      name: 'Estilhaço de Geada Fúnebre',
      description: 'Gelo de sepultura reduz o ímpeto da criatura atingida.',
      sigil: 'ᛁ',
      school: SpellSchool.frost,
      requiredLevel: 10,
      craftDurationMilliseconds: 6000,
      craftingExperience: 10,
      cost: ContentCost({'rune_essence': 6, 'grave_dust': 2}),
      effects: [
        SpellEffect(type: SpellEffectType.magicDamage, magnitude: 0.10),
        SpellEffect(
          type: SpellEffectType.enemyWeakening,
          magnitude: 0.04,
          durationSeconds: 8,
        ),
      ],
    ),
    SpellDefinition(
      id: 'storm_needle',
      name: 'Agulha da Tempestade',
      description: 'Prata eletrificada encontra frestas na defesa inimiga.',
      sigil: 'ᛋ',
      school: SpellSchool.storm,
      requiredLevel: 20,
      craftDurationMilliseconds: 9000,
      craftingExperience: 17,
      cost: ContentCost({'rune_essence': 10, 'silver': 3}),
      effects: [
        SpellEffect(type: SpellEffectType.armorPiercing, magnitude: 0.12),
      ],
    ),
    SpellDefinition(
      id: 'crimson_covenant',
      name: 'Pacto Carmesim',
      description: 'O conjurador transforma dor causada em vigor profano.',
      sigil: 'ᚷ',
      school: SpellSchool.blood,
      requiredLevel: 30,
      craftDurationMilliseconds: 13000,
      craftingExperience: 27,
      cost: ContentCost({'rune_essence': 14, 'crypt_leather': 3}),
      effects: [
        SpellEffect(
          type: SpellEffectType.lifeSteal,
          magnitude: 0.06,
          durationSeconds: 20,
        ),
      ],
    ),
    SpellDefinition(
      id: 'iron_rune_aegis',
      name: 'Égide da Runa Férrea',
      description: 'Uma inscrição de aço oco recebe o golpe em seu lugar.',
      sigil: 'ᛉ',
      school: SpellSchool.warding,
      requiredLevel: 40,
      craftDurationMilliseconds: 18000,
      craftingExperience: 41,
      cost: ContentCost({'rune_essence': 20, 'hollow_steel': 2}),
      effects: [
        SpellEffect(
          type: SpellEffectType.defense,
          magnitude: 0.14,
          durationSeconds: 30,
        ),
      ],
    ),
    SpellDefinition(
      id: 'abyssal_grasp',
      name: 'Garra Abissal',
      description: 'Dedos do vazio dilaceram o alvo e enfraquecem sua runa.',
      sigil: 'ᚦ',
      school: SpellSchool.voidMagic,
      requiredLevel: 50,
      craftDurationMilliseconds: 24000,
      craftingExperience: 60,
      cost: ContentCost({'rune_essence': 30, 'void_ichor': 2}),
      effects: [
        SpellEffect(type: SpellEffectType.magicDamage, magnitude: 0.18),
        SpellEffect(
          type: SpellEffectType.enemyWeakening,
          magnitude: 0.08,
          durationSeconds: 15,
        ),
      ],
    ),
    SpellDefinition(
      id: 'pyre_chain',
      name: 'Corrente da Pira',
      description: 'Elos de fogo antigo continuam ardendo após o impacto.',
      sigil: 'ᛒ',
      school: SpellSchool.flame,
      requiredLevel: 60,
      craftDurationMilliseconds: 30000,
      craftingExperience: 86,
      cost: ContentCost({
        'rune_essence': 45,
        'magic_log': 10,
        'abyssal_scale': 2,
      }),
      effects: [
        SpellEffect(type: SpellEffectType.magicDamage, magnitude: 0.20),
        SpellEffect(
          type: SpellEffectType.damageOverTime,
          magnitude: 0.05,
          durationSeconds: 12,
        ),
      ],
    ),
    SpellDefinition(
      id: 'winter_crown',
      name: 'Coroa do Inverno Morto',
      description: 'A quietude das criptas envolve o mago como uma coroa.',
      sigil: 'ᛇ',
      school: SpellSchool.frost,
      requiredLevel: 70,
      craftDurationMilliseconds: 37000,
      craftingExperience: 121,
      cost: ContentCost({'rune_essence': 65, 'mithril': 8, 'grave_dust': 8}),
      effects: [
        SpellEffect(
          type: SpellEffectType.defense,
          magnitude: 0.20,
          durationSeconds: 45,
        ),
        SpellEffect(
          type: SpellEffectType.enemyWeakening,
          magnitude: 0.10,
          durationSeconds: 20,
        ),
      ],
    ),
    SpellDefinition(
      id: 'thunder_verdict',
      name: 'Veredito do Trovão',
      description: 'Uma sentença rúnica cai antes que o inimigo possa reagir.',
      sigil: 'ᛏ',
      school: SpellSchool.storm,
      requiredLevel: 80,
      craftDurationMilliseconds: 45000,
      craftingExperience: 168,
      cost: ContentCost({'rune_essence': 90, 'runite': 5, 'runic_core': 1}),
      effects: [
        SpellEffect(type: SpellEffectType.magicDamage, magnitude: 0.30),
        SpellEffect(type: SpellEffectType.criticalChance, magnitude: 0.10),
      ],
    ),
    SpellDefinition(
      id: 'crimson_eclipse',
      name: 'Eclipse Carmesim',
      description:
          'O sangue derramado obscurece a lua e retorna ao conjurador.',
      sigil: 'ᛞ',
      school: SpellSchool.blood,
      requiredLevel: 90,
      craftDurationMilliseconds: 54000,
      craftingExperience: 230,
      cost: ContentCost({
        'rune_essence': 130,
        'orichalcum': 4,
        'lord_sigil': 1,
      }),
      effects: [
        SpellEffect(
          type: SpellEffectType.lifeSteal,
          magnitude: 0.14,
          durationSeconds: 35,
        ),
        SpellEffect(type: SpellEffectType.healing, magnitude: 0.18),
      ],
    ),
    SpellDefinition(
      id: 'gate_of_nothing',
      name: 'Portal do Nada',
      description: 'Por um instante, a ausência primordial atravessa o mundo.',
      sigil: 'ᛟ',
      school: SpellSchool.voidMagic,
      requiredLevel: 100,
      craftDurationMilliseconds: 65000,
      craftingExperience: 310,
      cost: ContentCost({
        'rune_essence': 180,
        'arcane_crystal': 6,
        'runic_core': 2,
      }),
      effects: [
        SpellEffect(type: SpellEffectType.armorPiercing, magnitude: 0.35),
        SpellEffect(type: SpellEffectType.lootChance, magnitude: 0.10),
      ],
    ),
    SpellDefinition(
      id: 'aegis_of_the_last_rune',
      name: 'Égide da Última Runa',
      description: 'A palavra final protege corpo e alma contra a extinção.',
      sigil: 'ᛝ',
      school: SpellSchool.warding,
      requiredLevel: 110,
      craftDurationMilliseconds: 78000,
      craftingExperience: 410,
      cost: ContentCost({
        'rune_essence': 260,
        'essence_stone': 8,
        'lord_sigil': 2,
      }),
      effects: [
        SpellEffect(
          type: SpellEffectType.defense,
          magnitude: 0.35,
          durationSeconds: 60,
        ),
        SpellEffect(type: SpellEffectType.healing, magnitude: 0.25),
      ],
    ),
  ];

  static SpellDefinition? byId(String id) {
    for (final spell in all) {
      if (spell.id == id) return spell;
    }
    return null;
  }

  static List<SpellDefinition> forSchool(SpellSchool school) {
    return all.where((spell) => spell.school == school).toList(growable: false);
  }
}
