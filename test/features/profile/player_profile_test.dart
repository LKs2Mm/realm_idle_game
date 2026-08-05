import 'package:flutter_test/flutter_test.dart';
import 'package:realm_idle_game/features/profile/models/player_profile.dart';

void main() {
  test('normalizes profile names and titles', () {
    final profile = PlayerProfile();

    profile.rename('  Lysa   da   Névoa  ');
    profile.chooseTitle('  Herdeira   do Eclipse ');

    expect(profile.name, 'Lysa da Névoa');
    expect(profile.title, 'Herdeira do Eclipse');
  });

  test('profile safely round-trips chronicle counters', () {
    final profile = PlayerProfile(
      name: 'Cael',
      title: 'Portador da Runa',
      createdAt: 1234,
      totalVictories: 9,
      totalGatheringCycles: 20,
      totalCrafts: 3,
      potionsConsumed: 2,
      selectedRegionId: 'runic_depths',
    );

    final restored = PlayerProfile.fromJson(profile.toJson());

    expect(restored.name, 'Cael');
    expect(restored.title, 'Portador da Runa');
    expect(restored.createdAt, 1234);
    expect(restored.totalVictories, 9);
    expect(restored.totalGatheringCycles, 20);
    expect(restored.totalCrafts, 3);
    expect(restored.potionsConsumed, 2);
    expect(restored.selectedRegionId, 'runic_depths');
  });
}
