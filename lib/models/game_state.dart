import 'package:realm_idle_game/features/combat/models/combat_encounter.dart';
import 'package:realm_idle_game/features/combat/models/combat_session.dart';
import 'package:realm_idle_game/features/content/data/combat_drop_catalog.dart';
import 'package:realm_idle_game/features/content/data/potion_catalog.dart';
import 'package:realm_idle_game/features/content/data/spell_catalog.dart';
import 'package:realm_idle_game/features/content/data/world_region_catalog.dart';
import 'package:realm_idle_game/features/content/models/active_buffs.dart';
import 'package:realm_idle_game/features/content/models/alchemy.dart';
import 'package:realm_idle_game/features/content/models/content_inventory.dart';
import 'package:realm_idle_game/features/content/models/spell.dart';
import 'package:realm_idle_game/features/content/models/world_region.dart';
import 'package:realm_idle_game/features/equipment/data/equipment_catalog.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_inventory.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_session.dart';
import 'package:realm_idle_game/features/processing/data/cooking_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/processing_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/models/processing_recipe.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/features/profile/models/player_profile.dart';
import 'package:realm_idle_game/features/tools/data/tool_catalog.dart';
import 'package:realm_idle_game/features/tools/models/tool_models.dart';
import 'package:realm_idle_game/models/audio_settings.dart';
import 'package:realm_idle_game/models/auto_eat_settings.dart';
import 'package:realm_idle_game/models/notification_settings.dart';
import 'package:realm_idle_game/models/skill.dart';

class GatheringReward {
  final String resourceId;
  final String skillId;
  final int cycles;
  final int quantity;
  final double experience;

  const GatheringReward({
    required this.resourceId,
    required this.skillId,
    required this.cycles,
    required this.quantity,
    required this.experience,
  });
}

enum FoodUseResult { success, unknownFood, notOwned, fullHealth }

class GameState {
  static const int schemaVersion = 7;
  static const int _xpBalanceSchemaVersion = 3;
  static const int _toolSystemSchemaVersion = 4;

  int gold = 0;
  int totalLevel = 1;
  int currentHealth = 100;
  late Map<String, Skill> skills;
  late GatheringInventory gatheringInventory;
  late ToolCollection tools;
  late EquipmentState equipment;
  late ContentInventory contentInventory;
  late ActiveBuffs activeBuffs;
  late PlayerProfile profile;
  AudioSettings audioSettings = AudioSettings();
  NotificationSettings notificationSettings = NotificationSettings();
  AutoEatSettings autoEatSettings = AutoEatSettings();
  bool hasSeenOnboarding = false;
  HeroClass activeHeroClass = HeroClass.knight;
  String? activeSpellId;
  final Map<HeroClass, int> classVictories = {
    for (final heroClass in HeroClass.values) heroClass: 0,
  };
  final Set<String> visitedRegionIds = {'ashen_crossroads'};
  final Map<String, double> gatheringYieldRemainders = {};
  final Map<String, double> combatDropRemainders = {};
  GatheringSession? activeGatheringSession;
  CombatSession? activeCombatSession;
  ProductionSession? activeProductionSession;

  GameState() {
    _initializeSkills();
    gatheringInventory = GatheringInventory();
    _initializeTools();
    equipment = EquipmentState();
    contentInventory = ContentInventory();
    activeBuffs = ActiveBuffs();
    profile = PlayerProfile(selectedRegionId: 'ashen_crossroads');
    updateTotalLevel();
  }

  void _initializeTools() {
    final owned = <String, OwnedTool>{};
    final equipped = <GatheringDiscipline, String>{};
    for (final discipline in GatheringDiscipline.values) {
      final starter = ToolCatalog.starterFor(discipline);
      owned[starter.id] = OwnedTool(toolId: starter.id);
      equipped[discipline] = starter.id;
    }
    tools = ToolCollection(ownedById: owned, equippedByDiscipline: equipped);
  }

  void _initializeSkills() {
    skills = {
      'mining': Skill(
        id: 'mining',
        name: 'Mineração',
        category: SkillCategory.gathering,
      ),
      'woodcutting': Skill(
        id: 'woodcutting',
        name: 'Corte de madeira',
        category: SkillCategory.gathering,
      ),
      'fishing': Skill(
        id: 'fishing',
        name: 'Pesca',
        category: SkillCategory.gathering,
      ),
      'smithing': Skill(
        id: 'smithing',
        name: 'Forja',
        category: SkillCategory.processing,
      ),
      'crafting': Skill(
        id: 'crafting',
        name: 'Artesanato',
        category: SkillCategory.processing,
      ),
      'shadowcraft': Skill(
        id: 'shadowcraft',
        name: 'Ofício do Véu',
        category: SkillCategory.processing,
      ),
      'arcanism': Skill(
        id: 'arcanism',
        name: 'Arcanismo',
        category: SkillCategory.processing,
      ),
      'alchemy': Skill(
        id: 'alchemy',
        name: 'Alquimia',
        category: SkillCategory.processing,
      ),
      'cooking': Skill(
        id: 'cooking',
        name: 'Culinária',
        category: SkillCategory.processing,
      ),
      'attack': Skill(
        id: 'attack',
        name: 'Ataque',
        category: SkillCategory.combat,
      ),
      'defense': Skill(
        id: 'defense',
        name: 'Defesa',
        category: SkillCategory.combat,
      ),
      'magic': Skill(
        id: 'magic',
        name: 'Magia',
        category: SkillCategory.combat,
      ),
      'knight_mastery': Skill(
        id: 'knight_mastery',
        name: 'Cavaleiro',
        category: SkillCategory.combat,
      ),
      'assassin_mastery': Skill(
        id: 'assassin_mastery',
        name: 'Assassino',
        category: SkillCategory.combat,
      ),
      'mage_mastery': Skill(
        id: 'mage_mastery',
        name: 'Mago',
        category: SkillCategory.combat,
      ),
      'archer_mastery': Skill(
        id: 'archer_mastery',
        name: 'Arqueiro',
        category: SkillCategory.combat,
      ),
    };
  }

  void addGold(int amount) {
    if (amount > 0) gold += amount;
  }

  int get combatLevel => skills['attack']?.level ?? 1;

  int get maxHealth {
    final masteryHealth = (classLevel(activeHeroClass) - 1) * 2;
    final equipmentHealth = equippedDefinitionsFor(
      activeHeroClass,
    ).fold<int>(0, (sum, definition) => sum + definition.stats.vitality);
    return 100 + masteryHealth + equipmentHealth;
  }

  bool get isDefeated => currentHealth <= 0;

  int classLevel(HeroClass heroClass) {
    return skills[_classSkillId(heroClass)]?.level ?? 1;
  }

  int victoriesForClass(HeroClass heroClass) => classVictories[heroClass] ?? 0;

