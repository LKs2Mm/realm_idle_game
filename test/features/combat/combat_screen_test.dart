import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/features/combat/services/combat_service.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/models/game_state.dart';
import 'package:realm_idle_game/models/skill.dart';
import 'package:realm_idle_game/screens/combat_screen.dart';
import 'package:realm_idle_game/widgets/header_widget.dart';

void main() {
  testWidgets('combat starts automatically and only rewards completed cycles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var currentTime = DateTime(2026, 8, 1, 12);
    final state = GameState();
    final service = CombatService(
      onUpdate: (_, _) {},
      now: () => currentTime,
      enableTimer: false,
    );
    service.initialize(state);
    addTearDown(service.dispose);

    await tester.pumpWidget(_combatApp(state: state, service: service));

    expect(find.text('Combate'), findsOneWidget);
    expect(find.text('Rato Sepulcral'), findsOneWidget);
    expect(find.text('+2 ouro'), findsOneWidget);
    expect(find.text('100 / 100 HP'), findsOneWidget);
    expect(find.text('-1 HP'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('combat-health-bar')),
      findsOneWidget,
    );
    expect(find.text('Nv. 10'), findsWidgets);
    expect(find.byType(RunicDivider), findsOneWidget);
    expect(find.byType(RunicFrame), findsWidgets);
    expect(state.gold, 0);
    expect(state.skills['attack']!.experience, 0);

    final starterEncounter = find.byKey(
      const ValueKey<String>('combat-encounter-grave_rat'),
    );
    await tester.ensureVisible(starterEncounter);
    await tester.tap(starterEncounter);
    await tester.pump();

    expect(state.activeCombatSession?.encounterId, 'grave_rat');
    expect(state.gold, 0);
    expect(state.skills['attack']!.experience, 0);
    expect(find.text('ATIVO'), findsWidgets);
    expect(find.byKey(const ValueKey<String>('combat-stop')), findsOneWidget);

    currentTime = currentTime.add(const Duration(milliseconds: 3999));
    final incomplete = service.advanceTo(currentTime);
    expect(incomplete.hasRewards, isFalse);
    expect(state.gold, 0);
    expect(state.skills['attack']!.experience, 0);

    currentTime = currentTime.add(const Duration(milliseconds: 1));
    final completed = service.advanceTo(currentTime);
    expect(completed.completedVictories, 1);
    expect(completed.goldEarned, 2);
    expect(completed.damageTaken, 1);
    expect(state.gold, 2);
    expect(state.currentHealth, 99);
    expect(state.skills['attack']!.experience, 3);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'combat supports queue, locked enemies, stop and offline report',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime(2026, 8, 1, 12);
      final state = GameState();
      state.skills['attack'] = Skill(
        id: 'attack',
        name: 'Ataque',
        category: SkillCategory.combat,
        level: 10,
      );
      state.updateTotalLevel();
      final service = CombatService(
        onUpdate: (_, _) {},
        now: () => now,
        enableTimer: false,
      );
      service.initialize(state);
      addTearDown(service.dispose);

      final report = CombatAdvanceResult()
        ..completedVictories = 3
        ..goldEarned = 6
        ..damageTaken = 3
        ..experienceEarned = 9
        ..victoriesByEncounter['grave_rat'] = 3
        ..lootEarned['grave_dust'] = 2;
      var dismissed = false;

      await tester.pumpWidget(
        _combatApp(
          state: state,
          service: service,
          offlineReport: report,
          onDismiss: () => dismissed = true,
        ),
      );

      expect(find.text('RELATÓRIO DA CAÇADA'), findsOneWidget);
      expect(find.textContaining('3 vitórias'), findsOneWidget);
      expect(find.textContaining('+6 ouro'), findsOneWidget);
      expect(find.textContaining('+9 XP'), findsOneWidget);
      expect(find.text('Dano sofrido: -3 HP'), findsOneWidget);
      expect(find.text('Rato Sepulcral ×3'), findsOneWidget);
      expect(find.text('ESPÓLIOS ENCONTRADOS'), findsOneWidget);
      expect(find.text('Pó sepulcral ×2'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('combat-encounter-crypt_wolf')),
        findsOneWidget,
      );

      final graveRat = find.byKey(
        const ValueKey<String>('combat-encounter-grave_rat'),
      );
      await tester.ensureVisible(graveRat);
      await tester.tap(graveRat);
      await tester.pump();

      final cultist = find.byKey(
        const ValueKey<String>('combat-encounter-rune_cultist'),
      );
      await tester.ensureVisible(cultist);
      await tester.tap(cultist);
      await tester.pump();

      expect(state.activeCombatSession?.encounterId, 'grave_rat');
      expect(state.activeCombatSession?.queuedEncounterId, 'rune_cultist');
      expect(state.gold, 0);
      expect(find.text('PRÓXIMO'), findsOneWidget);

      final stop = find.byKey(const ValueKey<String>('combat-stop'));
      await tester.ensureVisible(stop);
      await tester.tap(stop);
      await tester.pump();
      expect(state.activeCombatSession, isNull);

      final dismissReport = find.byTooltip('Fechar relatório');
      await tester.ensureVisible(dismissReport);
      await tester.pump();
      await tester.tap(dismissReport);
      expect(dismissed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('player freely switches class paths on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = GameState();
    final service = CombatService(
      onUpdate: (_, _) {},
      now: () => DateTime(2026, 8, 1, 12),
      enableTimer: false,
    );
    service.initialize(state);
    addTearDown(service.dispose);
    var stateChanges = 0;

    await tester.pumpWidget(
      _combatApp(
        state: state,
        service: service,
        onStateChanged: () => stateChanges++,
      ),
    );

    expect(state.activeHeroClass, HeroClass.knight);
    expect(
      find.text('Troque livremente: nenhuma classe é permanente.'),
      findsOneWidget,
    );
    expect(find.text('Cavaleiro'), findsOneWidget);
    expect(find.text('Assassino'), findsOneWidget);
    expect(find.text('Mago'), findsOneWidget);
    expect(find.text('Arqueiro'), findsOneWidget);

    final assassin = find.byKey(
      const ValueKey<String>('combat-class-assassin'),
    );
    await tester.ensureVisible(assassin);
    await tester.tap(assassin);
    await tester.pump();

    expect(state.activeHeroClass, HeroClass.assassin);
    expect(stateChanges, 1);
    expect(find.textContaining('caminho Assassino'), findsOneWidget);

    final mage = find.byKey(const ValueKey<String>('combat-class-mage'));
    await tester.ensureVisible(mage);
    await tester.tap(mage);
    await tester.pump();

    expect(state.activeHeroClass, HeroClass.mage);
    expect(stateChanges, 2);
    expect(find.textContaining('caminho Mago'), findsOneWidget);

    final knight = find.byKey(const ValueKey<String>('combat-class-knight'));
    await tester.ensureVisible(knight);
    await tester.tap(knight);
    await tester.pump();

    expect(state.activeHeroClass, HeroClass.knight);
    expect(stateChanges, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('defeat disables encounters and exposes the zero-health state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = GameState()..currentHealth = 0;
    final service = CombatService(
      onUpdate: (_, _) {},
      now: () => DateTime(2026, 8, 1, 12),
      enableTimer: false,
    );
    service.initialize(state);
    addTearDown(service.dispose);

    await tester.pumpWidget(_combatApp(state: state, service: service));

    expect(
      find.byKey(const ValueKey<String>('combat-defeated-state')),
      findsOneWidget,
    );
    expect(find.text('DERROTADO'), findsWidgets);
    expect(find.text('0 / 100 HP'), findsWidgets);

    final encounter = find.byKey(
      const ValueKey<String>('combat-encounter-grave_rat'),
    );
    await tester.ensureVisible(encounter);
    await tester.tap(encounter);
    await tester.pump();

    expect(state.activeCombatSession, isNull);
    expect(find.text('SEM VIDA'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('global header reads the real current and maximum health', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = GameState()..currentHealth = 37;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(body: HeaderWidget(gameState: state)),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('global-health-stat')),
      findsOneWidget,
    );
    expect(find.text('37/100 HP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _combatApp({
  required GameState state,
  required CombatService service,
  CombatAdvanceResult? offlineReport,
  VoidCallback? onDismiss,
  VoidCallback? onStateChanged,
}) {
  return MaterialApp(
    theme: AppTheme.theme,
    home: Scaffold(
      body: CombatScreen(
        gameState: state,
        service: service,
        offlineReport: offlineReport,
        onDismissOfflineReport: onDismiss ?? () {},
        onStateChanged: onStateChanged ?? () {},
      ),
    ),
  );
}
