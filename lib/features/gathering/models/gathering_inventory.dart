class GatheringInventory {
  final Map<String, int> resources;

  GatheringInventory({Map<String, int>? resources})
    : resources = resources ?? {};

  void add(String resourceId, int quantity) {
    if (quantity <= 0) return;
    resources[resourceId] = quantityOf(resourceId) + quantity;
  }

  int quantityOf(String resourceId) => resources[resourceId] ?? 0;

  bool containsAll(Map<String, int> cost) {
    for (final entry in cost.entries) {
      if (entry.value < 0 || quantityOf(entry.key) < entry.value) return false;
    }
    return true;
  }

  bool trySpend(Map<String, int> cost) {
    if (!containsAll(cost)) return false;

    for (final entry in cost.entries) {
      if (entry.value <= 0) continue;
      final remaining = quantityOf(entry.key) - entry.value;
      if (remaining == 0) {
        resources.remove(entry.key);
      } else {
        resources[entry.key] = remaining;
      }
    }
    return true;
  }

  int get totalCount => resources.values.fold(0, (sum, value) => sum + value);

  Map<String, int> toJson() => Map<String, int>.from(resources);

  factory GatheringInventory.fromJson(Object? json) {
    if (json is! Map) return GatheringInventory();

    final resources = <String, int>{};
    for (final entry in json.entries) {
      final value = entry.value;
      if (entry.key is String && value is num && value > 0) {
        resources[entry.key as String] = value.toInt();
      }
    }
    return GatheringInventory(resources: resources);
  }
}
