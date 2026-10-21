import 'package:drift/drift.dart';
import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/models/fitness_test.dart';
import '../../../../core/sync/sync_models.dart';
import '../../../../core/utils/test_score_calculator.dart';
import '../../../../core/sync/user_collections.dart';
import '../../../../core/sync/profile_payload.dart';
import '../../../auth/providers/auth_providers.dart';
import '../domain/fitness_protocol.dart';

/// Captured once before opening a form. Never renewed on submission.
final class FitnessWriteLease {
  FitnessWriteLease._(
    this._owner,
    this._epoch,
    this._binding,
    this._profileId,
    this.protocol,
    this._current,
  );
  final TestsRepository _owner;
  final int? _epoch;
  final SyncStateData _binding;
  final String _profileId;
  final bool Function()? _current;
  final FitnessProtocol? protocol;
}

/// Repozytorium testów sprawnościowych.
class TestsRepository {
  TestsRepository(this._db, {this.authority});
  final AppDatabase _db;
  final CachedAuthWriteAuthority? authority;

  void _guard(int? epoch, bool Function()? current, [String? account]) {
    final auth = authority?.state;
    if (authority?.epoch != epoch ||
        !(current?.call() ?? true) ||
        (auth != null &&
            (!auth.isSignedIn ||
                (account != null && auth.accountId != account)))) {
      throw StateError('Konto zmieniło się. Otwórz formularz ponownie.');
    }
  }

  bool _sameBinding(SyncStateData? a, SyncStateData? b) =>
      a != null &&
      b != null &&
      a.offlineAccess &&
      b.offlineAccess &&
      a.accountId.isNotEmpty &&
      a.accountId == b.accountId &&
      a.deviceId == b.deviceId;

  Future<UserProfileData> _profile(
    int? epoch,
    bool Function()? current, {
    SyncStateData? binding,
    String? profileId,
  }) async {
    _guard(epoch, current, binding?.accountId);
    final state = await _db.syncDao.readState();
    _guard(epoch, current, state?.accountId);
    if (state == null ||
        !state.offlineAccess ||
        state.accountId.isEmpty ||
        (binding != null && !_sameBinding(binding, state))) {
      throw StateError('Pamięć konta jest niedostępna.');
    }
    final profile = await _db.userProfileDao.watchProfileOnce();
    _guard(epoch, current, state.accountId);
    final after = await _db.syncDao.readState();
    _guard(epoch, current, state.accountId);
    if (!_sameBinding(state, after) ||
        profile == null ||
        profile.deletedAtUtc != null ||
        (profileId != null && profile.syncId != profileId)) {
      throw StateError('Profil konta jest niedostępny.');
    }
    return profile;
  }

  Future<void> _requireUnheld(UserProfileData profile) async {
    final records =
        await (_db.select(_db.syncDeferredRecords)..where(
              (r) =>
                  r.entityType.equals('profile') &
                  r.entityId.equals(profile.syncId),
            ))
            .get();
    for (final row in records) {
      final raw = jsonDecode(row.recordJson) as Map;
      if (raw['_profileCollectionConflict'] != null ||
          raw['deletedAt'] != null ||
          (raw['payload'] is Map &&
              (raw['payload'] as Map).containsKey('fitnessProtocols'))) {
        throw StateError(
          'Zasady testów oczekują na rozstrzygnięcie synchronizacji.',
        );
      }
    }
  }

