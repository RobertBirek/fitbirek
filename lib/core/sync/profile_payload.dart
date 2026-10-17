import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'user_collections.dart';

/// syncVersion is an observed watermark, not proof that deferred fields were
/// applied. A local snapshot with an unapplied remote record must go through
/// CAS again. Using a conservative older base needs no new schema/metadata and
/// is safe across restart, coalescing and old deferred records.
Future<int> profileWriteBaseVersion(
  AppDatabase db,
  String id,
  int observed,
) async {
  final deferred =
      await (db.select(db.syncDeferredRecords)..where(
            (r) => r.entityType.equals('profile') & r.entityId.equals(id),
          ))
          .getSingleOrNull();
  if (deferred != null && observed >= deferred.version) {
    return deferred.version - 1;
  }
  return observed;
}

Map<String, dynamic> profilePayload(UserProfileData row) {
  final json = Map<String, dynamic>.from(row.toJson());
  for (final key in [
    'id',
    'syncId',
    'syncVersion',
    'updatedAtUtc',
    'deletedAtUtc',
  ]) {
    json.remove(key);
  }
  json['dataUtworzenia'] = row.dataUtworzenia.toUtc().toIso8601String();
  json['dostepnySprzet'] = jsonDecode(row.dostepnySprzet);
  UserCollections.columnsToWire(json);
  return json;
}