  void selectHeroClass(HeroClass heroClass, {DateTime? at}) {
    if (activeHeroClass == heroClass) return;
    final previousMaxHealth = maxHealth;
    activeHeroClass = heroClass;
    _preserveHealthRatio(previousMaxHealth);

    final session = activeCombatSession;
    final encounter = session == null
        ? null
        : CombatEncounter.byId(session.encounterId);
    if (session == null || encounter == null) return;

    final timestamp = at ?? DateTime.now();
    final previousDuration = session.cycleDurationMilliseconds;
    final elapsedRatio = previousDuration <= 0
        ? 0.0
        : 1 - (session.timeRemainingMilliseconds / previousDuration);
    final nextDuration = combatCycleDurationMilliseconds(
      encounter,
      at: timestamp,
    );
    activeCombatSession = CombatSession(
      encounterId: encounter.id,
      cycleDurationMilliseconds: nextDuration,
      timeRemainingMilliseconds: (nextDuration * (1 - elapsedRatio))
          .ceil()
          .clamp(1, nextDuration),
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
      queuedEncounterId: session.queuedEncounterId,
    );
  }

  Iterable<EquipmentDefinition> equippedDefinitionsFor(
    HeroClass heroClass,
  ) sync* {
    final equippedIds = equipment.loadouts.equipped[heroClass]?.values;
    if (equippedIds == null) return;
    for (final id in equippedIds) {
      final definition = EquipmentCatalog.byId(id);
      if (definition != null) yield definition;
    }
  }

  int equipmentPowerFor(HeroClass heroClass) {
    return equippedDefinitionsFor(
      heroClass,
    ).fold(0, (sum, definition) => sum + definition.stats.powerScore);
  }

  EquipmentActionResult equipItem(String equipmentId) {
    final definition = EquipmentCatalog.byId(equipmentId);
    if (definition == null) return EquipmentActionResult.itemNotOwned;
    final previousMaxHealth = maxHealth;
    final operation = equipment.equip(definition);
    equipment = operation.state;
    _preserveHealthRatio(previousMaxHealth);
    return operation.result;
  }

  EquipmentActionResult unequipItem(HeroClass heroClass, EquipmentSlot slot) {
    final previousMaxHealth = maxHealth;
    final operation = equipment.unequip(heroClass, slot);
    equipment = operation.state;
    _preserveHealthRatio(previousMaxHealth);
    return operation.result;
  }

  bool equipSpell(String spellId) {
    if (contentInventory.quantityOfSpell(spellId) <= 0 ||
        SpellCatalog.byId(spellId) == null) {
      return false;
    }
    activeSpellId = spellId;
    return true;
  }

  void unequipSpell() {
    activeSpellId = null;
  }

  SpellDefinition? get activeSpell {
    final id = activeSpellId;
    if (id == null || contentInventory.quantityOfSpell(id) <= 0) return null;
    return SpellCatalog.byId(id);
  }

  String get selectedRegionName {
    return WorldRegionCatalog.byId(profile.selectedRegionId)?.name ??
        WorldRegionCatalog.all.first.name;
  }

  Map<String, int> get skillLevels => {
    for (final entry in skills.entries) entry.key: entry.value.level,
  };

  bool canEnterRegion(WorldRegion region) {
    return region.requirement.isMet(
      combatLevel: combatLevel,
      skillLevels: skillLevels,
      completedRegionIds: visitedRegionIds,
    );
  }

  bool selectRegion(String regionId) {
    final region = WorldRegionCatalog.byId(regionId);
    if (region == null || !canEnterRegion(region)) return false;
    profile.selectedRegionId = region.id;
    visitedRegionIds.add(region.id);
    return true;
  }

  double buffMultiplier(BuffType type, {DateTime? at}) {
    return activeBuffs.multiplierFor(type, at ?? DateTime.now());
  }

  int combatCycleDurationMilliseconds(
    CombatEncounter encounter, {
    DateTime? at,
  }) {
    final timestamp = at ?? DateTime.now();
    final gearBonus = (equipmentPowerFor(activeHeroClass) / 5000).clamp(
      0.0,
      0.5,
    );
    final attackBonus = buffMultiplier(BuffType.attackPower, at: timestamp) - 1;
    final defenseBonus = buffMultiplier(BuffType.defense, at: timestamp) - 1;
    final speedBonus = buffMultiplier(BuffType.combatSpeed, at: timestamp);
    final spellBonus = 1 + _activeSpellCombatSpeedBonus();
    final efficiency =
        speedBonus *
        (1 + (attackBonus * 0.65)) *
        (1 + (defenseBonus * 0.25)) *
        (1 + gearBonus) *
        spellBonus;
    return (encounter.cycleDurationMilliseconds / efficiency).ceil().clamp(
      250,
      86400000,
    );
  }

  bool canFight(CombatEncounter encounter) {
    return combatLevel >= encounter.requiredAttackLevel;
  }

  int effectiveDamageFor(CombatEncounter encounter, {DateTime? at}) {
    if (encounter.damagePerVictory <= 0) return 0;
    final equipmentDefense = equippedDefinitionsFor(
      activeHeroClass,
    ).fold<int>(0, (sum, definition) => sum + definition.stats.defense);
    final defenseLevel = skills['defense']?.level ?? 1;
    final defenseRating = equipmentDefense + (defenseLevel * 2);
    final physicalMitigation = (defenseRating / (defenseRating + 150)).clamp(
      0.0,
      0.80,
    );
    final buff = buffMultiplier(BuffType.defense, at: at);
    return (encounter.damagePerVictory * (1 - physicalMitigation) / buff)
        .ceil()
        .clamp(1, encounter.damagePerVictory);
  }

  bool startCombat(String encounterId, {DateTime? at}) {
    final encounter = CombatEncounter.byId(encounterId);
    if (encounter == null || !canFight(encounter) || isDefeated) return false;

    activeGatheringSession = null;
    final timestamp = at ?? DateTime.now();
    final duration = combatCycleDurationMilliseconds(encounter, at: timestamp);
    activeCombatSession = CombatSession(
      encounterId: encounter.id,
      cycleDurationMilliseconds: duration,
      timeRemainingMilliseconds: duration,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
    );
    return true;
  }

