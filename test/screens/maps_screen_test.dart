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
    expect(tester.takeException(), isNull);
  });
}
