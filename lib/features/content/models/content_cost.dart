class ContentCost {
  final Map<String, int> materials;

  const ContentCost(this.materials);

  int quantityOf(String itemId) => materials[itemId] ?? 0;

  int get totalUnits => materials.values.fold(0, (sum, value) => sum + value);

  bool get isEmpty => materials.values.every((quantity) => quantity <= 0);

  bool canAfford(Map<String, int> inventory) {
    for (final entry in materials.entries) {
      if (entry.value <= 0 || (inventory[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }
    return true;
  }
}
