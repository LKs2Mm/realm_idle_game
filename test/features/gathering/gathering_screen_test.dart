import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/runic_ornaments.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';
import 'package:realm_idle_game/features/gathering/screens/gathering_screen.dart';
import 'package:realm_idle_game/features/gathering/services/gathering_service.dart';
import 'package:realm_idle_game/models/game_state.dart';

void main() {
  testWidgets('gathering selection starts automation without click XP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = GameState();
    final service = GatheringService(onUpdate: (_, _) {}, enableTimer: false);
    service.initialize(state);
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GatheringScreen(
            gameState: state,
            service: service,
            offlineReport: null,
            onDismissOfflineReport: () {},
          ),
        ),
      ),
    );

    expect(find.text('Mineração'), findsWidgets);
    expect(find.text('Corte de madeira'), findsOneWidget);
    expect(find.text('Pesca'), findsOneWidget);
    expect(find.text('Minério de cobre'), findsOneWidget);
    expect(find.text('+5,6 XP'), findsOneWidget);
    expect(find.text('Essência rúnica'), findsOneWidget);
    expect(find.text('+1,3 XP'), findsOneWidget);
    expect(find.byType(RunicDivider), findsOneWidget);
    expect(find.byType(RunicFrame), findsWidgets);

    await tester.tap(find.text('Minério de cobre'));
    await tester.pump();

    expect(state.activeGatheringSession?.resourceId, 'copper');
    expect(state.skills['mining']!.experience, 0);
    expect(find.text('ATIVO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'explicit initialDiscipline wins over an already-active session',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = GameState();
      final service = GatheringService(
        onUpdate: (_, _) {},
        enableTimer: false,
      );
      service.initialize(state);
      service.selectResource('copper');
      addTearDown(service.dispose);

      // Player is actively mining, but navigates straight to Pesca (e.g. by
      // tapping the Pesca skill card) — the destination they picked must
      // win, not the discipline of the session already running.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatheringScreen(
              gameState: state,
              service: service,
              offlineReport: null,
              onDismissOfflineReport: () {},
              initialDiscipline: GatheringDiscipline.fishing,
            ),
          ),
        ),
      );

      // The resource list must show Pesca's resources (Camarão), not the
      // Mineração ones — "Minério de cobre" is still expected twice, but
      // only from the always-on active-activity banner (title + "Próximo
      // ciclo"), not from a Mineração resource list.
      expect(find.text('Camarão'), findsOneWidget);
      expect(find.text('Minério de cobre'), findsNWidgets(2));
    },
  );

  testWidgets('cycle progress stays continuous across one-second updates', (
    tester,
  ) async {
    var currentTime = DateTime(2026, 8, 1, 12);
    final state = GameState();
    final service = GatheringService(
      onUpdate: (_, _) {},
      now: () => currentTime,
      enableTimer: false,
    );
    service.initialize(state);
    service.selectResource('copper');
    addTearDown(service.dispose);

    Widget buildGame() => MaterialApp(
      home: Scaffold(
        body: GatheringScreen(
          gameState: state,
          service: service,
          offlineReport: null,
          onDismissOfflineReport: () {},
        ),
      ),
    );

    final cycleBar = find.byWidgetPredicate(
      (widget) => widget is LinearProgressIndicator && widget.minHeight == 9,
    );
    double cycleProgress() =>
        tester.widget<LinearProgressIndicator>(cycleBar).value!;

    await tester.pumpWidget(buildGame());
    await tester.pump(const Duration(milliseconds: 900));
    final beforeServiceUpdate = cycleProgress();
    expect(beforeServiceUpdate, closeTo(0.3, 0.02));

    currentTime = currentTime.add(const Duration(seconds: 1));
    service.advanceTo(currentTime);
    await tester.pumpWidget(buildGame());
    final afterServiceUpdate = cycleProgress();
    expect(afterServiceUpdate, greaterThanOrEqualTo(beforeServiceUpdate));

    await tester.pump(const Duration(milliseconds: 600));
    expect(cycleProgress(), closeTo(0.5, 0.02));

    await tester.pump(const Duration(seconds: 3));
  });
}
