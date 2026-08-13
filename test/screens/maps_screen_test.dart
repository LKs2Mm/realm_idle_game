import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/features/content/models/world_region.dart';
import 'package:realm_idle_game/screens/maps_screen.dart';

void main() {
  testWidgets('maps selects unlocked regions and blocks unmet requirements', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const regions = [
      WorldRegion(
        id: 'crossroads',
        name: 'Encruzilhada Cinzenta',
        lore: 'Cinzas antigas cobrem a primeira estrada.',
        sigil: 'Δ',
        primaryColorValue: 0x5E5145,
        accentColorValue: 0xC49A52,
        requirement: RegionRequirement(),
        enemyIds: ['rat'],
        workshops: [WorkshopType.forge],
      ),
      WorldRegion(
        id: 'bastion',
        name: 'Bastião Obsidiano',
        lore: 'Uma fortaleza que ainda vigia o abismo.',
        sigil: 'Ω',
        primaryColorValue: 0x392D43,
        accentColorValue: 0xA779B4,
        requirement: RegionRequirement(
          requiredCombatLevel: 20,
          requiredSkillLevels: {'mining': 10},
          prerequisiteRegionId: 'crossroads',
        ),
        enemyIds: ['sentinel'],
        workshops: [WorkshopType.arcanistSanctum],
      ),
    ];

    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: MapsScreen(
            regions: regions,
            selectedRegionId: null,
            combatLevel: 1,
            skillLevels: const {'mining': 1},
            completedRegionIds: const {},
            onSelectRegion: selected.add,
          ),
        ),
      ),
    );

    expect(find.text('Mapas'), findsOneWidget);
    expect(find.text('Encruzilhada Cinzenta'), findsOneWidget);
    expect(find.text('Bastião Obsidiano'), findsOneWidget);
    expect(find.text('Forja do Ferreiro'), findsOneWidget);
    expect(find.textContaining('Combate 20'), findsOneWidget);
    expect(find.textContaining('Mineração 10'), findsOneWidget);
    expect(find.text('BLOQUEADA'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('maps-world-banner')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('region-crossroads')));
    expect(selected, ['crossroads']);

    final lockedRegion = find.byKey(const ValueKey<String>('region-bastion'));
    await tester.ensureVisible(lockedRegion);
    await tester.tap(lockedRegion);
    expect(selected, ['crossroads']);

    final unlockedSemantics = tester.getSemantics(
      find.bySemanticsLabel('Encruzilhada Cinzenta'),
    );
    expect(unlockedSemantics.flagsCollection.isButton, isTrue);
    expect(unlockedSemantics.flagsCollection.isEnabled.toBoolOrNull(), isTrue);

    final lockedSemantics = tester.getSemantics(
      find.bySemanticsLabel('Bastião Obsidiano'),
    );
    expect(lockedSemantics.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
    expect(lockedSemantics.value, contains('bloqueada'));
    expect(lockedSemantics.value, contains('Combate 20'));

    final combatMetric = tester.getSemantics(
      find.bySemanticsLabel('Nível de combate'),
    );
    expect(combatMetric.value, '1');

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when there are no regions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: MapsScreen(
            regions: const [],
            selectedRegionId: null,
            combatLevel: 1,
            skillLevels: const {},
            completedRegionIds: const {},
            onSelectRegion: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.text('Nenhuma região foi registrada neste mapa.'),
      findsOneWidget,
    );
    expect(find.text('0 de 0 abertas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows the current-destination notice and every workshop chip once unlocked',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const region = WorldRegion(
        id: 'crossroads',
        name: 'Encruzilhada Cinzenta',
        lore: 'Cinzas antigas cobrem a primeira estrada.',
        sigil: 'Δ',
        primaryColorValue: 0x5E5145,
        accentColorValue: 0xC49A52,
        requirement: RegionRequirement(),
        enemyIds: ['rat'],
        workshops: WorkshopType.values,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: MapsScreen(
              regions: const [region],
              selectedRegionId: 'crossroads',
              combatLevel: 1,
              skillLevels: const {},
              completedRegionIds: const {},
              onSelectRegion: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('A região destacada é o destino atual'),
        findsOneWidget,
      );
      expect(find.text('ATUAL'), findsOneWidget);
      for (final workshop in WorkshopType.values) {
        expect(find.text(workshop.displayName), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders without overflow at a large accessibility text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const region = WorldRegion(
      id: 'crossroads',
      name: 'Encruzilhada Cinzenta',
      lore: 'Cinzas antigas cobrem a primeira estrada e guardam segredos.',
      sigil: 'Δ',
      primaryColorValue: 0x5E5145,
      accentColorValue: 0xC49A52,
      requirement: RegionRequirement(),
      enemyIds: ['rat'],
      workshops: WorkshopType.values,
    );
    const locked = WorldRegion(
      id: 'bastion',
      name: 'Bastião Obsidiano',
      lore: 'Uma fortaleza que ainda vigia o abismo.',
      sigil: 'Ω',
      primaryColorValue: 0x392D43,
      accentColorValue: 0xA779B4,
      requirement: RegionRequirement(
        requiredCombatLevel: 20,
        requiredSkillLevels: {'mining': 10},
        prerequisiteRegionId: 'crossroads',
      ),
      enemyIds: ['sentinel'],
      workshops: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Scaffold(
          body: MapsScreen(
            regions: const [region, locked],
            selectedRegionId: 'crossroads',
            combatLevel: 1,
            skillLevels: const {},
            completedRegionIds: const {},
            onSelectRegion: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
