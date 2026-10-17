import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../core/providers/database_provider.dart';
import '../data/filter_presets_repository.dart';
import '../domain/exercise_filter_engine.dart';
import '../domain/filter_preset.dart';
import '../data/user_collections_repository.dart';
import '../../auth/providers/auth_providers.dart';

/// Local durable auth binding only. Do not watch authStateProvider here: its
/// construction bootstraps an HTTP session even when restoring offline presets.
final filterPresetsAccountProvider = StreamProvider<String?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authority = ref.watch(cachedAuthWriteAuthorityProvider);
  final controller = StreamController<String?>();
  String? bound;
  void publish() {
    final auth = authority.state;
    controller.add(
      auth == null || (auth.isSignedIn && auth.accountId == bound)
          ? bound
          : null,
    );
  }

  final subscription = db
      .select(db.syncState)
      .watchSingleOrNull()
      .map(
        (row) => row != null && row.offlineAccess && row.accountId.isNotEmpty
            ? row.accountId
            : null,
      )
      .distinct()
      .listen((value) {
        bound = value;
        publish();
      });
  authority.revision.addListener(publish);
  ref.onDispose(() {
    authority.revision.removeListener(publish);
    subscription.cancel();
    controller.close();
  });
  return controller.stream.distinct();
});

final userCollectionsRepositoryProvider = Provider<UserCollectionsRepository>(
  (ref) => UserCollectionsRepository(
    ref.watch(appDatabaseProvider),
    authority: ref.watch(cachedAuthWriteAuthorityProvider),
  ),
);

final filterPresetsRepositoryProvider = Provider<FilterPresetsRepository>(
  (ref) => FilterPresetsRepository(
    cloud: ref.watch(userCollectionsRepositoryProvider),
  ),
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
      final controller = FilterPresetsController(
        ref.watch(filterPresetsRepositoryProvider),
        account,
      );
      final cloud = ref.watch(filterPresetsRepositoryProvider).cloud;
      if (cloud != null) {
        final subscription = cloud.db.userProfileDao.watchProfile().listen(
          (_) => controller.reload(),
        );
        ref.onDispose(subscription.cancel);
      }
      return controller;
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
  int _writes = 0;
  bool get _current => mounted && accountId != null;
  void reload() {
    if (_current && _writes == 0) {
      ++_revision;
      _load();
    }
  }

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
    ++_writes;
    try {
      await _repository.save(
        account,
        name,
        filters,
        overwriteId: overwriteId,
        isCurrent: () => _current,
      );
      if (!_current) throw StateError('Konto zostało zmienione.');
      await _load();
    } finally {
      --_writes;
    }
  }

  Future<void> delete(String id) async {
    final account = _account();
    ++_revision;
    ++_writes;
    try {
      await _repository.delete(account, id, isCurrent: () => _current);
      if (!_current) throw StateError('Konto zostało zmienione.');
      await _load();
    } finally {
      --_writes;
    }
  }

  ExerciseFilters apply(String id) {
    _account();
    return state.requireValue.firstWhere((p) => p.id == id).filters;
  }
}