  CombatReward? completeCombatVictories(
    String encounterId,
    int victories, {
    DateTime? at,
  }) {
    if (victories <= 0 || isDefeated) return null;
    final encounter = CombatEncounter.byId(encounterId);
    if (encounter == null || !canFight(encounter)) return null;

    final timestamp = at ?? DateTime.now();
    final damagePerVictory = effectiveDamageFor(encounter, at: timestamp);
    final survivableVictories = damagePerVictory <= 0
        ? victories
        : ((currentHealth + damagePerVictory - 1) ~/ damagePerVictory);
    final completedVictories = victories.clamp(0, survivableVictories);
    if (completedVictories <= 0) return null;
    final goldMultiplier = buffMultiplier(BuffType.goldGain, at: timestamp);
    final experienceMultiplier = buffMultiplier(
      BuffType.experienceGain,
      at: timestamp,
    );
    final goldEarned =
        (encounter.goldPerVictory * completedVictories * goldMultiplier)
            .floor();
    final experience = Skill.normalizeExperience(
      encounter.experiencePerVictory *
          completedVictories *
          experienceMultiplier,
    );
    final loot = _rollCombatLoot(encounter.id, completedVictories, timestamp);
    final damageTaken = (damagePerVictory * completedVictories).clamp(
      0,
      currentHealth,
    );
    currentHealth -= damageTaken;
    addGold(goldEarned);
    skills['attack']?.addExperience(experience);
    skills[_classSkillId(activeHeroClass)]?.addExperience(experience);
    if (activeHeroClass == HeroClass.knight) {
      skills['defense']?.addExperience(
        Skill.normalizeExperience(experience * 0.5),
      );
    } else if (activeHeroClass == HeroClass.mage) {
      skills['magic']?.addExperience(
        Skill.normalizeExperience(experience * 0.75),
      );
    }
    classVictories.update(
      activeHeroClass,
      (current) => current + completedVictories,
      ifAbsent: () => completedVictories,
    );
    profile.totalVictories += completedVictories;
    for (final entry in loot.entries) {
      gatheringInventory.add(entry.key, entry.value);
    }
    updateTotalLevel();
    final wasDefeated = isDefeated;
    if (wasDefeated) activeCombatSession = null;

    return CombatReward(
      encounterId: encounter.id,
      victories: completedVictories,
      gold: goldEarned,
      experience: experience,
      loot: loot,
      damageTaken: damageTaken,
      wasDefeated: wasDefeated,
    );
  }

  void stopCombat() {
    activeCombatSession = null;
  }

  void _preserveHealthRatio(int previousMaxHealth) {
    if (currentHealth <= 0) {
      currentHealth = 0;
      return;
    }
    if (previousMaxHealth <= 0) {
      currentHealth = maxHealth;
      return;
    }
    final ratio = currentHealth / previousMaxHealth;
    currentHealth = (maxHealth * ratio).round().clamp(1, maxHealth);
  }

  void updateTotalLevel() {
    totalLevel = skills.values.fold(0, (sum, skill) => sum + skill.level);
  }

  int skillLevelFor(GatheringDiscipline discipline) {
    return skills[discipline.skillId]?.level ?? 1;
  }

  bool canGather(GatheringResource resource) {
    return skillLevelFor(resource.discipline) >= resource.requiredLevel;
  }

  ToolDefinition equippedToolDefinition(GatheringDiscipline discipline) {
    final equippedId = tools.equippedId(discipline);
    final definition = equippedId == null ? null : ToolCatalog.byId(equippedId);
    if (definition != null &&
        definition.discipline == discipline &&
        tools.ownedById.containsKey(definition.id)) {
      return definition;
    }
    return ToolCatalog.starterFor(discipline);
  }

  OwnedTool? ownedTool(String toolId) => tools.ownedTool(toolId);

  double gatheringSpeedMultiplier(
    GatheringDiscipline discipline, {
    DateTime? at,
  }) {
    final definition = equippedToolDefinition(discipline);
    final owned = tools.ownedTool(definition.id);
    return definition.speedForUpgrade(owned?.upgradeLevel ?? 0) *
        buffMultiplier(BuffType.gatheringSpeed, at: at);
  }

  double gatheringYieldMultiplier(
    GatheringDiscipline discipline, {
    DateTime? at,
  }) {
    final definition = equippedToolDefinition(discipline);
    final owned = tools.ownedTool(definition.id);
    return definition.yieldForUpgrade(owned?.upgradeLevel ?? 0) *
        buffMultiplier(BuffType.gatheringYield, at: at);
  }

  int gatheringCycleDurationMilliseconds(
    GatheringResource resource, {
    DateTime? at,
  }) {
    final duration =
        (resource.cycleSeconds *
                1000 /
                gatheringSpeedMultiplier(resource.discipline, at: at))
            .ceil();
    return duration.clamp(1, 86400000);
  }

  double gatheringYieldPerCycle(GatheringResource resource, {DateTime? at}) {
    return resource.baseQuantity *
        gatheringYieldMultiplier(resource.discipline, at: at);
  }

  bool canAffordToolCost(ToolCost cost) {
    return cost.gold >= 0 &&
        gold >= cost.gold &&
        gatheringInventory.containsAll(cost.resources);
  }

  ToolActionResult acquireTool(String toolId) {
    final definition = ToolCatalog.byId(toolId);
    if (definition == null) return ToolActionResult.unknownTool;
    if (tools.ownedById.containsKey(toolId)) {
      return ToolActionResult.alreadyOwned;
    }
    if (skillLevelFor(definition.discipline) < definition.requiredSkillLevel) {
      return ToolActionResult.skillLevelRequired;
    }
    final payment = _spendToolCost(definition.purchaseCost);
    if (payment != ToolActionResult.success) return payment;
    tools.ownedById[toolId] = OwnedTool(toolId: toolId);
    return ToolActionResult.success;
  }

  ToolActionResult upgradeTool(String toolId) {
    final definition = ToolCatalog.byId(toolId);
    if (definition == null) return ToolActionResult.unknownTool;
    final owned = tools.ownedById[toolId];
    if (owned == null) return ToolActionResult.notOwned;
    final cost = definition.upgradeCostFor(owned.upgradeLevel);
    if (cost == null) return ToolActionResult.maxUpgradeReached;
    final payment = _spendToolCost(cost);
    if (payment != ToolActionResult.success) return payment;
    owned.upgradeLevel++;
    return ToolActionResult.success;
  }

  ToolActionResult equipTool(String toolId) {
    final definition = ToolCatalog.byId(toolId);
    if (definition == null) return ToolActionResult.unknownTool;
    if (!tools.ownedById.containsKey(toolId)) {
      return ToolActionResult.notOwned;
    }
    tools.equippedByDiscipline[definition.discipline] = toolId;
    return ToolActionResult.success;
  }

  ToolActionResult _spendToolCost(ToolCost cost) {
    if (cost.gold < 0 || gold < cost.gold) {
      return ToolActionResult.insufficientGold;
    }
    if (!gatheringInventory.containsAll(cost.resources)) {
      return ToolActionResult.insufficientResources;
    }
    if (!gatheringInventory.trySpend(cost.resources)) {
      return ToolActionResult.insufficientResources;
    }
    gold -= cost.gold;
    return ToolActionResult.success;
  }

  bool startGathering(String resourceId, {DateTime? at}) {
    final resource = GatheringResource.byId(resourceId);
    if (resource == null || !canGather(resource)) return false;

    activeCombatSession = null;
    final timestamp = at ?? DateTime.now();
    final tool = equippedToolDefinition(resource.discipline);
    final duration = gatheringCycleDurationMilliseconds(
      resource,
      at: timestamp,
    );
    activeGatheringSession = GatheringSession(
      resourceId: resource.id,
      cycleDurationMilliseconds: duration,
      timeRemainingMilliseconds: duration,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
      toolId: tool.id,
      yieldMultiplier: gatheringYieldMultiplier(
        resource.discipline,
        at: timestamp,
      ),
    );
    return true;
  }

