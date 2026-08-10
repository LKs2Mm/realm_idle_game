import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/features/processing/data/cooking_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/skewer_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/data/smelting_recipe_catalog.dart';
import 'package:realm_idle_game/features/processing/screens/processing_panel.dart';
import 'package:realm_idle_game/models/game_state.dart';

void main() {
  void configureMobileView(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget app({
    required GameState state,
    required void Function(String recipeId, int quantity, bool repeat)
    onStart,
    required ValueChanged<String> onEat,
    required VoidCallback onCancel,
  }) {
    return MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: ProcessingPanel(
          gameState: state,
          onStartProcessing: onStart,
          onEatFood: onEat,
          onCancelProduction: onCancel,
        ),
      ),
    );
  }

  testWidgets('switches crafts, scales batches, and dispatches mobile actions', (
    tester,
  ) async {
    configureMobileView(tester);
    final state = GameState();
    state.currentHealth = state.maxHealth - 20;
    final smelting = SmeltingRecipeCatalog.all.first;
    final cooking = CookingRecipeCatalog.all.first;
    final skewers = SkewerRecipeCatalog.recipe;
    for (final entry in smelting.cost.multipliedBy(5).entries) {
      state.gatheringInventory.add(entry.key, entry.value);
    }
    for (final entry in cooking.cost.multipliedBy(5).entries) {
      state.gatheringInventory.add(entry.key, entry.value);
    }
    for (final entry in skewers.cost.multipliedBy(5).entries) {
      state.gatheringInventory.add(entry.key, entry.value);
    }
    state.contentInventory.addConsumable(cooking.foodId, 2);

    final starts = <String>[];
    final foods = <String>[];
    await tester.pumpWidget(
      app(
        state: state,
        onStart: (recipeId, quantity, _) => starts.add('$recipeId:$quantity'),
        onEat: foods.add,
        onCancel: () {},
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('processing-health')),
      findsOneWidget,
    );
    expect(find.text('${state.currentHealth} / ${state.maxHealth} HP'), findsOneWidget);
    expect(find.text('Fundição'), findsOneWidget);
    expect(find.text('Culinária'), findsOneWidget);
    expect(find.text('Marcenaria'), findsOneWidget);
    expect(
      find.byKey(ValueKey<String>('processing-card-${smelting.id}')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('processing-quantity-5')),
    );
    await tester.pump();
    final smeltingStart = find.byKey(
      ValueKey<String>('processing-start-${smelting.id}'),
    );
    await tester.ensureVisible(smeltingStart);
    await tester.tap(smeltingStart);
    expect(starts, ['${smelting.id}:5']);
    expect(
      find.byKey(
        ValueKey<String>('processing-cost-${smelting.id}-${smelting.oreId}'),
      ),
      findsOneWidget,
    );

    final cookingChip = find.byKey(
      const ValueKey<String>('processing-kind-cooking'),
    );
    await tester.ensureVisible(cookingChip);
    await tester.tap(cookingChip);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey<String>('processing-card-${cooking.id}')),
      findsOneWidget,
    );
    final cookingCard = find.byKey(
      ValueKey<String>('processing-card-${cooking.id}'),
    );
    expect(
      find.descendant(
        of: cookingCard,
        matching: find.text('+${cooking.healAmount} HP cada'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cookingCard, matching: find.text('Produz ×5')),
      findsOneWidget,
    );
    final eat = find.byKey(
      ValueKey<String>('processing-eat-${cooking.foodId}'),
    );
    await tester.ensureVisible(eat);
    final eatButton = tester.widget<OutlinedButton>(eat);
    expect(eatButton.onPressed, isNotNull);
    eatButton.onPressed!.call();
    expect(foods, [cooking.foodId]);

    state.currentHealth = state.maxHealth;
    await tester.pumpWidget(
      app(
        state: state,
        onStart: (recipeId, quantity, _) => starts.add('$recipeId:$quantity'),
        onEat: foods.add,
        onCancel: () {},
      ),
    );
    expect(tester.widget<OutlinedButton>(eat).onPressed, isNull);
    expect(find.text('Vida cheia'), findsOneWidget);

    final woodworkingChip = find.byKey(
      const ValueKey<String>('processing-kind-woodworking'),
    );
    await tester.ensureVisible(woodworkingChip);
    await tester.tap(woodworkingChip);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey<String>('processing-card-${skewers.id}')),
      findsOneWidget,
    );
    expect(find.text('Produz ×25'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables start for level, cost, and occupied production queue', (
    tester,
  ) async {
    configureMobileView(tester);
    final state = GameState();
    final recipe = SmeltingRecipeCatalog.all.first;
    var cancelled = false;

    await tester.pumpWidget(
      app(
        state: state,
        onStart: (_, _, _) {},
        onEat: (_) {},
        onCancel: () => cancelled = true,
      ),
    );
    final start = find.byKey(
      ValueKey<String>('processing-start-${recipe.id}'),
    );
    await tester.ensureVisible(start);
    expect(tester.widget<ElevatedButton>(start).onPressed, isNull);
    expect(find.text('Materiais insuficientes'), findsOneWidget);

    state.skills[recipe.skillId]!.level = 0;
    await tester.pumpWidget(
      app(
        state: state,
        onStart: (_, _, _) {},
        onEat: (_) {},
        onCancel: () => cancelled = true,
      ),
    );
    expect(tester.widget<ElevatedButton>(start).onPressed, isNull);
    expect(find.text('Requer nível 1'), findsOneWidget);

    state.skills[recipe.skillId]!.level = 1;
    for (final entry in recipe.cost.materials.entries) {
      state.gatheringInventory.add(entry.key, entry.value);
    }
    expect(state.startProcessing(recipe.id), isNotNull);
    final session = state.activeProductionSession!;
    session.timeRemainingMilliseconds = session.durationMilliseconds ~/ 2;
    await tester.pumpWidget(
      app(
        state: state,
        onStart: (_, _, _) {},
        onEat: (_) {},
        onCancel: () => cancelled = true,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('processing-active-session')),
      findsOneWidget,
    );
    final progress = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey<String>('processing-session-progress')),
    );
    expect(progress.value, closeTo(0.5, 0.001));
    expect(tester.widget<ElevatedButton>(start).onPressed, isNull);
    expect(find.text('Fila ocupada'), findsWidgets);

    final cancel = find.byKey(
      const ValueKey<String>('processing-cancel-production'),
    );
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    expect(cancelled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders roasted food art on cooking recipe cards', (
    tester,
  ) async {
    configureMobileView(tester);
    final state = GameState();
    final cooking = CookingRecipeCatalog.all.first;

    await tester.pumpWidget(
      app(
        state: state,
        onStart: (_, _, _) {},
        onEat: (_) {},
        onCancel: () {},
      ),
    );
    final cookingChip = find.byKey(
      const ValueKey<String>('processing-kind-cooking'),
    );
    await tester.ensureVisible(cookingChip);
    await tester.tap(cookingChip);
    await tester.pumpAndSettle();

    bool matchesFoodArt(Widget widget) {
      if (widget is! Image) return false;
      final image = widget.image;
      if (image is! AssetImage) return false;
      return image.assetName ==
          MedievalAssets.gatheringItemAsset('comidas', cooking.foodId);
    }

    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('processing-card-${cooking.id}')),
        matching: find.byWidgetPredicate(matchesFoodArt),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders metal bar art on smelting recipe cards', (
    tester,
  ) async {
    configureMobileView(tester);
    final state = GameState();
    final smelting = SmeltingRecipeCatalog.forMaterial(
      EquipmentMaterial.copper,
    )!;

    await tester.pumpWidget(
      app(
        state: state,
        onStart: (_, _, _) {},
        onEat: (_) {},
        onCancel: () {},
      ),
    );

    bool matchesBarArt(Widget widget) {
      if (widget is! Image) return false;
      final image = widget.image;
      if (image is! AssetImage) return false;
      return image.assetName ==
          MedievalAssets.gatheringItemAsset('barras', smelting.output.resourceId);
    }

    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('processing-card-${smelting.id}')),
        matching: find.byWidgetPredicate(matchesBarArt),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps consume disabled without owned food', (tester) async {
    configureMobileView(tester);
    final state = GameState();
    state.currentHealth = state.maxHealth - 1;
    final recipe = CookingRecipeCatalog.all.first;

    await tester.pumpWidget(
      app(
        state: state,
        onStart: (_, _, _) {},
        onEat: (_) {},
        onCancel: () {},
      ),
    );
    final cookingChip = find.byKey(
      const ValueKey<String>('processing-kind-cooking'),
    );
    await tester.ensureVisible(cookingChip);
    await tester.tap(cookingChip);
    await tester.pumpAndSettle();
    final eat = find.byKey(
      ValueKey<String>('processing-eat-${recipe.foodId}'),
    );
    await tester.ensureVisible(eat);
    expect(tester.widget<OutlinedButton>(eat).onPressed, isNull);
    expect(
      find.descendant(
        of: find.byKey(ValueKey<String>('processing-card-${recipe.id}')),
        matching: find.text('Nenhuma porção pronta'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'toggling produção contínua passes repeat=true to onStartProcessing',
    (tester) async {
      configureMobileView(tester);
      final state = GameState();
      final smelting = SmeltingRecipeCatalog.all.first;
      for (final entry in smelting.cost.multipliedBy(1).entries) {
        state.gatheringInventory.add(entry.key, entry.value);
      }

      final starts = <bool>[];
      await tester.pumpWidget(
        app(
          state: state,
          onStart: (_, _, repeat) => starts.add(repeat),
          onEat: (_) {},
          onCancel: () {},
        ),
      );

      final start = find.byKey(
        ValueKey<String>('processing-start-${smelting.id}'),
      );
      await tester.ensureVisible(start);
      await tester.tap(start);
      expect(starts, [false]);

      final repeatToggle = find.byKey(
        const ValueKey<String>('processing-repeat'),
      );
      await tester.ensureVisible(repeatToggle);
      await tester.tap(repeatToggle);
      await tester.pump();

      await tester.ensureVisible(start);
      await tester.tap(start);

      expect(starts, [false, true]);
      expect(tester.takeException(), isNull);
    },
  );
}
