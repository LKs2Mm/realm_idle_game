import 'dart:collection';

import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';

enum HeroClass { knight, assassin, mage, archer }

extension HeroClassDetails on HeroClass {
  String get saveKey => name;

  String get displayName => switch (this) {
    HeroClass.knight => 'Cavaleiro',
    HeroClass.assassin => 'Assassino',
    HeroClass.mage => 'Mago',
    HeroClass.archer => 'Arqueiro',
  };

  EquipmentWorkshop get workshop => switch (this) {
    HeroClass.knight => EquipmentWorkshop.blacksmith,
    HeroClass.assassin => EquipmentWorkshop.veilGuild,
    HeroClass.mage => EquipmentWorkshop.arcanist,
    HeroClass.archer => EquipmentWorkshop.artisan,
  };
}

enum EquipmentSlot { head, body, legs, feet, weapon, offhand }

extension EquipmentSlotDetails on EquipmentSlot {
  String get saveKey => name;

  String get displayName => switch (this) {
    EquipmentSlot.head => 'Cabeça',
    EquipmentSlot.body => 'Torso',
    EquipmentSlot.legs => 'Pernas',
    EquipmentSlot.feet => 'Pés',
    EquipmentSlot.weapon => 'Arma',
    EquipmentSlot.offhand => 'Mão secundária',
  };
}

enum EquipmentWorkshop { blacksmith, veilGuild, arcanist, artisan }

extension EquipmentWorkshopDetails on EquipmentWorkshop {
  String get saveKey => switch (this) {
    EquipmentWorkshop.blacksmith => 'blacksmith',
    EquipmentWorkshop.veilGuild => 'veil_guild',
    EquipmentWorkshop.arcanist => 'arcanist',
    EquipmentWorkshop.artisan => 'artisan',
  };

  String get skillId => switch (this) {
    EquipmentWorkshop.blacksmith => 'smithing',
    EquipmentWorkshop.veilGuild => 'shadowcraft',
    EquipmentWorkshop.arcanist => 'arcanism',
    EquipmentWorkshop.artisan => 'crafting',
  };

  String get displayName => switch (this) {
    EquipmentWorkshop.blacksmith => 'Ferreiro',
    EquipmentWorkshop.veilGuild => 'Guilda dos Véus',
    EquipmentWorkshop.arcanist => 'Arcanista',
    EquipmentWorkshop.artisan => 'Artesão',
  };

  String get description => switch (this) {
    EquipmentWorkshop.blacksmith =>
      'A forja onde juramentos são selados em metal e fogo.',
    EquipmentWorkshop.veilGuild =>
      'Coureiro sombrio e armeiros secretos servem aos que andam no véu.',
    EquipmentWorkshop.arcanist =>
      'Um santuário de runas para tecer metal, tecido e poder arcano.',
    EquipmentWorkshop.artisan =>
      'Bancadas de madeira negra para arcos, aljavas e armaduras leves.',
  };
}

enum EquipmentMaterial {
  copper,
  iron,
  silver,
  gold,
  platinum,
  mithril,
  adamantite,
  runite,
  orichalcum,
  arcaneCrystal,
}

extension EquipmentMaterialDetails on EquipmentMaterial {
  int get tier => index;

  /// Identificador do minério bruto. Também permanece nos IDs dos
  /// equipamentos para que saves antigos continuem estáveis.
  String get resourceId => switch (this) {
    EquipmentMaterial.arcaneCrystal => 'arcane_crystal',
    _ => name,
  };

  String get oreResourceId => resourceId;

  /// Material refinado consumido por equipamentos e ferramentas.
  String get barResourceId => switch (this) {
    EquipmentMaterial.arcaneCrystal => 'arcane_ingot',
    _ => '${resourceId}_bar',
  };

