import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/gathering/models/gathering_resource.dart';

void main() {
  group('GatheringResource catalog', () {
    test('keeps resource identifiers unique', () {
      final ids = GatheringResource.all.map((resource) => resource.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
    });

    test('adds coal as an early mining fuel', () {
      final coal = GatheringResource.byId('coal');

      expect(coal, isNotNull);
      expect(coal!.discipline, GatheringDiscipline.mining);
      expect(coal.name, 'Carvão mineral');
      expect(coal.requiredLevel, 5);
      expect(coal.cycleSeconds, 4);
      expect(coal.experiencePerCycle, 6.8);
      expect(coal.baseQuantity, 1);
      expect(coal.description.toLowerCase(), contains('combustível'));
      expect(coal.description.toLowerCase(), contains('forjas'));
    });

    test('defines exactly ten progressively unlocked fishing catches', () {
      final resources = GatheringResource.forDiscipline(
        GatheringDiscipline.fishing,
      );

      expect(resources, hasLength(10));
      expect(resources.map((resource) => resource.id), [
        'shrimp',
        'sardine',
        'trout',
        'salmon',
        'tuna',
        'lobster',
        'swordfish',
        'shark',
        'abyssal_eel',
        'runic_leviathan',
      ]);
      expect(resources.map((resource) => resource.requiredLevel), [
        1,
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        90,
      ]);
      expect(resources.map((resource) => resource.cycleSeconds), [
        3,
        4,
        5,
        7,
        9,
        12,
        16,
        21,
        27,
        34,
      ]);
      expect(resources.map((resource) => resource.experiencePerCycle), [
        10,
        14,
        18.5,
        27.3,
        36.9,
        51.6,
        72,
        98.7,
        132.3,
        173.4,
      ]);

      for (var index = 1; index < resources.length; index++) {
        expect(
          resources[index].cycleSeconds,
          greaterThan(resources[index - 1].cycleSeconds),
          reason: resources[index].id,
        );
        expect(
          resources[index].experiencePerCycle,
          greaterThan(resources[index - 1].experiencePerCycle),
          reason: resources[index].id,
        );
        expect(
          resources[index].experiencePerCycle / resources[index].cycleSeconds,
          greaterThan(
            resources[index - 1].experiencePerCycle /
                resources[index - 1].cycleSeconds,
          ),
          reason: '${resources[index].id} XP/s',
        );
      }
    });

    test('ends fishing progression with dark and runic creatures', () {
      final abyssalEel = GatheringResource.byId('abyssal_eel');
      final runicLeviathan = GatheringResource.byId('runic_leviathan');

      expect(abyssalEel, isNotNull);
      expect(abyssalEel!.requiredLevel, 80);
      expect(abyssalEel.description.toLowerCase(), contains('abismo'));
      expect(runicLeviathan, isNotNull);
      expect(runicLeviathan!.requiredLevel, 90);
      expect(runicLeviathan.description.toLowerCase(), contains('runas'));
    });
  });
}
