import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/features/content/models/active_buffs.dart';
import 'package:realm_idle_game/features/content/models/alchemy.dart';
import 'package:realm_idle_game/features/content/models/content_cost.dart';
import 'package:realm_idle_game/features/content/models/content_inventory.dart';
import 'package:realm_idle_game/features/content/models/spell.dart';
import 'package:realm_idle_game/features/equipment/data/equipment_catalog.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/production/models/production_session.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/screens/items_screen.dart';

void main() {
  testWidgets('items previews four classes and dispatches item actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sword = EquipmentCatalog.definition(
      heroClass: HeroClass.knight,
      slot: EquipmentSlot.weapon,
      material: EquipmentMaterial.copper,
      rarity: EquipmentRarity.common,
    );
    final runicSword = EquipmentCatalog.definition(
      heroClass: HeroClass.knight,
      slot: EquipmentSlot.weapon,
      material: EquipmentMaterial.runite,
      rarity: EquipmentRarity.runic,
    );
    const potion = PotionDefinition(
      id: 'minor_harvest',
      name: 'Elixir da Colheita',
      description: 'Acelera as mãos por alguns instantes.',
      sigil: 'φ',
      requiredLevel: 1,
      craftDurationMilliseconds: 1000,
      craftingExperience: 2,
      durationSeconds: 60,
      potency: 0.1,
      buffType: BuffType.gatheringSpeed,
      cost: ContentCost({'copper': 1}),
    );
    const spell = SpellDefinition(
      id: 'ember_rune',
      name: 'Runa de Brasa',
      description: 'Uma chama presa em um sigilo antigo.',
      sigil: 'Ψ',
      school: SpellSchool.flame,
      requiredLevel: 1,
      craftDurationMilliseconds: 1000,
      craftingExperience: 2,
      cost: ContentCost({'copper': 1}),
      effects: [SpellEffect(type: SpellEffectType.magicDamage, magnitude: 0.1)],
    );

    final equipment = EquipmentState(
      inventory: EquipmentInventory(items: {sword.id: 1, runicSword.id: 1}),
      loadouts: EquipmentLoadouts(
        equipped: {
          HeroClass.knight: {EquipmentSlot.weapon: runicSword.id},
        },
      ),
    );
    final content = ContentInventory(
      consumables: {potion.id: 1},
      spells: {spell.id: 1},
    );
    final actions = <String>[];
    var productionCancelled = false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final activeBuffs = ActiveBuffs(
      activeByType: {
        BuffType.gatheringSpeed: ActiveBuff(
          sourcePotionId: potion.id,
          type: BuffType.gatheringSpeed,
          potency: potion.potency,
          startedAtEpochMilliseconds: now,
          expiresAtEpochMilliseconds: now + 65000,
        ),
      },
    );
    final productionSession = ProductionSession(
      kind: ProductionKind.equipment,
      recipeId: sword.id,
      displayName: sword.name,
      quantity: 1,
      durationMilliseconds: 10000,
      timeRemainingMilliseconds: 4000,
      lastProcessedAt: 0,
      goldCost: 12,
      resourceCost: const {'copper': 2},
      skillId: 'smithing',
      experience: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: ItemsScreen(
            gameState: GameState(),
            equipment: equipment,
            contentInventory: content,
            equipmentDefinitions: [sword, runicSword],
            potions: const [potion],
            spells: const [spell],
            workshopLevels: const {
              EquipmentWorkshop.blacksmith: 99,
              EquipmentWorkshop.veilGuild: 1,
              EquipmentWorkshop.arcanist: 1,
              EquipmentWorkshop.artisan: 1,
            },
            availableMaterials: const {
              'copper': 999,
              'copper_bar': 999,
              'grave_dust': 3,
              'oak_log': 0,
              'unknown_relic': 8,
            },
            availableGold: 9999,
            alchemyLevel: 10,
            magicLevel: 10,
            activeBuffs: activeBuffs,
            activeSpellId: spell.id,
            activeProductionSession: productionSession,
            onCancelProduction: () => productionCancelled = true,
            onCraftEquipment: (id) => actions.add('craft:$id'),
            onEquipItem: (id) => actions.add('equip:$id'),
            onBrewPotion: (id) => actions.add('brew:$id'),
            onUsePotion: (id) => actions.add('potion:$id'),
            onCraftSpell: (id) => actions.add('inscribe:$id'),
            onUseSpell: (id) => actions.add('spell:$id'),
            onStartProcessing: (id, quantity) =>
                actions.add('process:$id:$quantity'),
            onEatFood: (id) => actions.add('eat:$id'),
          ),
        ),
      ),
    );

    expect(find.text('Itens'), findsOneWidget);
    expect(find.text('Cavaleiro'), findsOneWidget);
    expect(find.text('Assassino'), findsOneWidget);
    expect(find.text('Mago'), findsOneWidget);
    expect(find.text('Arqueiro'), findsOneWidget);
    expect(find.textContaining('sem compromisso permanente'), findsOneWidget);
    final equippedWeapon = tester.widget<Card>(
      find.byKey(const ValueKey<String>('equipped-slot-weapon')),
    );
    expect(equippedWeapon.elevation, greaterThan(0));
    expect(equippedWeapon.shadowColor, isNotNull);
    expect(
      find.byKey(const ValueKey<String>('items-active-production')),
      findsOneWidget,
    );
    expect(find.textContaining('Equipamento'), findsOneWidget);
    expect(find.text('00:04'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('items-cancel-production')),
    );
    expect(productionCancelled, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('items-tab-arsenal')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('equipment-preview-${sword.id}')),
        matching: find.text(sword.name),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('items-armory-banner')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('equipment-preview-${sword.id}')),
        matching: find.textContaining('Físico +'),
      ),
      findsOneWidget,
    );

    final craft = find.byKey(ValueKey<String>('equipment-craft-${sword.id}'));
    await tester.ensureVisible(craft);
    await tester.tap(craft);
    final equip = find.byKey(ValueKey<String>('equipment-equip-${sword.id}'));
    await tester.tap(equip);

    await tester.tap(find.byKey(const ValueKey<String>('items-tab-workshops')));
    await tester.pumpAndSettle();
    expect(find.text('Ferreiro'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('items-workshop-banner')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('items-tab-alchemy')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('items-active-buffs')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('active-buff-gatheringSpeed')),
        matching: find.text('Velocidade de coleta +10%'),
      ),
      findsOneWidget,
    );
    final brew = find.byKey(
      const ValueKey<String>('potion-brew-minor_harvest'),
    );
    await tester.ensureVisible(brew);
    await tester.tap(brew);
    final usePotion = find.byKey(
      const ValueKey<String>('potion-use-minor_harvest'),
    );
    tester.widget<OutlinedButton>(usePotion).onPressed!.call();

    final grimoireTab = find.byKey(
      const ValueKey<String>('items-tab-grimoire'),
    );
    await tester.ensureVisible(grimoireTab);
    await tester.tap(grimoireTab);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('items-active-spell')),
        matching: find.text(spell.name),
      ),
      findsOneWidget,
    );
    final inscribe = find.byKey(
      const ValueKey<String>('spell-craft-ember_rune'),
    );
    await tester.ensureVisible(inscribe);
    await tester.tap(inscribe);
    await tester.tap(
      find.byKey(const ValueKey<String>('spell-use-ember_rune')),
    );

    final processingTab = find.byKey(
      const ValueKey<String>('items-tab-processing'),
    );
    await tester.ensureVisible(processingTab);
    await tester.tap(processingTab);
    await tester.pumpAndSettle();
    expect(find.text('Fundição'), findsOneWidget);
    expect(find.text('Culinária'), findsOneWidget);

    final materialsTab = find.byKey(
      const ValueKey<String>('items-tab-materials'),
    );
    await tester.ensureVisible(materialsTab);
    await tester.tap(materialsTab);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('items-materials-summary')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('material-copper')),
        matching: find.text('Minério de cobre'),
      ),
      findsOneWidget,
    );
    final materialsScrollable = find
        .ancestor(
          of: find.byKey(const ValueKey<String>('items-materials-summary')),
          matching: find.byType(Scrollable),
        )
        .first;
    final graveDustMaterial = find.byKey(
      const ValueKey<String>('material-grave_dust'),
    );
    await tester.scrollUntilVisible(
      graveDustMaterial,
      200,
      scrollable: materialsScrollable,
    );
    expect(
      find.descendant(
        of: graveDustMaterial,
        matching: find.text('Pó sepulcral'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('material-oak_log')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('material-unknown_relic')),
      findsNothing,
    );

    expect(actions, [
      'craft:${sword.id}',
      'equip:${sword.id}',
      'brew:minor_harvest',
      'potion:minor_harvest',
      'inscribe:ember_rune',
      'spell:ember_rune',
    ]);
    expect(tester.takeException(), isNull);
  });
}