  String get displayName => switch (this) {
    EquipmentMaterial.copper => 'Cobre',
    EquipmentMaterial.iron => 'Ferro',
    EquipmentMaterial.silver => 'Prata',
    EquipmentMaterial.gold => 'Ouro',
    EquipmentMaterial.platinum => 'Platina',
    EquipmentMaterial.mithril => 'Mitril',
    EquipmentMaterial.adamantite => 'Adamantita',
    EquipmentMaterial.runite => 'Runita',
    EquipmentMaterial.orichalcum => 'Oricalco',
    EquipmentMaterial.arcaneCrystal => 'Cristal Arcano',
  };

  String get adjective => switch (this) {
    EquipmentMaterial.copper => 'de Cobre',
    EquipmentMaterial.iron => 'de Ferro',
    EquipmentMaterial.silver => 'de Prata',
    EquipmentMaterial.gold => 'Dourado',
    EquipmentMaterial.platinum => 'de Platina',
    EquipmentMaterial.mithril => 'de Mitril',
    EquipmentMaterial.adamantite => 'de Adamantita',
    EquipmentMaterial.runite => 'de Runita',
    EquipmentMaterial.orichalcum => 'de Oricalco',
    EquipmentMaterial.arcaneCrystal => 'de Cristal Arcano',
  };

  GatheringResource get resource {
    final result = GatheringResource.byId(resourceId);
    if (result == null || result.discipline != GatheringDiscipline.mining) {
      throw StateError('Material de equipamento inválido: $resourceId');
    }
    return result;
  }

  /// Madeira usada para talhar a haste que acompanha arcos, aljavas e
  /// cajados mágicos nesse tier de material. Ver `ShaftRecipeCatalog`.
  String get shaftWoodId => switch (this) {
    EquipmentMaterial.copper => 'normal_log',
    EquipmentMaterial.iron => 'oak_log',
    EquipmentMaterial.silver => 'willow_log',
    EquipmentMaterial.gold => 'maple_log',
    EquipmentMaterial.platinum => 'mahogany_log',
    EquipmentMaterial.mithril => 'yew_log',
    EquipmentMaterial.adamantite => 'magic_log',
    EquipmentMaterial.runite => 'magic_log',
    EquipmentMaterial.orichalcum => 'ancient_log',
    EquipmentMaterial.arcaneCrystal => 'ancient_log',
  };

  String get shaftResourceId => '${shaftWoodId}_shaft';

  /// Cor usada para tingir programaticamente as 24 ilustrações-base de
  /// equipamento (uma por classe × slot, superfície neutra cinza-aço) via
  /// `BlendMode.modulate`, evitando precisar de arte por material. Ver
  /// `EquipmentRarityDetails.accentRgb` para o padrão equivalente de
  /// raridade.
  int get tintRgb => switch (this) {
    EquipmentMaterial.copper => 0xC17A4A,
    EquipmentMaterial.iron => 0x8C96A6,
    EquipmentMaterial.silver => 0xC9D0D8,
    EquipmentMaterial.gold => 0xD4AF37,
    EquipmentMaterial.platinum => 0xE5E4E2,
    EquipmentMaterial.mithril => 0x6FC3D0,
    EquipmentMaterial.adamantite => 0x3E4A5C,
    EquipmentMaterial.runite => 0x2E8B77,
    EquipmentMaterial.orichalcum => 0xC97A3D,
    EquipmentMaterial.arcaneCrystal => 0x9B6FD1,
  };
}

enum EquipmentRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythical,
  runic,
  cursed,
  voidborn,
  abyssal,
}

extension EquipmentRarityDetails on EquipmentRarity {
  int get tier => index;
  String get saveKey => name;

  String get displayName => switch (this) {
    EquipmentRarity.common => 'Comum',
    EquipmentRarity.uncommon => 'Incomum',
    EquipmentRarity.rare => 'Raro',
    EquipmentRarity.epic => 'Épico',
    EquipmentRarity.legendary => 'Lendário',
    EquipmentRarity.mythical => 'Mítico',
    EquipmentRarity.runic => 'Rúnico',
    EquipmentRarity.cursed => 'Amaldiçoado',
    EquipmentRarity.voidborn => 'Nascido do Vazio',
    EquipmentRarity.abyssal => 'Abissal',
  };