  GatheringReward? completeGatheringCycles(
    String resourceId,
    int cycles, {
    String? toolId,
    double? yieldMultiplier,
    DateTime? at,
  }) {
    if (cycles <= 0) return null;

    final resource = GatheringResource.byId(resourceId);
    if (resource == null) return null;

    final effectiveYield = _validatedYieldMultiplier(
      resource.discipline,
      toolId: toolId,
      snapshot: yieldMultiplier,
    );
    final remainderKey = resource.discipline.skillId;
    final previousRemainder = gatheringYieldRemainders[remainderKey] ?? 0.0;
    final rawQuantity =
        (resource.baseQuantity * effectiveYield * cycles) + previousRemainder;
    final quantity = rawQuantity.floor();
    gatheringYieldRemainders[remainderKey] = _normalizeYieldRemainder(
      rawQuantity - quantity,
    );
    final experience = Skill.normalizeExperience(
      resource.experiencePerCycle *
          cycles *
          buffMultiplier(BuffType.experienceGain, at: at),
    );
    gatheringInventory.add(resource.id, quantity);
    skills[resource.discipline.skillId]?.addExperience(experience);
    profile.totalGatheringCycles += cycles;
    updateTotalLevel();

    return GatheringReward(
      resourceId: resource.id,
      skillId: resource.discipline.skillId,
      cycles: cycles,
      quantity: quantity,
      experience: experience,
    );
  }

  ProductionStartResult craftEquipment(String equipmentId, {DateTime? at}) {
    final definition = EquipmentCatalog.byId(equipmentId);
    if (definition == null) return ProductionStartResult.unknownRecipe;
    if (activeProductionSession != null) {
      return ProductionStartResult.productionBusy;
    }
    if (equipment.inventory.itemQuantity(equipmentId) > 0) {
      return ProductionStartResult.alreadyOwned;
    }
    final workshopSkill = skills[definition.workshop.skillId];
    if ((workshopSkill?.level ?? 1) < definition.requiredWorkshopLevel) {
      return ProductionStartResult.levelRequired;
    }
    if (gold < definition.cost.gold) {
      return ProductionStartResult.insufficientGold;
    }
    if (!gatheringInventory.containsAll(definition.cost.resources)) {
      return ProductionStartResult.insufficientResources;
    }
    if (!gatheringInventory.trySpend(definition.cost.resources)) {
      return ProductionStartResult.insufficientResources;
    }
    gold -= definition.cost.gold;
    final timestamp = at ?? DateTime.now();
    activeProductionSession = ProductionSession(
      kind: ProductionKind.equipment,
      recipeId: definition.id,
      displayName: definition.name,
      quantity: 1,
      durationMilliseconds: definition.craftDurationSeconds * 1000,
      timeRemainingMilliseconds: definition.craftDurationSeconds * 1000,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
      goldCost: definition.cost.gold,
      resourceCost: definition.cost.resources,
      skillId: definition.workshop.skillId,
      experience: definition.workshopExperience,
    );
    return ProductionStartResult.success;
  }

  ProductionStartResult craftSpell(String spellId, {DateTime? at}) {
    final definition = SpellCatalog.byId(spellId);
    if (definition == null) return ProductionStartResult.unknownRecipe;
    if (activeProductionSession != null) {
      return ProductionStartResult.productionBusy;
    }
    if (contentInventory.quantityOfSpell(spellId) > 0) {
      return ProductionStartResult.alreadyOwned;
    }
    if ((skills['arcanism']?.level ?? 1) < definition.requiredLevel) {
      return ProductionStartResult.levelRequired;
    }
    final cost = definition.cost.materials;
    if (!gatheringInventory.containsAll(cost) ||
        !gatheringInventory.trySpend(cost)) {
      return ProductionStartResult.insufficientResources;
    }
    final timestamp = at ?? DateTime.now();
    activeProductionSession = ProductionSession(
      kind: ProductionKind.spell,
      recipeId: definition.id,
      displayName: definition.name,
      quantity: 1,
      durationMilliseconds: definition.craftDurationMilliseconds,
      timeRemainingMilliseconds: definition.craftDurationMilliseconds,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
      goldCost: 0,
      resourceCost: cost,
      skillId: 'arcanism',
      experience: definition.craftingExperience,
    );
    return ProductionStartResult.success;
  }

  ProductionStartResult brewPotion(
    String potionId, {
    int quantity = 1,
    DateTime? at,
  }) {
    final definition = PotionCatalog.byId(potionId);
    if (definition == null) return ProductionStartResult.unknownRecipe;
    if (quantity <= 0 || quantity > 10) {
      return ProductionStartResult.invalidQuantity;
    }
    if (activeProductionSession != null) {
      return ProductionStartResult.productionBusy;
    }
    if ((skills['alchemy']?.level ?? 1) < definition.requiredLevel) {
      return ProductionStartResult.levelRequired;
    }
    final cost = _scaledCost(definition.cost.materials, quantity);
    if (!gatheringInventory.containsAll(cost) ||
        !gatheringInventory.trySpend(cost)) {
      return ProductionStartResult.insufficientResources;
    }
    final timestamp = at ?? DateTime.now();
    final duration = definition.craftDurationMilliseconds * quantity;
    activeProductionSession = ProductionSession(
      kind: ProductionKind.potion,
      recipeId: definition.id,
      displayName: definition.name,
      quantity: quantity,
      durationMilliseconds: duration,
      timeRemainingMilliseconds: duration,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
      goldCost: 0,
      resourceCost: cost,
      skillId: 'alchemy',
      experience: definition.craftingExperience * quantity,
    );
    return ProductionStartResult.success;
  }

  ProductionStartResult startProcessing(
    String recipeId, {
    int quantity = 1,
    DateTime? at,
    bool repeat = false,
  }) {
    final recipe = ProcessingRecipeCatalog.byId(recipeId);
    if (recipe == null) return ProductionStartResult.unknownRecipe;
    if (quantity <= 0 || quantity > 10) {
      return ProductionStartResult.invalidQuantity;
    }
    if (activeProductionSession != null) {
      return ProductionStartResult.productionBusy;
    }
    if ((skills[recipe.skillId]?.level ?? 1) < recipe.requiredLevel) {
      return ProductionStartResult.levelRequired;
    }
    final cost = recipe.cost.multipliedBy(quantity);
    if (!gatheringInventory.containsAll(cost) ||
        !gatheringInventory.trySpend(cost)) {
      return ProductionStartResult.insufficientResources;
    }

    final timestamp = at ?? DateTime.now();
    final duration = recipe.durationMilliseconds * quantity;
    activeProductionSession = ProductionSession(
      kind: _productionKindFor(recipe.kind),
      recipeId: recipe.id,
      displayName: recipe.name,
      quantity: quantity,
      durationMilliseconds: duration,
      timeRemainingMilliseconds: duration,
      lastProcessedAt: timestamp.millisecondsSinceEpoch,
      goldCost: 0,
      resourceCost: cost,
      skillId: recipe.skillId,
      experience: recipe.experience * quantity,
      repeatWhenDone: repeat,
    );
    return ProductionStartResult.success;
  }

