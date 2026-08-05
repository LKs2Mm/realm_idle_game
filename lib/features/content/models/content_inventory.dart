class ContentInventory {
  final Map<String, int> consumables;
  final Map<String, int> spells;

  ContentInventory({Map<String, int>? consumables, Map<String, int>? spells})
    : consumables = _sanitizedCopy(consumables),
      spells = _sanitizedCopy(spells);

  int quantityOfConsumable(String itemId) => consumables[itemId] ?? 0;
  int quantityOfSpell(String spellId) => spells[spellId] ?? 0;

  int get totalConsumables =>
      consumables.values.fold(0, (sum, value) => sum + value);
  int get totalSpells => spells.values.fold(0, (sum, value) => sum + value);

  void addConsumable(String itemId, [int quantity = 1]) {
    _add(consumables, itemId, quantity);
  }

  void addSpell(String spellId, [int quantity = 1]) {
    _add(spells, spellId, quantity);
  }

  bool tryConsumeConsumable(String itemId, [int quantity = 1]) {
    return _tryConsume(consumables, itemId, quantity);
  }

  bool tryConsumeSpell(String spellId, [int quantity = 1]) {
    return _tryConsume(spells, spellId, quantity);
  }

  Map<String, dynamic> toJson() => {
    'consumables': Map<String, int>.from(consumables),
    'spells': Map<String, int>.from(spells),
  };

  factory ContentInventory.fromJson(Object? json) {
    if (json is! Map) return ContentInventory();
    return ContentInventory(
      consumables: _readQuantities(json['consumables']),
      spells: _readQuantities(json['spells']),
    );
  }

  static Map<String, int> _sanitizedCopy(Map<String, int>? source) {
    if (source == null) return {};
    return {
      for (final entry in source.entries)
        if (entry.key.isNotEmpty && entry.value > 0) entry.key: entry.value,
    };
  }

  static Map<String, int> _readQuantities(Object? json) {
    if (json is! Map) return {};
    final result = <String, int>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (entry.key is String &&
          (entry.key as String).isNotEmpty &&
          value is num &&
          value.isFinite &&
          value > 0) {
        result[entry.key as String] = value.toInt();
      }
    }
    return result;
  }

  static void _add(Map<String, int> target, String id, int quantity) {
    if (id.isEmpty || quantity <= 0) return;
    target[id] = (target[id] ?? 0) + quantity;
  }

  static bool _tryConsume(Map<String, int> target, String id, int quantity) {
    if (id.isEmpty || quantity <= 0 || (target[id] ?? 0) < quantity) {
      return false;
    }
    final remaining = target[id]! - quantity;
    if (remaining == 0) {
      target.remove(id);
    } else {
      target[id] = remaining;
    }
    return true;
  }
}
