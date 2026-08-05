class PlayerProfile {
  String name;
  String title;
  int createdAt;
  int totalVictories;
  int totalGatheringCycles;
  int totalCrafts;
  int potionsConsumed;
  String selectedRegionId;

  PlayerProfile({
    this.name = 'Errante sem Nome',
    this.title = 'Marcado pelas Runas',
    int? createdAt,
    this.totalVictories = 0,
    this.totalGatheringCycles = 0,
    this.totalCrafts = 0,
    this.potionsConsumed = 0,
    this.selectedRegionId = 'ashen_crossroads',
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  void rename(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return;
    name = normalized.length > 24 ? normalized.substring(0, 24) : normalized;
  }

  void chooseTitle(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return;
    title = normalized.length > 32 ? normalized.substring(0, 32) : normalized;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'title': title,
    'createdAt': createdAt,
    'totalVictories': totalVictories,
    'totalGatheringCycles': totalGatheringCycles,
    'totalCrafts': totalCrafts,
    'potionsConsumed': potionsConsumed,
    'selectedRegionId': selectedRegionId,
  };

  factory PlayerProfile.fromJson(Object? json) {
    if (json is! Map) return PlayerProfile();
    final profile = PlayerProfile(
      name: _safeText(json['name'], fallback: 'Errante sem Nome', max: 24),
      title: _safeText(json['title'], fallback: 'Marcado pelas Runas', max: 32),
      createdAt: _safeInt(json['createdAt'], fallback: 0),
      totalVictories: _safeInt(json['totalVictories']),
      totalGatheringCycles: _safeInt(json['totalGatheringCycles']),
      totalCrafts: _safeInt(json['totalCrafts']),
      potionsConsumed: _safeInt(json['potionsConsumed']),
      selectedRegionId: _safeText(
        json['selectedRegionId'],
        fallback: 'ashen_crossroads',
        max: 48,
      ),
    );
    if (profile.createdAt <= 0) {
      profile.createdAt = DateTime.now().millisecondsSinceEpoch;
    }
    return profile;
  }

  static int _safeInt(Object? value, {int fallback = 0}) {
    if (value is! num || !value.isFinite) return fallback;
    return value.toInt().clamp(0, 9000000000000000);
  }

  static String _safeText(
    Object? value, {
    required String fallback,
    required int max,
  }) {
    if (value is! String) return fallback;
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return fallback;
    return normalized.length > max ? normalized.substring(0, max) : normalized;
  }
}