  List<FitnessProtocol> _protocols(UserProfileData profile) {
    final value = UserCollections.validate(
      'fitnessProtocols',
      profile.fitnessProtocolsJson == null
          ? UserCollections.empty()
          : jsonDecode(profile.fitnessProtocolsJson!),
    );
    final rows =
        (value['entries'] as List)
            .map(
              (e) =>
                  FitnessProtocol.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList()
          ..sort((a, b) {
            final c = b.createdAtUtc.compareTo(a.createdAtUtc);
            return c != 0 ? c : a.id.compareTo(b.id);
          });
    return rows;
  }

  Future<FitnessWriteLease> captureLease({
    String? protocolId,
    bool Function()? isCurrent,
  }) async {
    final epoch = authority?.epoch;
    return _db.transaction(() async {
      final profile = await _profile(epoch, isCurrent);
      await _requireUnheld(profile);
      final protocols = _protocols(profile);
      final protocol = protocolId == null
          ? null
          : protocols.where((p) => p.id == protocolId).firstOrNull;
      if (protocolId != null && protocol == null) {
        throw StateError('Test jest niedostępny.');
      }
      final binding = await _db.syncDao.readState();
      await _profile(
        epoch,
        isCurrent,
        binding: binding,
        profileId: profile.syncId,
      );
      return FitnessWriteLease._(
        this,
        epoch,
        binding!,
        profile.syncId,
        protocol,
        isCurrent,
      );
    });
  }

  Future<UserProfileData> _check(FitnessWriteLease lease) async {
    if (!identical(lease._owner, this)) {
      throw StateError('Nieprawidłowe uprawnienia formularza.');
    }
    final profile = await _profile(
      lease._epoch,
      lease._current,
      binding: lease._binding,
      profileId: lease._profileId,
    );
    await _requireUnheld(profile);
    final rows = _protocols(profile);
    if (lease.protocol != null) {
      final p = rows.where((p) => p.id == lease.protocol!.id).firstOrNull;
      if (p == null ||
          p.isArchived ||
          !p.hasSameRevisionRules(lease.protocol!)) {
        throw StateError('Zasady testu zmieniły się lub test zarchiwizowano.');
      }
    }
    _guard(lease._epoch, lease._current, lease._binding.accountId);
    return profile;
  }

  Future<void> validateLease(FitnessWriteLease lease) =>
      _db.transaction(() async {
        await _check(lease);
      });
  Future<T> _write<T>(
    FitnessWriteLease lease,
    Future<T> Function(UserProfileData profile) action,
  ) => _db.transaction(() async {
    final profile = await _check(lease);
    final result = await action(profile);
    // Archive intentionally changes the baseline, but ownership and profile are
    // still checked after the final await so failure rolls the entire write back.
    await _profile(
      lease._epoch,
      lease._current,
      binding: lease._binding,
      profileId: lease._profileId,
    );
    return result;
  });
  Future<void> _saveProtocols(
    UserProfileData profile,
    List<FitnessProtocol> rows,
  ) async {
    final collection = UserCollections.validate('fitnessProtocols', {
      'version': 1,
      'entries': rows.map((p) => p.toJson()).toList(),
    });
    await (_db.update(
      _db.userProfiles,
    )..where((p) => p.id.equals(profile.id))).write(
      UserProfilesCompanion(
        fitnessProtocolsJson: Value(jsonEncode(collection)),
        updatedAtUtc: Value(DateTime.now().toUtc()),
      ),
    );
    final fresh = (await _db.userProfileDao.watchProfileOnce())!;
    await _db.syncDao.enqueueUpsert(
      entityType: SyncEntityType.profile,
      entityId: fresh.syncId,
      baseVersion: await profileWriteBaseVersion(
        _db,
        fresh.syncId,
        fresh.syncVersion,
      ),
      payload: profilePayload(fresh),
    );
  }

  Future<FitnessProtocol> _newProtocol(
    UserProfileData profile,
    FitnessProtocolDraft draft,
    FitnessProtocol? parent,
  ) async {
    final exercise = await (_db.select(
      _db.exercises,
    )..where((e) => e.id.equals(draft.exerciseId))).getSingleOrNull();
    if (exercise == null) {
      throw StateError('Ćwiczenie jest niedostępne w katalogu.');
    }
    final variant = draft.variantSnapshot;
    if (variant != null &&
        (parent?.variantSnapshot == null ||
            UserCollections.canonical(variant) !=
                UserCollections.canonical(parent!.variantSnapshot))) {
      final variants = UserCollections.validate(
        'exerciseVariants',
        profile.exerciseVariantsJson == null
            ? UserCollections.empty()
            : jsonDecode(profile.exerciseVariantsJson!),
      );
      if (!(variants['entries'] as List).any(
        (v) =>
            v['deletedAtUtc'] == null &&
            v['exerciseId'] == draft.exerciseId &&
            UserCollections.canonical(v) == UserCollections.canonical(variant),
      )) {
        throw StateError('Wybrany wariant nie jest już dostępny.');
      }
    }
    final id = const Uuid().v4(),
        stamp = DateTime.now().toUtc().toIso8601String();
    return FitnessProtocol.fromJson({
      'id': id,
      'familyId': parent?.familyId ?? id,
      'supersedesId': parent?.id,
      'name': draft.name.trim(),
      'exerciseId': draft.exerciseId,
      'exerciseName': draft.exerciseName,
      'metric': draft.metric.wireValue,
      'direction': draft.direction.wireValue,
      'loadKg': draft.loadKg,
      'loadBasis': draft.loadBasis?.wireValue,
      'side': draft.side?.wireValue,
      'variantSnapshot': variant,
      'timeLimitSeconds': draft.timeLimitSeconds,
      'instructions': draft.instructions,
      'createdAtUtc': stamp,
      'updatedAtUtc': stamp,
    });
  }

  Future<FitnessProtocol> createProtocol(
    FitnessWriteLease lease,
    FitnessProtocolDraft draft,
  ) => _write(lease, (profile) async {
    if (lease.protocol != null) {
      throw StateError('Nowy test wymaga nowego formularza.');
    }
    final p = await _newProtocol(profile, draft, null);
    await _saveProtocols(profile, [..._protocols(profile), p]);
    return p;
  });
  Future<FitnessProtocol> reviseProtocol(
    FitnessWriteLease lease,
    FitnessProtocolDraft draft,
  ) => _write(lease, (profile) async {
    if (lease.protocol == null) throw StateError('Brak rewizji źródłowej.');
    final p = await _newProtocol(profile, draft, lease.protocol);
    await _saveProtocols(profile, [..._protocols(profile), p]);
    return p;
  });
  Future<void> archiveProtocol(FitnessWriteLease lease) =>
      _write(lease, (profile) async {
        if (lease.protocol == null) throw StateError('Brak testu.');
        final rows = _protocols(profile).map((p) {
          if (p.id != lease.protocol!.id) return p;
          var stamp = DateTime.now().toUtc();
          if (!stamp.isAfter(p.updatedAtUtc)) {
            stamp = p.updatedAtUtc.add(const Duration(microseconds: 1));
          }
          return FitnessProtocol.fromJson({
            ...p.toJson(),
            'updatedAtUtc': stamp.toIso8601String(),
            'deletedAtUtc': stamp.toIso8601String(),
          });
        }).toList();
        await _saveProtocols(profile, rows);
      });
  DateTime _performed(DateTime date) {
    final utc = date.toUtc();
    if (utc.year < 1 ||
        utc.year > 9999 ||
        utc.isAfter(DateTime.now().toUtc())) {
      throw ArgumentError('Data próby nie może być przyszła.');
    }
    return utc;
  }

  Future<void> _insertResult({
    required String typ,
    required double value,
    required DateTime performedAt,
    required int score,
    Map<String, dynamic>? custom,
  }) async {
    final now = DateTime.now().toUtc(), id = const Uuid().v4();
    await _db.testsDao.addResult(
      FitnessTestResultsCompanion.insert(
        typ: typ,
        data: Value(performedAt),
        wynik: value,
        score: Value(score),
        syncId: Value(id),
        updatedAtUtc: Value(now),
        customProtocolJson: Value(custom == null ? null : jsonEncode(custom)),
      ),
    );
    await _db.syncDao.enqueueUpsert(
      entityType: SyncEntityType.fitnessTest,
      entityId: id,
      baseVersion: 0,
      payload: {
        'typ': typ,
        'data': performedAt.toIso8601String(),
        'wynik': custom != null && custom['snapshot']['metric'] == 'reps'
            ? value.toInt()
            : value,
        'score': score,
        if (custom != null) 'customProtocol': custom,
      },
    );
  }

  Future<void> addCustomResult(
    FitnessWriteLease lease, {
    required num value,
    required DateTime performedAt,
  }) => _write(lease, (profile) async {
    final p = lease.protocol;
    if (p == null) throw StateError('Brak protokołu testu.');
    FitnessProtocol.validateValue(p.metric, value);
    await _insertResult(
      typ: 'customFitnessTestV1',
      value: value.toDouble(),
      performedAt: _performed(performedAt),
      score: 0,
      custom: {
        'version': 1,
        'protocolId': p.id,
        'familyId': p.familyId,
        'snapshot': p.toJson(),
      },
    );
  });
  Future<void> addLegacyResult(
    FitnessWriteLease lease, {
    required TypTestu typ,
    required double value,
    required DateTime performedAt,
  }) => _write(lease, (profile) async {
    if (!value.isFinite) throw ArgumentError('Wynik musi być skończony.');
    await _insertResult(
      typ: typ.name,
      value: value,
      performedAt: _performed(performedAt),
      score: TestScoreCalculator.calculateScore(typ, value),
    );
  });

  /// Every subscription is pinned to its opening passive account epoch/binding.
  Stream<T> _watch<T>(
    Future<T> Function(UserProfileData profile) read,
    T Function(String reason, String? raw) unavailable,
  ) {
    late StreamController<T> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    final epoch = authority?.epoch;
    SyncStateData? binding;
    String? profileId;
    bool alive = true, revoked = false;
    Future<void> pending = Future.value();
    void refresh() {
      pending = pending.then((_) async {
        if (!alive) return;
        String? raw;
        try {
          if (revoked) {
            throw StateError('Konto zmieniło się. Otwórz ekran ponownie.');
          }
          binding ??= await _db.syncDao.readState();
          if (binding == null) {
            throw StateError('Pamięć konta jest niedostępna.');
          }
          final profile = await _profile(
            epoch,
            () => alive,
            binding: binding,
            profileId: profileId,
          );
          profileId ??= profile.syncId;
          raw = profile.fitnessProtocolsJson;
          final value = await read(profile);
          await _profile(
            epoch,
            () => alive,
            binding: binding,
            profileId: profileId,
          );
          if (alive) controller.add(value);
        } catch (e) {
          if (!alive) return;
          if (authority?.epoch != epoch) revoked = true;
          try {
            final state = await _db.syncDao.readState();
            if (binding != null && !_sameBinding(binding, state)) {
              revoked = true;
            }
            if (alive) controller.add(unavailable(e.toString(), raw));
          } catch (error, stack) {
            if (alive) controller.addError(error, stack);
          }
        }
      });
    }

    controller = StreamController<T>(
      onListen: () {
        subscriptions.add(
          _db
              .select(_db.userProfiles)
              .watch()
              .listen((_) => refresh(), onError: controller.addError),
        );
        subscriptions.add(
          _db.select(_db.syncState).watch().listen((rows) {
            if (binding != null && !_sameBinding(binding, rows.firstOrNull)) {
              revoked = true;
            }
            refresh();
          }, onError: controller.addError),
        );
        subscriptions.add(
          _db
              .select(_db.syncDeferredRecords)
              .watch()
              .listen((_) => refresh(), onError: controller.addError),
        );
        subscriptions.add(
          _db.testsDao.watchAll().listen(
            (_) => refresh(),
            onError: controller.addError,
          ),
        );
        authority?.revision.addListener(refresh);
      },
      onCancel: () async {
        alive = false;
        authority?.revision.removeListener(refresh);
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<FitnessProtocolsView> watchProtocols() => _watch(
    (p) async {
      await _requireUnheld(p);
      return FitnessProtocolsView(
        isAvailable: true,
        rawJson: p.fitnessProtocolsJson,
        protocols: _protocols(p),
      );
    },
    (reason, raw) => FitnessProtocolsView(
      isAvailable: false,
      unavailableReason: reason,
      rawJson: raw,
    ),
  );
  Stream<List<CustomFitnessResult>?> watchCustomResults() => _watch(
    (p) async => List<CustomFitnessResult>.unmodifiable(
      (await _db.testsDao.watchAll().first)
          .where(
            (r) =>
                r.typ == 'customFitnessTestV1' || r.customProtocolJson != null,
          )
          .map(CustomFitnessResult.fromRow),
    ),
    (_, _) => null,
  );
  Stream<List<FitnessTestResultData>?> watchLegacyResults() => _watch(
    (p) async => List<FitnessTestResultData>.unmodifiable(
      (await _db.testsDao.watchAll().first).where(
        (r) =>
            r.customProtocolJson == null &&
            TypTestu.values.any((t) => t.name == r.typ),
      ),
    ),
    (_, _) => null,
  );

  Future<void> addResult({required TypTestu typ, required double wynik}) async {
    final score = TestScoreCalculator.calculateScore(typ, wynik);
    final now = DateTime.now().toUtc();
    final syncId = Uuid().v4();
    await _db.transaction(() async {
      await _db.testsDao.addResult(
        FitnessTestResultsCompanion.insert(
          typ: typ.name,
          data: Value(now),
          wynik: wynik,
          score: Value(score),
          syncId: Value(syncId),
          updatedAtUtc: Value(now),
        ),
      );
      await _db.syncDao.enqueueUpsert(
        entityType: SyncEntityType.fitnessTest,
        entityId: syncId,
        baseVersion: 0,
        payload: {
          'typ': typ.name,
          'data': now.toIso8601String(),
          'wynik': wynik,
          'score': score,
        },
      );
    });
  }

  Stream<List<FitnessTestResultData>> watchAll() => _db.testsDao.watchAll();

  Future<List<FitnessTestResultData>> getHistoryForType(TypTestu typ) {
    return _db.testsDao.getHistoryForType(typ.name);
  }
}
