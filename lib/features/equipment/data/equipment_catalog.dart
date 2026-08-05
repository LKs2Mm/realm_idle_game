import 'dart:collection';

import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';

abstract final class EquipmentCatalog {
  static final List<EquipmentDefinition> all = List.unmodifiable(_buildAll());

  static final Map<String, EquipmentDefinition> _byId = UnmodifiableMapView({
    for (final definition in all) definition.id: definition,
  });

  static EquipmentDefinition? byId(String id) => _byId[id];

  static EquipmentDefinition definition({
    required HeroClass heroClass,
    required EquipmentSlot slot,
    required EquipmentMaterial material,
    required EquipmentRarity rarity,
  }) {
    return _byId[_idFor(heroClass, slot, material, rarity)]!;
  }

  static List<EquipmentDefinition> forClass(HeroClass heroClass) =>
      List.unmodifiable(all.where((item) => item.heroClass == heroClass));

  static List<EquipmentDefinition> forWorkshop(EquipmentWorkshop workshop) =>
      List.unmodifiable(all.where((item) => item.workshop == workshop));

  static List<EquipmentDefinition> variantsFor(
    HeroClass heroClass,
    EquipmentSlot slot,
  ) => List.unmodifiable(
    all.where((item) => item.heroClass == heroClass && item.slot == slot),
  );

  static List<EquipmentDefinition> _buildAll() {
    final definitions = <EquipmentDefinition>[];
    for (final heroClass in HeroClass.values) {
      for (final slot in EquipmentSlot.values) {
        for (final material in EquipmentMaterial.values) {
          // Resolve eagerly so a renamed or removed GatheringResource fails fast.
          material.resource;
          for (final rarity in EquipmentRarity.values) {
            definitions.add(
              EquipmentDefinition(
                id: _idFor(heroClass, slot, material, rarity),
                name: _nameFor(heroClass, slot, material, rarity),
                description: _descriptionFor(heroClass, slot, material, rarity),
                heroClass: heroClass,
                slot: slot,
                material: material,
                rarity: rarity,
                workshop: heroClass.workshop,
                cost: _costFor(heroClass, slot, material, rarity),
                requiredWorkshopLevel: 1 + (material.tier * 10) + rarity.tier,
                craftDurationSeconds:
                    _craftBaseSeconds[slot]! +
                    (material.tier * 5) +
                    (rarity.tier * 4),
                workshopExperience: _experienceFor(slot, material, rarity),
                stats: _statsFor(heroClass, slot, material, rarity),
                visuals: _visualsFor(rarity),
              ),
            );
          }
        }
      }
    }
    return definitions;
  }

  static String _idFor(
    HeroClass heroClass,
    EquipmentSlot slot,
    EquipmentMaterial material,
    EquipmentRarity rarity,
  ) =>
      '${heroClass.saveKey}:${slot.saveKey}:${material.resourceId}:${rarity.saveKey}';

  static EquipmentCost _costFor(
    HeroClass heroClass,
    EquipmentSlot slot,
    EquipmentMaterial material,
    EquipmentRarity rarity,
  ) {
    final materialRank = material.tier + 1;
    final resourceAmount =
        _resourceBaseAmount[slot]! + (material.tier * 2) + (rarity.tier * 3);
    final gold =
        (_goldBaseAmount[slot]! *
            materialRank *
            materialRank *
            (100 + (rarity.tier * 65))) ~/
        100;
    final shaftBaseAmount = _shaftBaseAmount(heroClass, slot);
    return EquipmentCost(
      gold: gold,
      resources: {
        material.barResourceId: resourceAmount,
        if (shaftBaseAmount != null)
          material.shaftResourceId:
              shaftBaseAmount + material.tier + rarity.tier,
      },
    );
  }

  /// Arcos, aljavas e cajados mágicos levam uma haste talhada pelo Artesão
  /// além da barra de metal — as demais peças seguem só com metal.
  static int? _shaftBaseAmount(HeroClass heroClass, EquipmentSlot slot) {
    if (heroClass == HeroClass.archer) {
      return switch (slot) {
        EquipmentSlot.weapon => 8,
        EquipmentSlot.offhand => 6,
        _ => null,
      };
    }
    if (heroClass == HeroClass.mage && slot == EquipmentSlot.weapon) {
      return 8;
    }
    return null;
  }

  static double _experienceFor(
    EquipmentSlot slot,
    EquipmentMaterial material,
    EquipmentRarity rarity,
  ) {
    final duration =
        _craftBaseSeconds[slot]! + (material.tier * 5) + (rarity.tier * 4);
    final materials =
        _resourceBaseAmount[slot]! + (material.tier * 2) + (rarity.tier * 3);
    return ((duration * 14) + (materials * 20)) / 10;
  }