  void cancelProduction({bool refund = true}) {
    final session = activeProductionSession;
    if (session == null) return;
    if (refund) {
      addGold(session.goldCost);
      for (final entry in session.resourceCost.entries) {
        gatheringInventory.add(entry.key, entry.value);
      }
    }
    activeProductionSession = null;
  }

  ProductionReward? completeProduction({DateTime? at}) {
    final session = activeProductionSession;
    if (session == null) return null;
    activeProductionSession = null;

    switch (session.kind) {
      case ProductionKind.equipment:
        if (EquipmentCatalog.byId(session.recipeId) == null) return null;
        equipment = equipment.grant(
          session.recipeId,
          quantity: session.quantity,
        );
        break;
      case ProductionKind.spell:
        if (SpellCatalog.byId(session.recipeId) == null) return null;
        contentInventory.addSpell(session.recipeId, session.quantity);
        break;
      case ProductionKind.potion:
        if (PotionCatalog.byId(session.recipeId) == null) return null;
        contentInventory.addConsumable(session.recipeId, session.quantity);
        break;
      case ProductionKind.smelting:
      case ProductionKind.arcaneRefining:
      case ProductionKind.woodworking:
        final recipe = ProcessingRecipeCatalog.byId(session.recipeId);
        if (recipe == null || _productionKindFor(recipe.kind) != session.kind) {
          return null;
        }
        gatheringInventory.add(
          recipe.output.resourceId,
          recipe.output.forBatches(session.quantity),
        );
        break;
      case ProductionKind.cooking:
        final recipe = ProcessingRecipeCatalog.byId(session.recipeId);
        if (recipe is! CookingRecipe) return null;
        contentInventory.addConsumable(
          recipe.foodId,
          recipe.output.forBatches(session.quantity),
        );
        break;
    }

    final experience = Skill.normalizeExperience(
      session.experience * buffMultiplier(BuffType.experienceGain, at: at),
    );
    skills[session.skillId]?.addExperience(experience);
    profile.totalCrafts += session.quantity;
    updateTotalLevel();
    return ProductionReward(
      kind: session.kind,
      recipeId: session.recipeId,
      quantity: session.quantity,
      skillId: session.skillId,
      experience: experience,
    );
  }

  bool consumePotion(String potionId, {DateTime? at}) {
    final potion = PotionCatalog.byId(potionId);
    if (potion == null || !contentInventory.tryConsumeConsumable(potionId)) {
      return false;
    }
    activeBuffs.activate(potion, at ?? DateTime.now());
    profile.potionsConsumed++;
    return true;
  }

  FoodUseResult consumeCookedFish(String foodId) {
    final recipe = CookingRecipeCatalog.byFoodId(foodId);
    if (recipe == null) return FoodUseResult.unknownFood;
    if (currentHealth >= maxHealth) return FoodUseResult.fullHealth;
    if (!contentInventory.tryConsumeConsumable(foodId)) {
      return FoodUseResult.notOwned;
    }
    currentHealth = (currentHealth + recipe.healAmount).clamp(0, maxHealth);
    return FoodUseResult.success;
  }

  /// A refeição de maior cura entre as que o jogador possui em estoque, ou
  /// `null` se não houver nenhuma — usada pelo consumo automático em combate.
  String? get bestOwnedFoodId {
    CookingRecipe? best;
    for (final recipe in CookingRecipeCatalog.all) {
      if (contentInventory.quantityOfConsumable(recipe.foodId) <= 0) continue;
      if (best == null || recipe.healAmount > best.healAmount) best = recipe;
    }
    return best?.foodId;
  }

  int pruneExpiredBuffs({DateTime? at}) {
    return activeBuffs.pruneExpired(at ?? DateTime.now());
  }

  void updateProfile({required String name, required String title}) {
    profile.rename(name);
    profile.chooseTitle(title);
  }

  void setMusicVolume(double volume) {
    audioSettings.musicVolume = volume.clamp(0.0, 1.0);
  }

  void setSfxVolume(double volume) {
    audioSettings.sfxVolume = volume.clamp(0.0, 1.0);
  }

  void setAudioMuted(bool muted) {
    audioSettings.muted = muted;
  }

  void completeOnboarding() {
    hasSeenOnboarding = true;
  }

  void setNotificationsEnabled(bool enabled) {
    notificationSettings.enabled = enabled;
  }

  void setAutoEatEnabled(bool enabled) {
    autoEatSettings.enabled = enabled;
  }

  void setAutoEatThreshold(int percent) {
    autoEatSettings.thresholdPercent = percent.clamp(
      AutoEatSettings.minThresholdPercent,
      AutoEatSettings.maxThresholdPercent,
    );
  }

  String get saveIdentity {
    final fragment = profile.createdAt.toRadixString(16).toUpperCase();
    return 'realm-${fragment.length <= 8 ? fragment : fragment.substring(fragment.length - 8)}';
  }

