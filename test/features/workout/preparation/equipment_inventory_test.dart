import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/workout/preparation/domain/equipment_inventory.dart';

void main() {
  final owner = EquipmentInventory.ownerConfirmed();
  List<LoadAssembly> assemble(
    int grams, {
    EquipmentInventory? inventory,
    LoadImplement implement = LoadImplement.smallDumbbell,
    int quantity = 2,
  }) => assembleLoad(
    inventory: inventory ?? owner,
    implement: implement,
    targetGrams: grams,
    quantity: quantity,
  );

  test('confirmed shared stock contains 30 plates with total mass 58500g', () {
    expect(owner.plateCounts, {5000: 4, 2500: 8, 1250: 10, 1000: 4, 500: 4});
    expect(owner.plateCounts.values.fold<int>(0, (a, b) => a + b), 30);
    expect(owner.plateMassGrams, 58500);
  });

  test('pair7250 requires four2500 plates, not two independently reused', () {
    final result = assemble(7250).first;
    expect(result.totalGramsPerImplement, 7250);
    expect(result.quantity, 2);
    expect(result.platesPerSide, {2500: 1});
    expect(result.inventoryUsed, {2500: 4});
  });

  test('pair8250 uses four2500 and four500 from a controlled shared stock', () {
    final stock = EquipmentInventory(plateCounts: {2500: 4, 500: 4});
    final result = assemble(8250, inventory: stock).single;
    expect(result.platesPerSide, {2500: 1, 500: 1});
    expect(result.inventoryUsed, {2500: 4, 500: 4});
    expect(
      assemble(
        8250,
        inventory: EquipmentInventory(plateCounts: {2500: 4, 500: 2}),
      ),
      isEmpty,
    );
  });

  test('single dumbbell may use two500 plates that cannot serve a pair', () {
    final stock = EquipmentInventory(plateCounts: {500: 2});
    expect(assemble(3250, inventory: stock), isEmpty);
    expect(assemble(3250, inventory: stock, quantity: 1).single.inventoryUsed, {
      500: 2,
    });
  });

  test('never silently rounds an unreachable target7300', () {
    expect(assemble(7300), isEmpty);
    expect(assemble(7750), isNotEmpty);
  });

  test('bare handles and EZ retain their own masses', () {
    expect(assemble(2250).single.platesPerSide, isEmpty);
    expect(
      assemble(
        2500,
        implement: LoadImplement.largeDumbbell,
      ).single.platesPerSide,
      isEmpty,
    );
    expect(
      assemble(
        7000,
        implement: LoadImplement.ezBar,
        quantity: 1,
      ).single.platesPerSide,
      isEmpty,
    );
    expect(assemble(7000, implement: LoadImplement.ezBar), isEmpty);
    expect(assemble(2000), isEmpty);
  });

  test('fixed dumbbells are1500 and2000, never the visually misread5000', () {
    for (final grams in [1500, 2000]) {
      final result = assemble(
        grams,
        implement: LoadImplement.fixedDumbbell,
      ).single;
      expect(result.totalGramsPerImplement, grams);
      expect(result.inventoryUsed, isEmpty);
    }
    expect(assemble(5000, implement: LoadImplement.fixedDumbbell), isEmpty);
  });

  test('EZ17000 uses two5000 plates including its7000g bar', () {
    final result = assemble(
      17000,
      implement: LoadImplement.ezBar,
      quantity: 1,
    ).first;
    expect(result.platesPerSide, {5000: 1});
    expect(result.inventoryUsed, {5000: 2});
  });

  test(
    'fewest plates preferred and returned configurations remain deterministic',
    () {
      final first = assemble(7250);
      final again = assemble(7250);
      expect(first.first.platesPerSide, {2500: 1});
      expect(
        first.map((r) => r.platesPerSide).toList(),
        again.map((r) => r.platesPerSide).toList(),
      );
      for (final result in first) {
        var perSide = 0;
        for (final entry in result.platesPerSide.entries) {
          perSide += entry.key * entry.value;
          expect(result.inventoryUsed[entry.key], entry.value * 4);
          expect(
            result.inventoryUsed[entry.key]! <= owner.plateCounts[entry.key]!,
            isTrue,
          );
        }
        expect(2250 + 2 * perSide, 7250);
      }
    },
  );

  test(
    'inventory and assembly maps cannot be mutated through retained aliases',
    () {
      final raw = {2500: 4};
      final stock = EquipmentInventory(plateCounts: raw);
      raw[2500] = 0;
      final result = assemble(7250, inventory: stock).single;
      expect(result.inventoryUsed, {2500: 4});
      expect(() => stock.plateCounts[2500] = 0, throwsUnsupportedError);
      expect(() => result.platesPerSide[2500] = 2, throwsUnsupportedError);
    },
  );

  test('invalid quantities and negative stock fail explicitly', () {
    expect(() => assemble(7250, quantity: 0), throwsArgumentError);
    expect(() => assemble(-1), throwsArgumentError);
    expect(
      () => EquipmentInventory(plateCounts: {500: -1}),
      throwsArgumentError,
    );
    expect(assemble(1000000000), isEmpty);
  });
}
