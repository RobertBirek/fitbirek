import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart' show FitnessTestResultData;
import '../../../../core/providers/database_provider.dart';
import '../data/tests_repository.dart';
import '../domain/fitness_protocol.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../../core/models/fitness_test.dart';
export '../data/tests_repository.dart' show FitnessWriteLease;

final testsRepositoryProvider = Provider<TestsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TestsRepository(
    db,
    authority: ref.watch(cachedAuthWriteAuthorityProvider),
  );
});

final allTestResultsProvider = StreamProvider<List<FitnessTestResultData>>((
  ref,
) {
  final repo = ref.watch(testsRepositoryProvider);
  return repo.watchAll();
});

final fitnessProtocolsProvider =
    StreamProvider.autoDispose<FitnessProtocolsView>(
      (ref) => ref.watch(testsRepositoryProvider).watchProtocols(),
    );
final customFitnessResultsProvider =
    StreamProvider.autoDispose<List<CustomFitnessResult>?>(
      (ref) => ref.watch(testsRepositoryProvider).watchCustomResults(),
    );
final legacyTestResultsProvider =
    StreamProvider.autoDispose<List<FitnessTestResultData>?>(
      (ref) => ref.watch(testsRepositoryProvider).watchLegacyResults(),
    );
final fitnessTestsWorkflowProvider = Provider<FitnessTestsWorkflow>(
  (ref) => FitnessTestsWorkflow(ref),
);

class FitnessTestsWorkflow {
  FitnessTestsWorkflow(Ref ref) : _repo = ref.read(testsRepositoryProvider) {
    ref.onDispose(() => _alive = false);
  }
  final TestsRepository _repo;
  bool _alive = true, _busy = false;
  Future<T> _run<T>(Future<T> Function() action) async {
    if (!_alive) throw StateError('Formularz jest zamknięty.');
    if (_busy) throw StateError('Zapis testu już trwa.');
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<FitnessWriteLease> captureLease({String? protocolId}) => _run(
    () => _repo.captureLease(protocolId: protocolId, isCurrent: () => _alive),
  );
  Future<void> validateLease(FitnessWriteLease lease) =>
      _run(() => _repo.validateLease(lease));
  Future<FitnessProtocol> createProtocol(
    FitnessWriteLease lease,
    FitnessProtocolDraft draft,
  ) => _run(() => _repo.createProtocol(lease, draft));
  Future<FitnessProtocol> reviseProtocol(
    FitnessWriteLease lease,
    FitnessProtocolDraft draft,
  ) => _run(() => _repo.reviseProtocol(lease, draft));
  Future<void> archiveProtocol(FitnessWriteLease lease) =>
      _run(() => _repo.archiveProtocol(lease));
  Future<void> addCustomResult(
    FitnessWriteLease lease, {
    required num value,
    required DateTime performedAt,
  }) => _run(
    () => _repo.addCustomResult(lease, value: value, performedAt: performedAt),
  );
  Future<void> addLegacyResult(
    FitnessWriteLease lease, {
    required TypTestu typ,
    required double value,
    required DateTime performedAt,
  }) => _run(
    () => _repo.addLegacyResult(
      lease,
      typ: typ,
      value: value,
      performedAt: performedAt,
    ),
  );
}