  String get nameEpithet => switch (this) {
    EquipmentRarity.common => 'do Aprendiz',
    EquipmentRarity.uncommon => 'da Vigília',
    EquipmentRarity.rare => 'do Sangue Antigo',
    EquipmentRarity.epic => 'do Crepúsculo',
    EquipmentRarity.legendary => 'da Coroa Perdida',
    EquipmentRarity.mythical => 'dos Deuses Mortos',
    EquipmentRarity.runic => 'das Runas Eternas',
    EquipmentRarity.cursed => 'da Maldição',
    EquipmentRarity.voidborn => 'do Vazio',
    EquipmentRarity.abyssal => 'do Abismo',
  };

  EquipmentBorderStyle get borderStyle => EquipmentBorderStyle.values[tier];

  EquipmentAuraStyle get auraStyle => switch (this) {
    EquipmentRarity.common => EquipmentAuraStyle.none,
    EquipmentRarity.uncommon => EquipmentAuraStyle.faint,
    EquipmentRarity.rare => EquipmentAuraStyle.ember,
    EquipmentRarity.epic => EquipmentAuraStyle.spectral,
    EquipmentRarity.legendary => EquipmentAuraStyle.golden,
    EquipmentRarity.mythical => EquipmentAuraStyle.arcane,
    EquipmentRarity.runic => EquipmentAuraStyle.runic,
    EquipmentRarity.cursed => EquipmentAuraStyle.cursed,
    EquipmentRarity.voidborn => EquipmentAuraStyle.voidMist,
    EquipmentRarity.abyssal => EquipmentAuraStyle.abyssalFlame,
  };

  int get accentRgb => switch (this) {
    EquipmentRarity.common => 0x7B746A,
    EquipmentRarity.uncommon => 0x557A4B,
    EquipmentRarity.rare => 0x497BA8,
    EquipmentRarity.epic => 0x7650A8,
    EquipmentRarity.legendary => 0xC49A3A,
    EquipmentRarity.mythical => 0xB34F52,
    EquipmentRarity.runic => 0x27A6A1,
    EquipmentRarity.cursed => 0x743046,
    EquipmentRarity.voidborn => 0x413469,
    EquipmentRarity.abyssal => 0xA4212B,
  };
}

enum EquipmentBorderStyle {
  weathered,
  ironbound,
  silverEtched,
  gilded,
  relic,
  starforged,
  runeBound,
  cursedThorns,
  voidMarked,
  abyssalCrown,
}

enum EquipmentAuraStyle {
  none,
  faint,
  ember,
  spectral,
  golden,
  arcane,
  runic,
  cursed,
  voidMist,
  abyssalFlame,
}

class EquipmentVisuals {
  final EquipmentBorderStyle borderStyle;
  final EquipmentAuraStyle auraStyle;
  final int borderTier;
  final double auraIntensity;
  final int runeDensity;
  final int accentRgb;

  const EquipmentVisuals({
    required this.borderStyle,
    required this.auraStyle,
    required this.borderTier,
    required this.auraIntensity,
    required this.runeDensity,
    required this.accentRgb,
  });
}

class EquipmentCost {
  final int gold;
  final Map<String, int> resources;

  EquipmentCost({required int gold, required Map<String, int> resources})
    : gold = gold < 0 ? 0 : gold,
      resources = UnmodifiableMapView(_positiveEntries(resources));

  bool get isFree => gold == 0 && resources.isEmpty;

  bool canAfford({
    required int availableGold,
    required Map<String, int> availableResources,
  }) {
    if (availableGold < gold) return false;
    return resources.entries.every(
      (entry) => (availableResources[entry.key] ?? 0) >= entry.value,
    );
  }
}

class EquipmentStats {
  final int physicalPower;
  final int arcanePower;
  final int defense;
  final int vitality;
  final int precision;
  final int evasion;