  void stopGathering() {
    activeGatheringSession = null;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'gold': gold,
    'totalLevel': totalLevel,
    'currentHealth': currentHealth,
    'skills': skills.map((key, skill) => MapEntry(key, skill.toJson())),
    'gatheringInventory': gatheringInventory.toJson(),
    'gatheringYieldRemainders': gatheringYieldRemainders,
    'activeGatheringSession': activeGatheringSession?.toJson(),
    'activeCombatSession': activeCombatSession?.toJson(),
    'activeProductionSession': activeProductionSession?.toJson(),
    'tools': tools.toJson(),
    'equipment': equipment.toJson(),
    'contentInventory': contentInventory.toJson(),
    'activeBuffs': activeBuffs.toJson(),
    'profile': profile.toJson(),
    'activeHeroClass': activeHeroClass.saveKey,
    'activeSpellId': activeSpellId,
    'classVictories': {
      for (final entry in classVictories.entries)
        entry.key.saveKey: entry.value,
    },
    'visitedRegionIds': visitedRegionIds.toList(growable: false),
    'combatDropRemainders': combatDropRemainders,
    'audioSettings': audioSettings.toJson(),
    'notificationSettings': notificationSettings.toJson(),
    'autoEatSettings': autoEatSettings.toJson(),
    'hasSeenOnboarding': hasSeenOnboarding,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final state = GameState();
    final savedSchemaVersion = _intValue(
      json['schemaVersion'],
      fallback: 1,
      minimum: 1,
    );
    state.gold = _intValue(json['gold'], fallback: 0, minimum: 0);

    final skillsJson = json['skills'];
    if (skillsJson is Map) {
      for (final entry in skillsJson.entries) {
        final skillId = entry.key;
        final skillJson = entry.value;
        final template = skillId is String ? state.skills[skillId] : null;
        if (template == null || skillJson is! Map) continue;

        final level = _intValue(skillJson['level'], fallback: 1, minimum: 1);
        final currentThreshold = Skill.experienceRequiredForLevel(level);
        final savedExperience = _doubleValue(
          skillJson['experience'],
          fallback: 0.0,
          minimum: 0.0,
        );
        final experience = savedSchemaVersion < _xpBalanceSchemaVersion
            ? _migrateLegacyExperience(
                savedExperience: savedExperience,
                savedThreshold: _intValue(
                  skillJson['experienceToNextLevel'],
                  fallback: currentThreshold,
                  minimum: 1,
                ),
                currentThreshold: currentThreshold,
              )
            : _clampExperienceToCurrentLevel(savedExperience, currentThreshold);
        state.skills[skillId as String] = Skill(
          id: template.id,
          name: template.name,
          category: template.category,
          level: level,
          experience: experience,
          experienceToNextLevel: currentThreshold,
        );
      }
    }

    if (savedSchemaVersion >= _toolSystemSchemaVersion) {
      state.tools = ToolCollection.fromJson(json['tools']);
    } else {
      state.tools = _migrateLegacyTools(json);
    }
    state._repairToolCollection();

    state.gatheringInventory = GatheringInventory.fromJson(
      json['gatheringInventory'] ?? json['miningInventory'],
    );
    if (savedSchemaVersion < _xpBalanceSchemaVersion) {
      _migrateLegacyInventory(state.gatheringInventory);
    }
    state._loadYieldRemainders(json['gatheringYieldRemainders']);
    state._loadCombatDropRemainders(json['combatDropRemainders']);

    state.equipment = EquipmentState.fromJson(json['equipment']);
    state.contentInventory = ContentInventory.fromJson(
      json['contentInventory'],
    );
    state.activeBuffs = ActiveBuffs.fromJson(json['activeBuffs']);
    state.activeBuffs.pruneExpired(DateTime.now());
    state.profile = PlayerProfile.fromJson(json['profile']);
    state.audioSettings = AudioSettings.fromJson(json['audioSettings']);
    state.notificationSettings = NotificationSettings.fromJson(
      json['notificationSettings'],
    );
    state.autoEatSettings = AutoEatSettings.fromJson(json['autoEatSettings']);
    // Saves gravados antes do onboarding existir não têm essa chave — trata
    // como "já viu" pra não reexibir o tutorial pra quem já está em progresso.
    state.hasSeenOnboarding = json.containsKey('hasSeenOnboarding')
        ? json['hasSeenOnboarding'] == true
        : true;

    final savedHeroClass = _heroClassFromKey(json['activeHeroClass']);
    state.activeHeroClass = savedHeroClass ?? HeroClass.knight;
    state.currentHealth = _intValue(
      json['currentHealth'],
      fallback: state.maxHealth,
      minimum: 0,
      maximum: state.maxHealth,
    );
    final savedSpellId = json['activeSpellId'];
    if (savedSpellId is String &&
        SpellCatalog.byId(savedSpellId) != null &&
        state.contentInventory.quantityOfSpell(savedSpellId) > 0) {
      state.activeSpellId = savedSpellId;
    }

    final savedVictories = json['classVictories'];
    if (savedVictories is Map) {
      for (final heroClass in HeroClass.values) {
        state.classVictories[heroClass] = _intValue(
          savedVictories[heroClass.saveKey],
          fallback: 0,
          minimum: 0,
        );
      }
    }

    state.visitedRegionIds.clear();
    final savedRegions = json['visitedRegionIds'];
    if (savedRegions is List) {
      for (final id in savedRegions) {
        if (id is String && WorldRegionCatalog.byId(id) != null) {
          state.visitedRegionIds.add(id);
        }
      }
    }
    state.visitedRegionIds.add(WorldRegionCatalog.all.first.id);
    if (WorldRegionCatalog.byId(state.profile.selectedRegionId) == null) {
      state.profile.selectedRegionId = WorldRegionCatalog.all.first.id;
    }
    state.visitedRegionIds.add(state.profile.selectedRegionId);

    state.activeGatheringSession = _readGatheringSession(
      json,
      state,
      savedSchemaVersion,
    );
    state.activeCombatSession = _readCombatSession(json, state);
    state.activeProductionSession = _readProductionSession(json);
    if (state.activeGatheringSession != null &&
        state.activeCombatSession != null) {
      if (state.activeCombatSession!.lastProcessedAt >=
          state.activeGatheringSession!.lastProcessedAt) {
        state.activeGatheringSession = null;
      } else {
        state.activeCombatSession = null;
      }
    }
    state.updateTotalLevel();
    return state;
  }

  static GatheringSession? _readGatheringSession(
    Map<String, dynamic> json,
    GameState state,
    int savedSchemaVersion,
  ) {
    final gatheringJson = json['activeGatheringSession'];
    if (gatheringJson != null) {
      try {
        final session = GatheringSession.fromJson(gatheringJson);
        final requestedId = _migratedResourceId(
          session.resourceId,
          savedSchemaVersion,
        );
        final requestedResource = GatheringResource.byId(requestedId);
        if (requestedResource != null) {
          final resource = _availableSessionResource(
            requestedResource,
            state,
            savedSchemaVersion,
          );
          if (resource == null) return null;

          final queuedId = session.queuedResourceId == null
              ? null
              : _migratedResourceId(
                  session.queuedResourceId!,
                  savedSchemaVersion,
                );
          final queuedResource = queuedId == null
              ? null
              : GatheringResource.byId(queuedId);
          final validQueuedId =
              queuedResource != null &&
                  state.canGather(queuedResource) &&
                  queuedResource.id != resource.id
              ? queuedResource.id
              : null;
          final sessionToolDefinition = session.toolId == null
              ? null
              : ToolCatalog.byId(session.toolId!);
          final sessionOwnedTool = sessionToolDefinition == null
              ? null
              : state.tools.ownedById[sessionToolDefinition.id];
          final hasValidToolSnapshot =
              sessionToolDefinition != null &&
              sessionToolDefinition.discipline == resource.discipline &&
              sessionOwnedTool != null &&
              session.yieldMultiplier <=
                  (sessionToolDefinition.yieldForUpgrade(
                            sessionOwnedTool.upgradeLevel,
                          ) *
                          3) +
                      0.000000001;
          final wasMigrated =
              resource.id != session.resourceId ||
              validQueuedId != session.queuedResourceId ||
              savedSchemaVersion < _toolSystemSchemaVersion ||
              !hasValidToolSnapshot;
          if (!wasMigrated) return session;

          final tool = state.equippedToolDefinition(resource.discipline);
          final duration = state.gatheringCycleDurationMilliseconds(resource);
          return GatheringSession(
            resourceId: resource.id,
            cycleDurationMilliseconds: duration,
            timeRemainingMilliseconds: session.timeRemainingMilliseconds.clamp(
              1,
              duration,
            ),
            lastProcessedAt: session.lastProcessedAt,
            toolId: tool.id,
            yieldMultiplier: state.gatheringYieldMultiplier(
              resource.discipline,
            ),
            queuedResourceId: validQueuedId,
          );
        }
      } on FormatException {
        // A sessão inválida é ignorada sem descartar o restante do save.
      }
    }

    final legacySession = json['activeMiningSession'];
    if (legacySession is! Map || legacySession['isActive'] == false) {
      return null;
    }

    final resourceId = legacySession['currentOreId'];
    final requestedResource = resourceId is String
        ? GatheringResource.byId(
            _migratedResourceId(resourceId, savedSchemaVersion),
          )
        : null;
    if (requestedResource == null) return null;
    final resource = _availableSessionResource(
      requestedResource,
      state,
      savedSchemaVersion,
    );
    if (resource == null) return null;

    final tool = state.equippedToolDefinition(resource.discipline);
    final duration = state.gatheringCycleDurationMilliseconds(resource);
    final legacyRemainingSeconds = _intValue(
      legacySession['timeRemaining'],
      fallback: (duration / 1000).ceil(),
      minimum: 1,
      maximum: 86400,
    );
    return GatheringSession(
      resourceId: resource.id,
      cycleDurationMilliseconds: duration,
      timeRemainingMilliseconds: (legacyRemainingSeconds * 1000).clamp(
        1,
        duration,
      ),
      lastProcessedAt: _intValue(
        legacySession['startTime'],
        fallback: DateTime.now().millisecondsSinceEpoch,
        minimum: 0,
      ),
      toolId: tool.id,
      yieldMultiplier: state.gatheringYieldMultiplier(resource.discipline),
    );
  }

