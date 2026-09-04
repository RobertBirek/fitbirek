import 'package:drift/drift.dart';

/// Stub dla platform nieobsługiwanych przez żadną z implementacji connection.
QueryExecutor openConnection() {
  throw UnsupportedError('Nieobsługiwana platforma dla bazy FitBirek.');
}
