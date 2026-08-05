import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/tools/data/tool_catalog.dart';
import 'package:realm_idle_game/features/tools/screens/tools_screen.dart';
import 'package:realm_idle_game/models/game_state.dart';

void main() {
  void useNarrowViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpToolsScreen(
    WidgetTester tester,
    GameState state, {
    VoidCallback? onStateChanged,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: ToolsScreen(
            gameState: state,
            onStateChanged: onStateChanged ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders all three six-tier catalogs on a narrow viewport', (
    tester,
  ) async {
    useNarrowViewport(tester);
    final state = GameState();

    await pumpToolsScreen(tester, state);

    expect(find.text('Ferramentas'), findsOneWidget);
    expect(find.text('Picaretas'), findsOneWidget);
    expect(find.text('Machados'), findsOneWidget);
    expect(find.text('Varas'), findsOneWidget);
    expect(find.text('EQUIPADA'), findsWidgets);
    expect(find.text('ARSENAL'), findsOneWidget);
    expect(find.byKey(const ValueKey('equipped-tool-card')), findsOneWidget);
    for (final tool in ToolCatalog.forDiscipline(GatheringDiscipline.mining)) {
      expect(find.byKey(ValueKey('tool-card-${tool.id}')), findsOneWidget);
    }
    expect(find.text('Requer Nível 20'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('tools-discipline-woodcutting')),
    );
    await tester.pumpAndSettle();
    for (final tool in ToolCatalog.forDiscipline(
      GatheringDiscipline.woodcutting,
    )) {
      expect(find.byKey(ValueKey('tool-card-${tool.id}')), findsOneWidget);
    }
    expect(
      state.equippedToolDefinition(GatheringDiscipline.woodcutting).id,
      'axe:wooden',
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('tools-discipline-fishing')));
    await tester.pumpAndSettle();
    for (final tool in ToolCatalog.forDiscipline(GatheringDiscipline.fishing)) {
      expect(find.byKey(ValueKey('tool-card-${tool.id}')), findsOneWidget);
    }
    expect(
      state.equippedToolDefinition(GatheringDiscipline.fishing).id,
      'rod:basic',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fabricates, equips, and upgrades without granting click XP', (
    tester,
  ) async {
    useNarrowViewport(tester);
    final state = GameState();
    state.skills['mining']!.level = 20;
    state.addGold(630);
    state.gatheringInventory.add('iron_bar', 72);
    final experienceBefore = state.skills['mining']!.experience;
    var changedCount = 0;

    await pumpToolsScreen(tester, state, onStateChanged: () => changedCount++);

    final acquire = find.byKey(const ValueKey('tool-acquire-pickaxe:iron'));
    await tester.ensureVisible(acquire);
    await tester.pumpAndSettle();
    await tester.tap(acquire);
    await tester.pumpAndSettle();

    expect(state.ownedTool('pickaxe:iron'), isNotNull);
    expect(state.gatheringInventory.quantityOf('iron_bar'), 12);
    expect(state.gold, 30);
    expect(changedCount, 1);
    expect(find.textContaining('foi fabricada.'), findsOneWidget);
    expect(state.skills['mining']!.experience, experienceBefore);

    final equip = find.byKey(const ValueKey('tool-equip-pickaxe:iron'));
    await tester.ensureVisible(equip);
    await tester.pumpAndSettle();
    await tester.tap(equip);
    await tester.pumpAndSettle();

    expect(state.tools.equippedId(GatheringDiscipline.mining), 'pickaxe:iron');
    expect(changedCount, 2);
    expect(find.textContaining('foi equipada.'), findsOneWidget);
    expect(state.skills['mining']!.experience, experienceBefore);

    final upgrade = find.byKey(const ValueKey('tool-upgrade-pickaxe:iron'));
    await tester.ensureVisible(upgrade);
    await tester.pumpAndSettle();
    await tester.tap(upgrade);
    await tester.pumpAndSettle();

    expect(state.ownedTool('pickaxe:iron')?.upgradeLevel, 1);
    expect(state.gatheringInventory.quantityOf('iron_bar'), 0);
    expect(state.gold, 0);
    expect(changedCount, 3);
    expect(find.textContaining('foi melhorada.'), findsOneWidget);
    expect(state.skills['mining']!.experience, experienceBefore);
    expect(tester.takeException(), isNull);
  });
}
