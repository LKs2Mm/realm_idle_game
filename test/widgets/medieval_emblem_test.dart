import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/core/theme/medieval_assets.dart';

void main() {
  testWidgets('applies a modulate tint filter only when tintColor is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MedievalEmblem(
            assetPath: MedievalAssets.crest,
            size: 32,
            tintColor: Color(0xFFC17A4A),
          ),
        ),
      ),
    );

    final filtered = tester.widget<ColorFiltered>(
      find.byType(ColorFiltered),
    );
    expect(
      filtered.colorFilter,
      const ColorFilter.mode(Color(0xFFC17A4A), BlendMode.modulate),
    );
  });

  testWidgets('renders without a color filter when untinted and not muted', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MedievalEmblem(assetPath: MedievalAssets.crest, size: 32),
        ),
      ),
    );

    expect(find.byType(ColorFiltered), findsNothing);
  });
}