  static CombatSession? _readCombatSession(
    Map<String, dynamic> json,
    GameState state,
  ) {
    if (state.isDefeated) return null;
    final sessionJson = json['activeCombatSession'];
    if (sessionJson == null) return null;

    try {
      final session = CombatSession.fromJson(sessionJson);
      final encounter = CombatEncounter.byId(session.encounterId);
      if (encounter == null || !state.canFight(encounter)) return null;

      final queuedEncounter = session.queuedEncounterId == null
          ? null
          : CombatEncounter.byId(session.queuedEncounterId!);
      final validQueuedId =
          queuedEncounter != null &&
              state.canFight(queuedEncounter) &&
              queuedEncounter.id != encounter.id
          ? queuedEncounter.id
          : null;
      final duration = state.combatCycleDurationMilliseconds(encounter);
      if (session.cycleDurationMilliseconds == duration &&
          session.queuedEncounterId == validQueuedId) {
        return session;
      }

      final remainingRatio =
          session.timeRemainingMilliseconds / session.cycleDurationMilliseconds;
      return CombatSession(
        encounterId: encounter.id,
        cycleDurationMilliseconds: duration,
        timeRemainingMilliseconds: (duration * remainingRatio).ceil().clamp(
          1,
          duration,
        ),
        lastProcessedAt: session.lastProcessedAt,
        queuedEncounterId: validQueuedId,
      );
    } on FormatException {
      return null;
    }
  }

  static ProductionSession? _readProductionSession(Map<String, dynamic> json) {
    final sessionJson = json['activeProductionSession'];
    if (sessionJson == null) return null;
    try {
      final session = ProductionSession.fromJson(sessionJson);
      final recipeExists = switch (session.kind) {
        ProductionKind.equipment =>
          EquipmentCatalog.byId(session.recipeId) != null,
        ProductionKind.spell => SpellCatalog.byId(session.recipeId) != null,
        ProductionKind.potion => PotionCatalog.byId(session.recipeId) != null,
        ProductionKind.smelting =>
          ProcessingRecipeCatalog.byId(session.recipeId)?.kind ==
              ProcessingKind.smelting,
        ProductionKind.arcaneRefining =>
          ProcessingRecipeCatalog.byId(session.recipeId)?.kind ==
              ProcessingKind.arcaneRefining,
        ProductionKind.cooking =>
          ProcessingRecipeCatalog.byId(session.recipeId)?.kind ==
              ProcessingKind.cooking,
        ProductionKind.woodworking =>
          ProcessingRecipeCatalog.byId(session.recipeId)?.kind ==
              ProcessingKind.woodworking,
      };
      return recipeExists ? session : null;
    } on FormatException {
      return null;
    }
  }

  static int _intValue(
    Object? value, {
    required int fallback,
    required int minimum,
    int? maximum,
  }) {
    if (value is! num || !value.isFinite) return fallback;
    final integer = value.toInt();
    if (integer < minimum) return minimum;
    if (maximum != null && integer > maximum) return maximum;
    return integer;
  }

  static double _doubleValue(
    Object? value, {
    required double fallback,
    required double minimum,
  }) {
    if (value is! num || !value.isFinite) return fallback;
    final decimal = value.toDouble();
    return decimal < minimum ? minimum : decimal;
  }

  static double _migrateLegacyExperience({
    required double savedExperience,
    required int savedThreshold,
    required int currentThreshold,
  }) {
    final progress = (savedExperience / savedThreshold).clamp(0.0, 1.0);
    return _clampExperienceToCurrentLevel(
      progress * currentThreshold,
      currentThreshold,
    );
  }

  static double _clampExperienceToCurrentLevel(
    double experience,
    int threshold,
  ) {
    final maximum = threshold - (1 / Skill.experiencePrecision);
    return Skill.normalizeExperience(experience.clamp(0.0, maximum).toDouble());
  }

  static void _migrateLegacyInventory(GatheringInventory inventory) {
    final legacyTin = inventory.quantityOf('tin');
    if (legacyTin <= 0) return;
    inventory.resources.remove('tin');
    inventory.add('rune_essence', legacyTin);
  }

  static String _migratedResourceId(String resourceId, int schema) {
    if (schema < _xpBalanceSchemaVersion && resourceId == 'tin') {
      return 'rune_essence';
    }
    return resourceId;
  }

  static GatheringResource? _availableSessionResource(
    GatheringResource requested,
    GameState state,
    int savedSchemaVersion,
  ) {
    if (state.canGather(requested)) return requested;
    if (savedSchemaVersion >= _xpBalanceSchemaVersion) return null;

    GatheringResource? bestAvailable;
    for (final resource in GatheringResource.forDiscipline(
      requested.discipline,
    )) {
      if (state.canGather(resource)) bestAvailable = resource;
    }
    return bestAvailable;
  }

  double _validatedYieldMultiplier(
    GatheringDiscipline discipline, {
    String? toolId,
    double? snapshot,
  }) {
    final definition = toolId == null ? null : ToolCatalog.byId(toolId);
    if (definition != null &&
        definition.discipline == discipline &&
        tools.ownedById.containsKey(definition.id)) {
      if (snapshot != null && snapshot.isFinite && snapshot >= 1) {
        final owned = tools.ownedById[definition.id]!;
        return snapshot.clamp(
          1.0,
          definition.yieldForUpgrade(owned.upgradeLevel) * 3,
        );
      }
      final owned = tools.ownedById[definition.id]!;
      return definition.yieldForUpgrade(owned.upgradeLevel);
    }
    return gatheringYieldMultiplier(discipline);
  }

