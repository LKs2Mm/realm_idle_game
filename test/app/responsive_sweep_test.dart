import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/app/realm_idle_app.dart';
import 'package:realm_idle_game/services/storage_service.dart';
import 'package:realm_idle_game/widgets/skill_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Varredura de responsividade: navega por todas as telas principais numa
/// faixa de tamanhos de tela real (celular pequeno até tablet grande),
/// checando que nenhuma tela produz overflow ou outra exceção de layout.
/// Não valida visual/estética, só que o layout não quebra.
void main() {
  const sizes = <String, Size>{
    'celular muito estreito (300w)': Size(300, 700),
    'iPhone SE 1ª geração (320w)': Size(320, 700),
    'celular Android compacto (375w)': Size(375, 812),
    'celular Android padrão (393w)': Size(393, 851),
    'tablet pequeno / breakpoint Material (600w)': Size(600, 960),
    'iPad retrato (768w)': Size(768, 1024),
    'iPad paisagem (1024w)': Size(1024, 768),
  };

  for (final entry in sizes.entries) {
    testWidgets('todas as telas renderizam sem overflow em ${entry.key}', (
      tester,
    ) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await StorageService.initialize();
      await tester.pumpWidget(const RealmIdleApp());
      await tester.pumpAndSettle();
      await _skipOnboarding(tester);

      expect(find.text('HABILIDADES'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final miningCard = find.ancestor(
        of: find.text('Mineração'),
        matching: find.byType(SkillCard),
      );
      expect(miningCard, findsOneWidget);
      await tester.ensureVisible(miningCard);
      await tester.pumpAndSettle();
      await tester.tap(miningCard);
      await tester.pumpAndSettle();
      expect(find.text('Colheita'), findsWidgets);
      expect(tester.takeException(), isNull);

      await _openDestination(tester, 'Habilidades');
      for (final destination in [
        'Combate',
        'Itens',
        'Mapas',
        'Ferramentas',
        'Conta',
      ]) {
        await _openDestination(tester, destination);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'abas internas de Colheita/Itens/Ferramentas não estouram na largura '
    'mais estreita (300w)',
    (tester) async {
      tester.view.physicalSize = const Size(300, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      await StorageService.initialize();
      await tester.pumpWidget(const RealmIdleApp());
      await tester.pumpAndSettle();
      await _skipOnboarding(tester);

      final miningCard = find.ancestor(
        of: find.text('Mineração'),
        matching: find.byType(SkillCard),
      );
      await tester.ensureVisible(miningCard);
      await tester.pumpAndSettle();
      await tester.tap(miningCard);
      await tester.pumpAndSettle();
      for (final discipline in ['Corte de madeira', 'Pesca', 'Mineração']) {
        await tester.tap(find.text(discipline));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await _openDestination(tester, 'Habilidades');
      await _openDestination(tester, 'Itens');
      for (final tabKey in [
        'items-tab-equipped',
        'items-tab-arsenal',
        'items-tab-workshops',
        'items-tab-alchemy',
        'items-tab-grimoire',
        'items-tab-processing',
        'items-tab-materials',
      ]) {
        final tab = find.byKey(ValueKey<String>(tabKey));
        await tester.ensureVisible(tab);
        await tester.pumpAndSettle();
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tabKey);
      }

      await _openDestination(tester, 'Ferramentas');
      for (final toolLabel in ['Machados', 'Varas', 'Picaretas']) {
        await tester.tap(find.text(toolLabel));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}

Future<void> _openDestination(WidgetTester tester, String label) async {
  final destination = find.text(label).last;
  expect(destination, findsOneWidget);
  await tester.tap(destination);
  await tester.pumpAndSettle();
}

Future<void> _skipOnboarding(WidgetTester tester) async {
  final skip = find.byKey(const ValueKey<String>('onboarding-skip'));
  if (skip.evaluate().isEmpty) return;
  await tester.tap(skip);
  await tester.pumpAndSettle();
}
