import 'package:drift/drift.dart';
import '../models/set_role.dart';
import 'tables/workout_tables.dart';

/// Evidence only. Do not use for general history/backup queries.
Expression<bool> effectiveWorkingSets(SetsLog sets) =>
    sets.setRole.isNull() | sets.setRole.equals(SetRole.working);