  double _activeSpellCombatSpeedBonus() {
    if (activeHeroClass != HeroClass.mage) return 0;
    final spell = activeSpell;
    if (spell == null) return 0;
    var bonus = 0.0;
    for (final effect in spell.effects) {
      bonus += switch (effect.type) {
        SpellEffectType.magicDamage => effect.magnitude * 0.55,
        SpellEffectType.damageOverTime => effect.magnitude * 0.35,
        SpellEffectType.armorPiercing => effect.magnitude * 0.45,
        SpellEffectType.criticalChance => effect.magnitude * 0.35,
        SpellEffectType.attackSpeed => effect.magnitude,
        SpellEffectType.enemyWeakening => effect.magnitude * 0.25,
        SpellEffectType.defense ||
        SpellEffectType.healing ||
        SpellEffectType.lifeSteal ||
        SpellEffectType.lootChance => 0,
      };
    }
    return bonus.clamp(0.0, 0.5);
  }

  double _activeSpellLootBonus() {
    if (activeHeroClass != HeroClass.mage) return 0;
    final spell = activeSpell;
    if (spell == null) return 0;
    return spell.effects
        .where((effect) => effect.type == SpellEffectType.lootChance)
        .fold<double>(0, (sum, effect) => sum + effect.magnitude)
        .clamp(0.0, 1.0);
  }

  Map<String, int> _rollCombatLoot(
    String encounterId,
    int victories,
    DateTime at,
  ) {
    final loot = <String, int>{};
    final chanceMultiplier =
        buffMultiplier(BuffType.lootChance, at: at) *
        (1 + _activeSpellLootBonus());
    for (final drop in CombatDropCatalog.forEncounter(encounterId)) {
      final key = '$encounterId:${drop.id}';
      final rawQuantity =
          (drop.dropChance *
              drop.averageQuantity *
              victories *
              chanceMultiplier) +
          (combatDropRemainders[key] ?? 0);
      final quantity = rawQuantity.floor();
      combatDropRemainders[key] = _normalizeYieldRemainder(
        rawQuantity - quantity,
      );
      if (quantity > 0) loot[drop.id] = quantity;
    }
    return loot;
  }

  static String _classSkillId(HeroClass heroClass) => switch (heroClass) {
    HeroClass.knight => 'knight_mastery',
    HeroClass.assassin => 'assassin_mastery',
    HeroClass.mage => 'mage_mastery',
    HeroClass.archer => 'archer_mastery',
  };

  static HeroClass? _heroClassFromKey(Object? value) {
    if (value is! String) return null;
    for (final heroClass in HeroClass.values) {
      if (heroClass.saveKey == value) return heroClass;
    }
    return null;
  }

  static Map<String, int> _scaledCost(Map<String, int> cost, int quantity) {
    return {
      for (final entry in cost.entries)
        if (entry.value > 0) entry.key: entry.value * quantity,
    };
  }

  static ProductionKind _productionKindFor(ProcessingKind kind) =>
      switch (kind) {
        ProcessingKind.smelting => ProductionKind.smelting,
        ProcessingKind.arcaneRefining => ProductionKind.arcaneRefining,
        ProcessingKind.cooking => ProductionKind.cooking,
        ProcessingKind.woodworking => ProductionKind.woodworking,
      };

  static double _normalizeYieldRemainder(double remainder) {
    if (!remainder.isFinite || remainder <= 0) return 0.0;
    final normalized = (remainder * 1000000000).roundToDouble() / 1000000000;
    return normalized.clamp(0.0, 0.999999999);
  }

  void _loadYieldRemainders(Object? json) {
    if (json is! Map) return;
    for (final discipline in GatheringDiscipline.values) {
      final rawRemainder = json[discipline.skillId];
      if (rawRemainder is! num || !rawRemainder.isFinite) continue;
      gatheringYieldRemainders[discipline.skillId] = _normalizeYieldRemainder(
        rawRemainder.toDouble(),
      );
    }
  }

  void _loadCombatDropRemainders(Object? json) {
    if (json is! Map) return;
    for (final entry in json.entries) {
      final value = entry.value;
      if (entry.key is! String || value is! num || !value.isFinite) continue;
      combatDropRemainders[entry.key as String] = _normalizeYieldRemainder(
        value.toDouble(),
      );
    }
  }

  static ToolCollection _migrateLegacyTools(Map<String, dynamic> json) {
    final collection = _starterToolCollection();

    void importPickaxe(Object? value, {bool equipped = false}) {
      final pickaxeJson = _stringMap(value);
      if (pickaxeJson == null) return;
      final legacyId = pickaxeJson['id'];
      if (legacyId is! String) return;
      final toolId = ToolCatalog.migratedLegacyPickaxeId(legacyId);
      final definition = toolId == null ? null : ToolCatalog.byId(toolId);
      if (definition == null) return;

      final migrated = OwnedTool.fromJson(toolId!, pickaxeJson);
      migrated.upgradeLevel = migrated.upgradeLevel.clamp(
        0,
        definition.maxUpgradeLevel,
      );
      final existing = collection.ownedById[toolId];
      if (equipped ||
          existing == null ||
          migrated.upgradeLevel > existing.upgradeLevel) {
        collection.ownedById[toolId] = migrated;
      }
      if (equipped) {
        collection.equippedByDiscipline[GatheringDiscipline.mining] = toolId;
      }
    }

    final ownedPickaxes = json['ownedPickaxes'];
    if (ownedPickaxes is List) {
      for (final pickaxe in ownedPickaxes) {
        importPickaxe(pickaxe);
      }
    }
    importPickaxe(json['currentPickaxe'], equipped: true);
    return collection;
  }

  static ToolCollection _starterToolCollection() {
    final collection = ToolCollection();
    for (final discipline in GatheringDiscipline.values) {
      final starter = ToolCatalog.starterFor(discipline);
      collection.ownedById[starter.id] = OwnedTool(toolId: starter.id);
      collection.equippedByDiscipline[discipline] = starter.id;
    }
    return collection;
  }

  void _repairToolCollection() {
    tools.ownedById.removeWhere((toolId, ownedTool) {
      final definition = ToolCatalog.byId(toolId);
      if (definition == null || ownedTool.toolId != toolId) return true;
      ownedTool.upgradeLevel = ownedTool.upgradeLevel.clamp(
        0,
        definition.maxUpgradeLevel,
      );
      return false;
    });

    for (final discipline in GatheringDiscipline.values) {
      final starter = ToolCatalog.starterFor(discipline);
      tools.ownedById.putIfAbsent(
        starter.id,
        () => OwnedTool(toolId: starter.id),
      );

      final equippedId = tools.equippedByDiscipline[discipline];
      final equippedDefinition = equippedId == null
          ? null
          : ToolCatalog.byId(equippedId);
      if (equippedDefinition == null ||
          equippedDefinition.discipline != discipline ||
          !tools.ownedById.containsKey(equippedDefinition.id)) {
        tools.equippedByDiscipline[discipline] = starter.id;
      }
    }
  }

  static Map<String, dynamic>? _stringMap(Object? value) {
    if (value is! Map) return null;
    try {
      return Map<String, dynamic>.from(value);
    } on TypeError {
      return null;
    }
  }
}
