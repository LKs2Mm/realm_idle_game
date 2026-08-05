import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';
import 'package:realm_idle_game/screens/skills_screen.dart';
import 'package:realm_idle_game/widgets/animated_xp_progress.dart';
import 'package:realm_idle_game/widgets/skill_card.dart';

void main() {
  testWidgets(
    'habilidades mostra classes com barra decorativa e sem conceder XP por toque',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final gameState = GameState();
      gameState.skills['knight_mastery']!.level = 7;
      gameState.skills['smithing']!.level = 5;
      gameState.skills['devotion'] = Skill(
        id: 'devotion',
        name: 'Devoção Rúnica',
        category: SkillCategory.divinity,
      );
      gameState.updateTotalLevel();
      final experienceBefore = gameState.skills['knight_mastery']!.experience;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(body: SkillsScreen(gameState: gameState)),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('skills-class-armory-banner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('skills-progression-doctrine')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('skills-workshop-ledger')),
        findsNothing,
      );
      expect(find.text('OFICINAS INDEPENDENTES'), findsNothing);
      expect(find.text('Nível 7 · EM USO'), findsOneWidget);
      expect(find.text('Assassino'), findsWidgets);
      expect(find.text('Mago'), findsWidgets);
      expect(find.text('Arqueiro'), findsWidgets);

      // Cada selo de classe mostra uma barra de progresso decorativa.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('class-mastery-knight')),
          matching: find.byType(AnimatedXpProgress),
        ),
        findsOneWidget,
      );

      // Tocar o selo de classe não navega nem concede XP — é só decorativo.
      await tester.tap(
        find.byKey(const ValueKey<String>('class-mastery-knight')),
      );
      await tester.pump();
      expect(gameState.skills['knight_mastery']!.experience, experienceBefore);

      await tester.ensureVisible(find.text('DIVINDADE'));
      await tester.pumpAndSettle();
      expect(find.text('PRODUÇÃO'), findsOneWidget);
      expect(find.text('DIVINDADE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('toca em card de perícia dispara onOpenSkill', (tester) async {
    tester.view.physicalSize = const Size(320, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gameState = GameState();
    final opened = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: SkillsScreen(gameState: gameState, onOpenSkill: opened.add),
        ),
      ),
    );
    await tester.pump();

    // O selo de classe continua sem navegar, mesmo com onOpenSkill definido.
    await tester.tap(
      find.byKey(const ValueKey<String>('class-mastery-knight')),
    );
    await tester.pump();
    expect(opened, isEmpty);

    final miningCard = find.ancestor(
      of: find.text('Mineração'),
      matching: find.byType(SkillCard),
    );
    expect(miningCard, findsOneWidget);
    await tester.tap(miningCard);
    await tester.pump();
    expect(opened, ['mining']);

    final cookingCard = find.ancestor(
      of: find.text('Culinária'),
      matching: find.byType(SkillCard),
    );
    expect(cookingCard, findsOneWidget);
    await tester.tap(cookingCard);
    await tester.pump();
    expect(opened, ['mining', 'cooking']);
    expect(tester.takeException(), isNull);
  });
}
