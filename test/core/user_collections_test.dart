import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/sync/user_collections.dart';

void main() {
  const id = '11111111-1111-4111-8111-111111111111';
  Map<String, dynamic> entry(String name, {bool deleted = false}) => {
    'id': id,
    'name': name,
    'createdAtUtc': '2026-10-17T10:00:00.000Z',
    'updatedAtUtc': '2026-10-17T10:00:00.000Z',
    if (deleted) 'deletedAtUtc': '2026-10-17T10:00:00.000Z',
    'filters': <String, dynamic>{},
  };
  Map<String, dynamic> collection(List<Map<String, dynamic>> entries) => {
    'version': 1,
    'entries': entries,
  };
  test('per-ID merge is commutative and retains deletion on timestamp tie', () {
    final a = collection([entry('A')]);
    final b = collection([entry('B', deleted: true)]);
    final merged = UserCollections.merge('filterPresets', a, b);
    expect(merged, UserCollections.merge('filterPresets', b, a));
    expect((merged['entries'] as List).single['deletedAtUtc'], isNotNull);
  });
  test(
    'different IDs survive and invalid collection cannot be silently pruned',
    () {
      final a = collection([entry('A')]);
      final other = entry('B')..['id'] = '22222222-2222-4222-8222-222222222222';
      expect(
        (UserCollections.merge(
              'filterPresets',
              a,
              collection([other]),
            )['entries']
            as List),
        hasLength(2),
      );
      expect(
        () => UserCollections.validate('filterPresets', {
          'version': 2,
          'entries': [],
        }),
        throwsFormatException,
      );
      expect(
        () => UserCollections.validate(
          'filterPresets',
          collection([entry('A'), entry('B')]),
        ),
        throwsFormatException,
      );
    },
  );
  test('canonical live tie is stable; entry limit includes tombstones', () {
    final a = collection([entry('A')]), b = collection([entry('B')]);
    expect(
      UserCollections.merge('filterPresets', a, b),
      UserCollections.merge('filterPresets', b, a),
    );
    final entries = List.generate(
      UserCollections.maxEntries + 1,
      (i) => entry('Deleted', deleted: true)
        ..['id'] =
            '${i.toRadixString(16).padLeft(8, '0')}-1111-4111-8111-111111111111',
    );
    expect(
      () => UserCollections.validate('filterPresets', collection(entries)),
      throwsFormatException,
    );
    expect(
      () => UserCollections.merge(
        'filterPresets',
        collection(entries.take(500).toList()),
        collection([entries.last]),
      ),
      throwsFormatException,
    );
  });
}
