import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../data/filter_presets_repository.dart';
import '../domain/exercise_filter_engine.dart';
import '../domain/filter_preset.dart';

/// Local durable auth binding only. Do not watch authStateProvider here: its
/// construction bootstraps an HTTP session even when restoring offline presets.
final filterPresetsAccountProvider = StreamProvider<String?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db
      .select(db.syncState)
      .watchSingleOrNull()
      .map(
        (row) => row != null && row.offlineAccess && row.accountId.isNotEmpty
            ? row.accountId
            : null,
      )
      .distinct();
});

final filterPresetsRepositoryProvider = Provider<FilterPresetsRepository>(
  (ref) => FilterPresetsRepository(),
);

final filterPresetsProvider =
    StateNotifierProvider<
      FilterPresetsController,
      AsyncValue<List<FilterPreset>>
    >((ref) {
      final binding = ref.watch(filterPresetsAccountProvider);
      final account = binding.isLoading || binding.hasError
          ? null
          : binding.valueOrNull;
      return FilterPresetsController(
        ref.watch(filterPresetsRepositoryProvider),
        account,
      );
    });

class FilterPresetsController
    extends StateNotifier<AsyncValue<List<FilterPreset>>> {
  FilterPresetsController(this._repository, this.accountId)
    : super(accountId == null ? const AsyncData([]) : const AsyncLoading()) {
    if (accountId != null) _load();
  }
  final FilterPresetsRepository _repository;
  final String? accountId;
  int _revision = 0;
  bool get _current => mounted && accountId != null;

  Future<void> _load() async {
    final revision = _revision;
    try {
      final items = await _repository.load(
        accountId!,
        isCurrent: () => _current,
      );
      if (_current && revision == _revision) state = AsyncData(items);
    } catch (e, st) {
      if (_current && revision == _revision) state = AsyncError(e, st);
    }
  }

  String _account() {
    if (!_current) throw StateError('Brak aktywnego konta.');
    return accountId!;
  }

  Future<void> save(
    String name,
    ExerciseFilters filters, {
    String? overwriteId,
  }) async {
    final account = _account();
    ++_revision;
    await _repository.save(
      account,
      name,
      filters,
      overwriteId: overwriteId,
      isCurrent: () => _current,
    );
    if (!_current) throw StateError('Konto zostało zmienione.');
    await _load();
  }

  Future<void> delete(String id) async {
    final account = _account();
    ++_revision;
    await _repository.delete(account, id, isCurrent: () => _current);
    if (!_current) throw StateError('Konto zostało zmienione.');
    await _load();
  }

  ExerciseFilters apply(String id) {
    _account();
    return state.requireValue.firstWhere((p) => p.id == id).filters;
  }
}