  const EquipmentStats({
    required this.physicalPower,
    required this.arcanePower,
    required this.defense,
    required this.vitality,
    required this.precision,
    required this.evasion,
  });

  int get powerScore =>
      physicalPower + arcanePower + defense + vitality + precision + evasion;
}

class EquipmentDefinition {
  final String id;
  final String name;
  final String description;
  final HeroClass heroClass;
  final EquipmentSlot slot;
  final EquipmentMaterial material;
  final EquipmentRarity rarity;
  final EquipmentWorkshop workshop;
  final EquipmentCost cost;
  final int requiredWorkshopLevel;
  final int craftDurationSeconds;
  final double workshopExperience;
  final EquipmentStats stats;
  final EquipmentVisuals visuals;

  const EquipmentDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.heroClass,
    required this.slot,
    required this.material,
    required this.rarity,
    required this.workshop,
    required this.cost,
    required this.requiredWorkshopLevel,
    required this.craftDurationSeconds,
    required this.workshopExperience,
    required this.stats,
    required this.visuals,
  });
}

enum EquipmentActionResult { success, itemNotOwned, slotAlreadyEmpty }

class EquipmentInventory {
  final Map<String, int> items;

  EquipmentInventory({Map<String, int> items = const {}})
    : items = UnmodifiableMapView(_positiveEntries(items));

  int itemQuantity(String equipmentId) => items[equipmentId] ?? 0;

  Map<String, dynamic> toJson() => {'items': Map<String, int>.from(items)};

  factory EquipmentInventory.fromJson(Object? json) {
    if (json is! Map) return EquipmentInventory();
    return EquipmentInventory(items: _intMap(json['items']));
  }

  EquipmentInventory _withAdded(String equipmentId, int quantity) {
    final updatedItems = Map<String, int>.from(items);
    updatedItems[equipmentId] = itemQuantity(equipmentId) + quantity;
    return EquipmentInventory(items: updatedItems);
  }
}

class EquipmentLoadouts {
  final Map<HeroClass, Map<EquipmentSlot, String>> equipped;

  EquipmentLoadouts({
    Map<HeroClass, Map<EquipmentSlot, String>> equipped = const {},
  }) : equipped = UnmodifiableMapView(
         equipped.map(
           (heroClass, slots) => MapEntry(
             heroClass,
             UnmodifiableMapView(Map<EquipmentSlot, String>.from(slots)),
           ),
         ),
       );

  String? equippedId(HeroClass heroClass, EquipmentSlot slot) {
    return equipped[heroClass]?[slot];
  }

  EquipmentLoadouts withEquipped(EquipmentDefinition definition) {
    final updated = _mutableCopy();
    updated.putIfAbsent(definition.heroClass, () => {})[definition.slot] =
        definition.id;
    return EquipmentLoadouts(equipped: updated);
  }

  EquipmentLoadouts without(HeroClass heroClass, EquipmentSlot slot) {
    final updated = _mutableCopy();
    final slots = updated[heroClass];
    slots?.remove(slot);
    if (slots != null && slots.isEmpty) updated.remove(heroClass);
    return EquipmentLoadouts(equipped: updated);
  }

  Map<String, dynamic> toJson() => equipped.map(
    (heroClass, slots) => MapEntry(
      heroClass.saveKey,
      slots.map((slot, id) => MapEntry(slot.saveKey, id)),
    ),
  );

  factory EquipmentLoadouts.fromJson(Object? json) {
    if (json is! Map) return EquipmentLoadouts();
    final parsed = <HeroClass, Map<EquipmentSlot, String>>{};
    for (final heroClass in HeroClass.values) {
      final rawSlots = json[heroClass.saveKey];
      if (rawSlots is! Map) continue;
      final slots = <EquipmentSlot, String>{};
      for (final slot in EquipmentSlot.values) {
        final id = rawSlots[slot.saveKey];
        if (id is String && id.isNotEmpty) slots[slot] = id;
      }
      if (slots.isNotEmpty) parsed[heroClass] = slots;
    }
    return EquipmentLoadouts(equipped: parsed);
  }

