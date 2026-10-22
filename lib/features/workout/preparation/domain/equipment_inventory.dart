/// Grams are exact on native and Web. Quantities refer to complete implements,
/// so a dumbbell pair shares four sides from one physical plate inventory.
enum LoadImplement {
  smallDumbbell('Małe uchwyty', 2250, 2),
  largeDumbbell('Duże uchwyty', 2500, 2),
  ezBar('Gryf łamany', 7000, 1),
  fixedDumbbell('Hantle stałe', 0, 2);

  const LoadImplement(this.label, this.baseGrams, this.availableQuantity);
  final String label;
  final int baseGrams, availableQuantity;
  bool get isDumbbell => this != ezBar;
}

/// Explicit configuration of the owner's private installation, not a claim
/// about every person's equipment or the mechanical capacity of their handles.
class EquipmentInventory {
  EquipmentInventory({
    required Map<int, int> plateCounts,
    Map<int, int> fixedDumbbells = const {1500: 2, 2000: 2},
    this.sandbagGrams,
  }) : plateCounts = _validated(plateCounts),
       fixedDumbbells = _validated(fixedDumbbells) {
    if (sandbagGrams != null && sandbagGrams! <= 0) {
      throw ArgumentError('Potwierdzona masa sandbaga musi być dodatnia.');
    }
  }

  factory EquipmentInventory.ownerConfirmed() => EquipmentInventory(
    plateCounts: const {5000: 4, 2500: 8, 1250: 10, 1000: 4, 500: 4},
    sandbagGrams: 20000,
  );

  final Map<int, int> plateCounts;
  final Map<int, int> fixedDumbbells;

  /// A confirmed complete resource, not plate stock or a historical performance.
  final int? sandbagGrams;

  int get plateMassGrams => plateCounts.entries.fold(
    0,
    (mass, entry) => mass + entry.key * entry.value,
  );

  static Map<int, int> _validated(Map<int, int> values) {
    if (values.entries.any((e) => e.key <= 0 || e.value < 0)) {
      throw ArgumentError('Masy muszą być dodatnie, liczności nieujemne.');
    }
    return Map.unmodifiable(values);
  }
}

class LoadAssembly {
  LoadAssembly({
    required this.implement,
    required this.quantity,
    required this.totalGramsPerImplement,
    required Map<int, int> platesPerSide,
  }) : platesPerSide = Map.unmodifiable(platesPerSide),
       inventoryUsed = Map.unmodifiable({
         for (final e in platesPerSide.entries) e.key: e.value * 2 * quantity,
       });

  final LoadImplement implement;
  final int quantity, totalGramsPerImplement;
  final Map<int, int> platesPerSide, inventoryUsed;

  int get plateCountPerSide =>
      platesPerSide.values.fold(0, (sum, count) => sum + count);
}

/// Exact, symmetric assemblies, ordered by fewest plates, then larger plates.
/// An empty result never implies rounding or a promise of physical fit.
List<LoadAssembly> assembleLoad({
  required EquipmentInventory inventory,
  required LoadImplement implement,
  required int targetGrams,
  required int quantity,
}) {
  if (quantity < 1 || quantity > 2 || targetGrams < 0) {
    throw ArgumentError('Wybierz jedną sztukę lub parę i nieujemną masę.');
  }
  if (quantity > implement.availableQuantity) return const [];
  if (implement == LoadImplement.fixedDumbbell) {
    return (inventory.fixedDumbbells[targetGrams] ?? 0) < quantity
        ? const []
        : List.unmodifiable([
            LoadAssembly(
              implement: implement,
              quantity: quantity,
              totalGramsPerImplement: targetGrams,
              platesPerSide: const {},
            ),
          ]);
  }
  final additional = targetGrams - implement.baseGrams;
  if (additional < 0 || additional.isOdd) return const [];
  final sides = 2 * quantity;
  final weights = inventory.plateCounts.keys.toList()
    ..sort((a, b) => b.compareTo(a));
  final counts = {
    for (final w in weights) w: inventory.plateCounts[w]! ~/ sides,
  };
  final remainingCapacity = List<int>.filled(weights.length + 1, 0);
  for (var i = weights.length - 1; i >= 0; i--) {
    remainingCapacity[i] =
        remainingCapacity[i + 1] + weights[i] * counts[weights[i]]!;
  }
  final result = <LoadAssembly>[];
  final chosen = <int, int>{};
  void visit(int index, int remaining) {
    if (remaining == 0) {
      result.add(
        LoadAssembly(
          implement: implement,
          quantity: quantity,
          totalGramsPerImplement: targetGrams,
          platesPerSide: chosen,
        ),
      );
      return;
    }
    if (index == weights.length || remaining > remainingCapacity[index]) return;
    final weight = weights[index];
    final maximum = (remaining ~/ weight) < counts[weight]!
        ? remaining ~/ weight
        : counts[weight]!;
    for (var n = maximum; n >= 0; n--) {
      if (n == 0) {
        chosen.remove(weight);
      } else {
        chosen[weight] = n;
      }
      visit(index + 1, remaining - weight * n);
    }
    chosen.remove(weight);
  }

  visit(0, additional ~/ 2);
  result.sort((a, b) {
    final count = a.plateCountPerSide.compareTo(b.plateCountPerSide);
    if (count != 0) return count;
    for (final weight in weights) {
      final order = (b.platesPerSide[weight] ?? 0).compareTo(
        a.platesPerSide[weight] ?? 0,
      );
      if (order != 0) return order;
    }
    return 0;
  });
  return List.unmodifiable(result);
}