  static EquipmentStats _statsFor(
    HeroClass heroClass,
    EquipmentSlot slot,
    EquipmentMaterial material,
    EquipmentRarity rarity,
  ) {
    final slotPower = _slotBasePower[slot]!;
    final budget =
        slotPower +
        (material.tier * slotPower) +
        (rarity.tier * ((slotPower ~/ 2) + (material.tier * 2)));

    final weights = List<int>.from(_classStatWeights[heroClass]!);
    final slotBonus = _slotStatBonuses(heroClass, slot);
    for (var index = 0; index < weights.length; index++) {
      weights[index] += slotBonus[index];
    }
    final weightTotal = weights.fold<int>(0, (sum, value) => sum + value);
    final values = List<int>.filled(weights.length, 0);
    var allocated = 0;
    for (var index = 0; index < weights.length - 1; index++) {
      values[index] = (budget * weights[index]) ~/ weightTotal;
      allocated += values[index];
    }
    values[weights.length - 1] = budget - allocated;

    return EquipmentStats(
      physicalPower: values[0],
      arcanePower: values[1],
      defense: values[2],
      vitality: values[3],
      precision: values[4],
      evasion: values[5],
    );
  }

  static List<int> _slotStatBonuses(HeroClass heroClass, EquipmentSlot slot) {
    return switch (slot) {
      EquipmentSlot.head => const [0, 0, 4, 8, 20, 0],
      EquipmentSlot.body => const [0, 0, 28, 18, 0, 0],
      EquipmentSlot.legs => const [0, 0, 16, 8, 0, 14],
      EquipmentSlot.feet => const [0, 0, 2, 0, 12, 28],
      EquipmentSlot.weapon =>
        heroClass == HeroClass.mage
            ? const [0, 45, 0, 0, 12, 0]
            : const [45, 0, 0, 0, 12, 0],
      EquipmentSlot.offhand => switch (heroClass) {
        HeroClass.knight => const [4, 0, 38, 12, 0, 0],
        HeroClass.assassin => const [18, 0, 0, 0, 12, 24],
        HeroClass.mage => const [0, 30, 4, 8, 14, 0],
        HeroClass.archer => const [8, 0, 0, 0, 30, 14],
      },
    };
  }

  static EquipmentVisuals _visualsFor(EquipmentRarity rarity) {
    return EquipmentVisuals(
      borderStyle: rarity.borderStyle,
      auraStyle: rarity.auraStyle,
      borderTier: rarity.tier,
      auraIntensity: rarity.tier == 0
          ? 0
          : (0.12 + (rarity.tier * 0.095)).clamp(0, 1).toDouble(),
      runeDensity: rarity.tier < 2 ? 0 : rarity.tier - 1,
      accentRgb: rarity.accentRgb,
    );
  }

  static String _nameFor(
    HeroClass heroClass,
    EquipmentSlot slot,
    EquipmentMaterial material,
    EquipmentRarity rarity,
  ) {
    final coreName = slot == EquipmentSlot.weapon
        ? _weaponNames[heroClass]![material.tier]
        : '${_slotNames[heroClass]![slot]} ${material.adjective}';
    return '$coreName ${rarity.nameEpithet}';
  }

  static String _descriptionFor(
    HeroClass heroClass,
    EquipmentSlot slot,
    EquipmentMaterial material,
    EquipmentRarity rarity,
  ) {
    final purpose = switch (heroClass) {
      HeroClass.knight =>
        'feito para sustentar a linha quando a noite engole o campo de batalha',
      HeroClass.assassin =>
        'preparado pelos coureiros sombrios para matar sem romper o silêncio',
      HeroClass.mage =>
        'tecido ao redor de sigilos que conduzem poder sem consumir seu portador',
      HeroClass.archer =>
        'equilibrado para caçadas longas sob florestas sem lua',
    };
    return '${slot.displayName} de ${material.displayName.toLowerCase()}, '
        '$purpose. A marca ${rarity.displayName.toLowerCase()} revela sua '
        'força por meio de bordas e auras rúnicas.';
  }

  static const Map<EquipmentSlot, int> _slotBasePower = {
    EquipmentSlot.head: 24,
    EquipmentSlot.body: 46,
    EquipmentSlot.legs: 35,
    EquipmentSlot.feet: 20,
    EquipmentSlot.weapon: 58,
    EquipmentSlot.offhand: 40,
  };

  static const Map<EquipmentSlot, int> _resourceBaseAmount = {
    EquipmentSlot.head: 6,
    EquipmentSlot.body: 12,
    EquipmentSlot.legs: 9,
    EquipmentSlot.feet: 5,
    EquipmentSlot.weapon: 14,
    EquipmentSlot.offhand: 10,
  };

