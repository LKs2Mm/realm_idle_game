import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';
import 'package:realm_idle_game/screens/skills_screen.dart';
import 'package:realm_idle_game/widgets/skill_card.dart';

void main() {
  testWidgets('skill cards are informational and never grant XP on tap', (
    tester,
  ) async {
    final skill = Skill(
      id: 'mining',
      name: 'Mineração',
      category: SkillCategory.gathering,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 220,
            child: SkillCard(skill: skill, categoryColor: Colors.green),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SkillCard));
    await tester.pump();

    expect(skill.experience, 0);
    expect(skill.level, 1);
  });

  testWidgets('skills grid uses two columns on narrow mobile screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: SkillsScreen(gameState: GameState())),
    );

    final firstGrid = tester.widget<GridView>(find.byType(GridView).first);
    final delegate =
        firstGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('XP bar and text animate smoothly within the same level', (
    tester,
  ) async {
    final skill = Skill(
      id: 'mining',
      name: 'Mineração',
      category: SkillCategory.gathering,
    );

    Widget buildCard() => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 180,
          height: 220,
          child: SkillCard(skill: skill, categoryColor: Colors.green),
        ),
      ),
    );

    double barValue() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    await tester.pumpWidget(buildCard());
    expect(barValue(), 0);

    skill.addExperience(5.6);
    await tester.pumpWidget(buildCard());
    expect(barValue(), closeTo(0, 0.000001));

    await tester.pump(const Duration(milliseconds: 160));
    expect(barValue(), greaterThan(0));
    expect(barValue(), lessThan(0.112));

    await tester.pump(const Duration(milliseconds: 400));
    expect(barValue(), closeTo(0.112, 0.000001));
    expect(find.text('5,6 / 50 XP'), findsOneWidget);
  });

  testWidgets('level-up starts at the real new-level progress', (tester) async {
    final skill = Skill(
      id: 'mining',
      name: 'Mineração',
      category: SkillCategory.gathering,
      experience: 49.4,
    );

    Widget buildCard() => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 180,
          height: 220,
          child: SkillCard(skill: skill, categoryColor: Colors.green),
        ),
      ),
    );

    await tester.pumpWidget(buildCard());
    skill.addExperience(0.6);
    await tester.pumpWidget(buildCard());

    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(skill.level, 2);
    expect(progress.value, 0);
    expect(find.text('0 / 80 XP'), findsOneWidget);
  });
}
