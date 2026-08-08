import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/widgets/onboarding_overlay.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    required VoidCallback onFinished,
  }) {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(body: OnboardingOverlay(onFinished: onFinished)),
      ),
    );
  }

  testWidgets('walks through all four steps and finishes on the last one', (
    tester,
  ) async {
    var finished = 0;
    await pumpOverlay(tester, onFinished: () => finished++);

    expect(find.text('Bem-vindo(a) a Realm Idle'), findsOneWidget);

    final next = find.byKey(const ValueKey<String>('onboarding-next'));
    expect(tester.widget<ElevatedButton>(next).child, isA<Text>());

    for (final title in ['Colheita', 'Combate', 'Itens']) {
      await tester.tap(next);
      await tester.pump();
      expect(find.text(title), findsOneWidget);
      expect(finished, 0);
    }

    final lastButtonText = tester.widget<Text>(
      find.descendant(of: next, matching: find.byType(Text)),
    );
    expect(lastButtonText.data, 'Começar jornada');

    await tester.tap(next);
    await tester.pump();
    expect(finished, 1);
  });

  testWidgets('skip finishes immediately from the first step', (
    tester,
  ) async {
    var finished = 0;
    await pumpOverlay(tester, onFinished: () => finished++);

    await tester.tap(find.byKey(const ValueKey<String>('onboarding-skip')));
    await tester.pump();

    expect(finished, 1);
    expect(tester.takeException(), isNull);
  });
}