  static const Map<EquipmentSlot, int> _goldBaseAmount = {
    EquipmentSlot.head: 90,
    EquipmentSlot.body: 180,
    EquipmentSlot.legs: 135,
    EquipmentSlot.feet: 75,
    EquipmentSlot.weapon: 240,
    EquipmentSlot.offhand: 155,
  };

  static const Map<EquipmentSlot, int> _craftBaseSeconds = {
    EquipmentSlot.head: 14,
    EquipmentSlot.body: 26,
    EquipmentSlot.legs: 21,
    EquipmentSlot.feet: 12,
    EquipmentSlot.weapon: 32,
    EquipmentSlot.offhand: 24,
  };

  static const Map<HeroClass, List<int>> _classStatWeights = {
    HeroClass.knight: [20, 0, 34, 28, 10, 5],
    HeroClass.assassin: [30, 0, 7, 10, 24, 29],
    HeroClass.mage: [4, 44, 10, 18, 19, 5],
    HeroClass.archer: [29, 2, 8, 13, 33, 15],
  };

  static const Map<HeroClass, Map<EquipmentSlot, String>> _slotNames = {
    HeroClass.knight: {
      EquipmentSlot.head: 'Elmo do Bastião',
      EquipmentSlot.body: 'Armadura do Juramento',
      EquipmentSlot.legs: 'Grevas da Fortaleza',
      EquipmentSlot.feet: 'Botas da Marcha',
      EquipmentSlot.weapon: 'Espada',
      EquipmentSlot.offhand: 'Escudo do Guardião',
    },
    HeroClass.assassin: {
      EquipmentSlot.head: 'Capuz do Véu',
      EquipmentSlot.body: 'Gibão Sombrio',
      EquipmentSlot.legs: 'Perneiras do Silêncio',
      EquipmentSlot.feet: 'Botas do Passo Morto',
      EquipmentSlot.weapon: 'Lâminas Gêmeas',
      EquipmentSlot.offhand: 'Relicário do Véu',
    },
    HeroClass.mage: {
      EquipmentSlot.head: 'Coroa dos Sigilos',
      EquipmentSlot.body: 'Manto do Conjurador',
      EquipmentSlot.legs: 'Vestes do Círculo',
      EquipmentSlot.feet: 'Sandálias do Éter',
      EquipmentSlot.weapon: 'Cajado',
      EquipmentSlot.offhand: 'Grimório Rúnico',
    },
    HeroClass.archer: {
      EquipmentSlot.head: 'Capuz da Vigília',
      EquipmentSlot.body: 'Couraça do Ermo',
      EquipmentSlot.legs: 'Perneiras do Batedor',
      EquipmentSlot.feet: 'Botas do Rastro',
      EquipmentSlot.weapon: 'Arco',
      EquipmentSlot.offhand: 'Aljava e Flechas do Caçador',
    },
  };

  static const Map<HeroClass, List<String>> _weaponNames = {
    HeroClass.knight: [
      'Espada do Primeiro Cobre',
      'Espada da Guarda de Ferro',
      'Clarão da Lua de Prata',
      'Espada do Rei Dourado',
      'Lâmina da Torre de Platina',
      'Juramento de Mitril',
      'Rompedora de Adamantita',
      'Gume das Nove Runas',
      'Espada do Trono de Oricalco',
      'Lâmina do Firmamento Arcano',
    ],
    HeroClass.assassin: [
      'Presas Gêmeas de Cobre',
      'Lâminas do Sussurro de Ferro',
      'Gêmeas da Lua de Prata',
      'Lâminas do Sangue Dourado',
      'Presas Pálidas de Platina',
      'Gêmeas do Vento de Mitril',
      'Lâminas da Queda de Adamantita',
      'Presas do Véu Rúnico',
      'Gêmeas do Silêncio de Oricalco',
      'Lâminas da Noite Arcana',
    ],
    HeroClass.mage: [
      'Cajado da Faísca de Cobre',
      'Cajado do Círculo de Ferro',
      'Cajado da Lua de Prata',
      'Cajado do Sol Sepulto',
      'Cajado do Astro de Platina',
      'Cajado dos Ventos de Mitril',
      'Cajado da Vontade Adamantina',
      'Cajado das Runas Eternas',
      'Cajado do Oráculo de Oricalco',
      'Cajado do Coração Arcano',
    ],
    HeroClass.archer: [
      'Arco do Galho de Cobre',
      'Arco da Sentinela de Ferro',
      'Arco da Lua de Prata',
      'Arco do Alvorecer Dourado',
      'Arco do Falcão de Platina',
      'Arco do Vendaval de Mitril',
      'Arco do Cerco de Adamantita',
      'Arco das Runas Sussurrantes',
      'Arco do Ermo de Oricalco',
      'Arco da Constelação Arcana',
    ],
  };
}
