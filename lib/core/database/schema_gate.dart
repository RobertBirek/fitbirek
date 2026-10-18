import 'package:drift/drift.dart';

/// An open RPC executor is not evidence that this client's migration ran.
class DatabaseSchemaMismatch extends StateError {
  DatabaseSchemaMismatch({required this.expected, required this.actual})
    : super('Database schema $actual; this client requires exactly $expected');

  final int expected;
  final int actual;
}

/// Preserve the remote stream store as well as guarding the executor. Applying
/// just QueryExecutor.interceptWith to a DatabaseConnection loses cross-tab
/// invalidations.
QueryExecutor guardDatabaseSchema(QueryExecutor executor) {
  final gate = _SchemaGate(
    executor is DatabaseConnection ? executor.executor : executor,
  );
  if (executor is DatabaseConnection) return executor.interceptWith(gate);
  return executor.interceptWith(gate);
}

class _SchemaGate extends QueryInterceptor {
  _SchemaGate(this.root);
  final QueryExecutor root;
  Future<bool>? _opening;
  bool _verified = false;
  (Object, StackTrace)? _failure;

  void _requireVerified() {
    if (_failure case (final error, final stack)?) {
      Error.throwWithStackTrace(error, stack);
    }
    if (!_verified) throw StateError('Database schema has not been verified');
  }

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) {
    if (!identical(executor, root)) {
      _requireVerified();
      return executor.ensureOpen(user);
    }
    if (_verified) return executor.ensureOpen(user);
    return _opening ??= _open(executor, user);
  }

  Future<bool> _open(QueryExecutor executor, QueryExecutorUser user) async {
    try {
      return await _verify(executor, user);
    } catch (error, stack) {
      _failure = (error, stack);
      rethrow;
    }
  }

  Future<bool> _verify(QueryExecutor executor, QueryExecutorUser user) async {
    final guardedUser = _SchemaUser(user);
    try {
      await executor.ensureOpen(guardedUser);
    } catch (_) {
      // RPC may wrap a local beforeOpen error in DriftRemoteException.
      if (guardedUser.mismatch case final mismatch?) throw mismatch;
      rethrow;
    }
    final rows = await executor.runSelect('PRAGMA user_version', const []);
    final actual = rows.single['user_version'] as int;
    if (actual != user.schemaVersion) {
      throw DatabaseSchemaMismatch(
        expected: user.schemaVersion,
        actual: actual,
      );
    }
    _verified = true;
    return true;
  }

  // Raw executor calls do not invoke ensureOpen. Guard them as well as nested
  // executors, including during an in-flight migration. Drift passes a separate
  // beforeOpen executor to _SchemaUser: only that scoped executor may run DDL
  // before verification, never this public wrapper or a caller-wide bypass.
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _requireVerified();
    return executor.runSelect(statement, args);
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _requireVerified();
    return executor.runCustom(statement, args);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _requireVerified();
    return executor.runInsert(statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _requireVerified();
    return executor.runUpdate(statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _requireVerified();
    return executor.runDelete(statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    _requireVerified();
    return executor.runBatched(statements);
  }

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    _requireVerified();
    return parent.beginTransaction();
  }

  @override
  QueryExecutor beginExclusive(QueryExecutor parent) {
    _requireVerified();
    return parent.beginExclusive();
  }
}

class _SchemaUser implements QueryExecutorUser {
  _SchemaUser(this.user);
  final QueryExecutorUser user;
  DatabaseSchemaMismatch? mismatch;
  @override
  int get schemaVersion => user.schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {
    final previous = details.versionBefore;
    // Drift otherwise invokes onUpgrade even for downgrades and then writes
    // this client's lower user_version. Never relabel a future database.
    if (previous != null && previous > schemaVersion) {
      throw mismatch = DatabaseSchemaMismatch(
        expected: schemaVersion,
        actual: previous,
      );
    }
    await user.beforeOpen(executor, details);
  }
}
