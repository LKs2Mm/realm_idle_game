import 'package:realm_idle_game/features/content/models/alchemy.dart';
import 'package:realm_idle_game/features/content/models/content_cost.dart';

abstract final class PotionCatalog {
  static const List<PotionDefinition> all = [
    PotionDefinition(
      id: 'gravefury_draught',
      name: 'Tônico da Fúria Sepulcral',
      description: 'Aquece o sangue com a fome incansável das catacumbas.',
      sigil: 'ᚢ',
      requiredLevel: 1,
      craftDurationMilliseconds: 5000,
      craftingExperience: 7,
      durationSeconds: 300,
      potency: 0.08,
      buffType: BuffType.attackPower,
      cost: ContentCost({'sardine': 2, 'grave_dust': 2}),
    ),
    PotionDefinition(
      id: 'cryptskin_elixir',
      name: 'Elixir da Pele de Cripta',
      description: 'Reveste a pele com uma couraça fria e quase espectral.',
      sigil: 'ᛉ',
      requiredLevel: 15,
      craftDurationMilliseconds: 8000,
      craftingExperience: 14,
      durationSeconds: 360,
      potency: 0.10,
      buffType: BuffType.defense,
      cost: ContentCost({'iron': 4, 'crypt_leather': 2}),
    ),
    PotionDefinition(
      id: 'silverhand_distillate',
      name: 'Destilado da Mão de Prata',
      description: 'Aguça movimentos repetidos na mina, mata e costa.',
      sigil: 'ᚱ',
      requiredLevel: 30,
      craftDurationMilliseconds: 12000,
      craftingExperience: 26,
      durationSeconds: 420,
      potency: 0.12,
      buffType: BuffType.gatheringSpeed,
      cost: ContentCost({'silver': 3, 'cultist_cloth': 2}),
    ),
    PotionDefinition(
      id: 'harvesters_omen',
      name: 'Presságio do Coletor',
      description: 'Faz cada veio, árvore e cardume revelar um pouco mais.',
      sigil: 'ᛃ',
      requiredLevel: 45,
      craftDurationMilliseconds: 17000,
      craftingExperience: 44,
      durationSeconds: 480,
      potency: 0.10,
      buffType: BuffType.gatheringYield,
      cost: ContentCost({'magic_log': 3, 'rune_ink': 2}),
    ),
    PotionDefinition(
      id: 'wolfblood_tonic',
      name: 'Tônico de Sangue Lupino',
      description: 'Apaga a hesitação entre um ataque e o seguinte.',
      sigil: 'ᛏ',
      requiredLevel: 60,
      craftDurationMilliseconds: 23000,
      craftingExperience: 70,
      durationSeconds: 420,
      potency: 0.14,
      buffType: BuffType.combatSpeed,
      cost: ContentCost({'salmon': 4, 'ectoplasm': 3}),
    ),
    PotionDefinition(
      id: 'gilded_ichor',
      name: 'Ícor Dourado',
      description: 'Atrai moedas como se toda vitória já estivesse escrita.',
      sigil: 'ᚠ',
      requiredLevel: 75,
      craftDurationMilliseconds: 30000,
      craftingExperience: 108,
      durationSeconds: 600,
      potency: 0.18,
      buffType: BuffType.goldGain,
      cost: ContentCost({'gold': 4, 'oath_shard': 2}),
    ),
    PotionDefinition(
      id: 'abyssal_eye_philter',
      name: 'Filtro do Olho Abissal',
      description: 'Revela espólios escondidos sob carne, escama e sombra.',
      sigil: 'ᚺ',
      requiredLevel: 90,
      craftDurationMilliseconds: 38000,
      craftingExperience: 162,
      durationSeconds: 600,
      potency: 0.15,
      buffType: BuffType.lootChance,
      cost: ContentCost({'shark': 2, 'abyssal_scale': 2, 'void_ichor': 1}),
    ),
    PotionDefinition(
      id: 'awakening_draught',
      name: 'Poção do Despertar Rúnico',
      description: 'Abre a mente para lições gravadas no próprio destino.',
      sigil: 'ᛟ',
      requiredLevel: 105,
      craftDurationMilliseconds: 48000,
      craftingExperience: 240,
      durationSeconds: 600,
      potency: 0.20,
      buffType: BuffType.experienceGain,
      cost: ContentCost({
        'arcane_crystal': 3,
        'runic_core': 2,
        'lord_sigil': 1,
      }),
    ),
  ];

  static PotionDefinition? byId(String id) {
    for (final potion in all) {
      if (potion.id == id) return potion;
    }
    return null;
  }

  static PotionDefinition? forBuff(BuffType type) {
    for (final potion in all) {
      if (potion.buffType == type) return potion;
    }
    return null;
  }
}
