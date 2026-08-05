import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_inventory.dart';

void main() {
  group('GatheringInventory.trySpend', () {
    test('spends the complete recipe and removes empty stacks', () {
      final inventory = GatheringInventory(
        resources: {'iron': 8, 'normal_log': 12},
      );

      final spent = inventory.trySpend({'iron': 3, 'normal_log': 12});

      expect(spent, isTrue);
      expect(inventory.resources, {'iron': 5});
    });

    test('is atomic when any recipe ingredient is missing', () {
      final inventory = GatheringInventory(
        resources: {'iron': 8, 'normal_log': 11},
      );
      final before = Map<String, int>.from(inventory.resources);

      final spent = inventory.trySpend({'iron': 3, 'normal_log': 12});

      expect(spent, isFalse);
      expect(inventory.resources, before);
    });

    test('rejects a negative recipe without changing inventory', () {
      final inventory = GatheringInventory(resources: {'iron': 8});
      final before = Map<String, int>.from(inventory.resources);

      final spent = inventory.trySpend({'iron': -1});

      expect(spent, isFalse);
      expect(inventory.resources, before);
    });
  });
}
