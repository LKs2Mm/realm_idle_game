import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/app/realm_idle_app.dart';
import 'package:realm_idle_game/services/storage_service.dart';
import 'package:realm_idle_game/widgets/skill_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'all six fixed navigation destinations contain playable content',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await StorageService.initialize();
      await tester.pumpWidget(const RealmIdleApp());
      await tester.pumpAndSettle();

      expect(find.text('HABILIDADES'), findsOneWidget);
      // Colheita não tem mais aba fixa: é alcançada pelos cards de
      // Habilidades, testado em 'tocar um card de perícia leva à tela
      // correspondente' abaixo.
      expect(find.text('Colheita'), findsNothing);

      await _openDestination(tester, 'Combate');
      expect(find.text('Combate'), findsWidgets);
      expect(find.text('Cavaleiro'), findsWidgets);

      await _openDestination(tester, 'Itens');
      expect(find.text('Itens'), findsWidgets);
      expect(find.text('Arsenal'), findsOneWidget);

      await _openDestination(tester, 'Mapas');
      expect(find.text('Mapas'), findsWidgets);
      expect(find.text('Encruzilhada das Cinzas'), findsOneWidget);

      await _openDestination(tester, 'Ferramentas');
      expect(find.text('Ferramentas'), findsWidgets);

      await _openDestination(tester, 'Conta');
      expect(find.text('Conta'), findsWidgets);
      expect(find.text('CAMINHOS DE BATALHA'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tocar um card de perícia leva à tela correspondente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await StorageService.initialize();
    await tester.pumpWidget(const RealmIdleApp());
    await tester.pumpAndSettle();

    final cookingCard = find.ancestor(
      of: find.text('Culinária'),
      matching: find.byType(SkillCard),
    );
    expect(cookingCard, findsOneWidget);
    await tester.tap(cookingCard);
    await tester.pumpAndSettle();

    expect(find.text('Itens'), findsWidgets);
    expect(find.text('Fundição'), findsOneWidget);
    expect(find.text('Culinária'), findsWidgets);

    await _openDestination(tester, 'Habilidades');

    final miningCard = find.ancestor(
      of: find.text('Mineração'),
      matching: find.byType(SkillCard),
    );
    expect(miningCard, findsOneWidget);
    await tester.tap(miningCard);
    await tester.pumpAndSettle();

    expect(find.text('Colheita'), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tocar a classe ativa no Combate abre o equipamento por peça sem trocar de tela',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await StorageService.initialize();
      await tester.pumpWidget(const RealmIdleApp());
      await tester.pumpAndSettle();

      await _openDestination(tester, 'Combate');
      final knight = find.byKey(const ValueKey<String>('combat-class-knight'));
      expect(knight, findsOneWidget);
      await tester.tap(knight);
      await tester.pumpAndSettle();

      // Ainda no Combate por baixo do modal, não navegou pra outra aba.
      expect(find.text('Combate'), findsWidgets);
      expect(find.text('Equipar Cavaleiro'), findsOneWidget);
      expect(find.text('Arsenal'), findsOneWidget);
      expect(find.text('Grimório'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Equipar Cavaleiro'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _openDestination(WidgetTester tester, String label) async {
  final destination = find.text(label).last;
  expect(destination, findsOneWidget);
  await tester.tap(destination);
  await tester.pumpAndSettle();
}
