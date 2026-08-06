import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/app_theme.dart';
import 'package:realm_idle_game/features/equipment/models/equipment_models.dart';
import 'package:realm_idle_game/screens/account_screen.dart';

void main() {
  testWidgets('account edits identity and exposes all class and save actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? changedName;
    String? changedTitle;
    var saveRequests = 0;
    var identityRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: AccountScreen(
            characterName: 'Aldren',
            characterTitle: 'Sem título',
            saveId: 'realm-7F2A',
            createdAtLabel: '01/08/2026',
            lastSavedAtLabel: 'agora',
            classStats: HeroClass.values
                .map(
                  (heroClass) => AccountClassStats(
                    heroClass: heroClass,
                    level: heroClass.index + 1,
                    victories: heroClass.index * 3,
                    power: 10 + heroClass.index,
                  ),
                )
                .toList(),
            chronicle: const [
              AccountChronicleEntry(
                id: 'awakening',
                title: 'O Despertar',
                description: 'A primeira runa respondeu ao chamado.',
                dateLabel: 'Hoje',
              ),
            ],
            onProfileChanged: (name, title) {
              changedName = name;
              changedTitle = title;
            },
            onSaveRequested: () => saveRequests++,
            onIdentityRequested: () => identityRequests++,
          ),
        ),
      ),
    );

    expect(find.text('Conta'), findsOneWidget);
    expect(find.text('Cavaleiro'), findsOneWidget);
    expect(find.text('Assassino'), findsOneWidget);
    expect(find.text('Mago'), findsOneWidget);
    expect(find.text('Arqueiro'), findsOneWidget);
    expect(find.text('O Despertar'), findsOneWidget);

    final nameField = find.byKey(const ValueKey<String>('account-name-field'));
    final titleField = find.byKey(
      const ValueKey<String>('account-title-field'),
    );
    await tester.enterText(nameField, 'Lyra');
    await tester.enterText(titleField, 'A Rúnica');
    await tester.tap(
      find.byKey(const ValueKey<String>('account-save-profile')),
    );
    await tester.pump();

    expect(changedName, 'Lyra');
    expect(changedTitle, 'A Rúnica');

    final save = find.byKey(const ValueKey<String>('account-save-now'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    final identity = find.byKey(
      const ValueKey<String>('account-copy-identity'),
    );
    await tester.ensureVisible(identity);
    await tester.tap(identity);

    expect(saveRequests, 1);
    expect(identityRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows the empty chronicle placeholder and defaults missing class stats',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: Scaffold(
            body: AccountScreen(
              characterName: 'Aldren',
              characterTitle: 'Sem título',
              saveId: 'realm-7F2A',
              createdAtLabel: '01/08/2026',
              lastSavedAtLabel: 'agora',
              classStats: const [
                AccountClassStats(
                  heroClass: HeroClass.knight,
                  level: 5,
                  victories: 9,
                  power: 40,
                ),
              ],
              chronicle: const [],
              onProfileChanged: (_, _) {},
              onSaveRequested: () {},
              onIdentityRequested: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('A crônica ainda aguarda seu primeiro grande feito.'),
        findsOneWidget,
      );

      final archerCard = find.byKey(
        const ValueKey<String>('account-class-archer'),
      );
      expect(
        find.descendant(
          of: archerCard,
          matching: find.text('Nível: 1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: archerCard,
          matching: find.text('Vitórias: 0'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: archerCard, matching: find.text('Poder: 0')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('falls back to the previous name and title when fields are blank', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? changedName;
    String? changedTitle;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: AccountScreen(
            characterName: 'Aldren',
            characterTitle: 'Sem título',
            saveId: 'realm-7F2A',
            createdAtLabel: '01/08/2026',
            lastSavedAtLabel: 'agora',
            classStats: const [],
            chronicle: const [],
            onProfileChanged: (name, title) {
              changedName = name;
              changedTitle = title;
            },
            onSaveRequested: () {},
            onIdentityRequested: () {},
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('account-name-field')),
      '   ',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('account-title-field')),
      '   ',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('account-save-profile')),
    );
    await tester.pump();

    expect(changedName, 'Aldren');
    expect(changedTitle, 'Sem título');
    expect(tester.takeException(), isNull);
  });

  testWidgets('syncs the name and title fields when the parent updates them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget buildScreen(String name, String title) => MaterialApp(
      theme: AppTheme.theme,
      home: Scaffold(
        body: AccountScreen(
          characterName: name,
          characterTitle: title,
          saveId: 'realm-7F2A',
          createdAtLabel: '01/08/2026',
          lastSavedAtLabel: 'agora',
          classStats: const [],
          chronicle: const [],
          onProfileChanged: (_, _) {},
          onSaveRequested: () {},
          onIdentityRequested: () {},
        ),
      ),
    );

    await tester.pumpWidget(buildScreen('Aldren', 'Sem título'));
    await tester.pumpWidget(buildScreen('Lyra', 'A Rúnica'));

    final nameField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('account-name-field')),
    );
    final titleField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('account-title-field')),
    );
    expect(nameField.controller?.text, 'Lyra');
    expect(titleField.controller?.text, 'A Rúnica');
    expect(tester.takeException(), isNull);
  });
}