  EquipmentLoadouts retainingOwned(Set<String> ownedIds) {
    final retained = <HeroClass, Map<EquipmentSlot, String>>{};
    for (final classEntry in equipped.entries) {
      final slots = <EquipmentSlot, String>{};
      for (final slotEntry in classEntry.value.entries) {
        if (ownedIds.contains(slotEntry.value)) {
          slots[slotEntry.key] = slotEntry.value;
        }
      }
      if (slots.isNotEmpty) retained[classEntry.key] = slots;
    }
    return EquipmentLoadouts(equipped: retained);
  }

  Map<HeroClass, Map<EquipmentSlot, String>> _mutableCopy() => equipped.map(
    (heroClass, slots) =>
        MapEntry(heroClass, Map<EquipmentSlot, String>.from(slots)),
  );
}

class EquipmentState {
  final EquipmentInventory inventory;
  final EquipmentLoadouts loadouts;

  EquipmentState({EquipmentInventory? inventory, EquipmentLoadouts? loadouts})
    : inventory = inventory ?? EquipmentInventory(),
      loadouts = loadouts ?? EquipmentLoadouts();

  /// Adds the result of a completed production cycle without duplicating
  /// currencies or gathering resources owned by the surrounding game state.
  EquipmentState grant(String equipmentId, {int quantity = 1}) {
    if (equipmentId.isEmpty || quantity <= 0) return this;
    return EquipmentState(
      inventory: inventory._withAdded(equipmentId, quantity),
      loadouts: loadouts,
    );
  }

  EquipmentState grantDefinition(
    EquipmentDefinition definition, {
    int quantity = 1,
  }) {
    return grant(definition.id, quantity: quantity);
  }

  EquipmentOperation equip(EquipmentDefinition definition) {
    if (inventory.itemQuantity(definition.id) <= 0) {
      return EquipmentOperation(
        result: EquipmentActionResult.itemNotOwned,
        state: this,
      );
    }
    return EquipmentOperation(
      result: EquipmentActionResult.success,
      state: EquipmentState(
        inventory: inventory,
        loadouts: loadouts.withEquipped(definition),
      ),
    );
  }

  EquipmentOperation unequip(HeroClass heroClass, EquipmentSlot slot) {
    if (loadouts.equippedId(heroClass, slot) == null) {
      return EquipmentOperation(
        result: EquipmentActionResult.slotAlreadyEmpty,
        state: this,
      );
    }
    return EquipmentOperation(
      result: EquipmentActionResult.success,
      state: EquipmentState(
        inventory: inventory,
        loadouts: loadouts.without(heroClass, slot),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'inventory': inventory.toJson(),
    'loadouts': loadouts.toJson(),
  };

  factory EquipmentState.fromJson(Object? json) {
    if (json is! Map) return EquipmentState();
    final inventory = EquipmentInventory.fromJson(json['inventory']);
    final loadouts = EquipmentLoadouts.fromJson(
      json['loadouts'],
    ).retainingOwned(inventory.items.keys.toSet());
    return EquipmentState(inventory: inventory, loadouts: loadouts);
  }
}

class EquipmentOperation {
  final EquipmentActionResult result;
  final EquipmentState state;

  const EquipmentOperation({required this.result, required this.state});

  bool get succeeded => result == EquipmentActionResult.success;
}

Map<String, int> _positiveEntries(Map<String, int> source) {
  final result = <String, int>{};
  for (final entry in source.entries) {
    if (entry.key.isNotEmpty && entry.value > 0) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

Map<String, int> _intMap(Object? json) {
  if (json is! Map) return const {};
  final result = <String, int>{};
  for (final entry in json.entries) {
    if (entry.key is! String || entry.key.isEmpty) continue;
    final value = entry.value;
    if (value is num && value.isFinite && value > 0) {
      result[entry.key as String] = value.toInt();
    }
  }
  return result;
}
