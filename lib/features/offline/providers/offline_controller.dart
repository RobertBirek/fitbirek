import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/offline_bridge.dart';
import '../domain/offline_snapshot.dart';

class OfflineViewState {
  const OfflineViewState(
    this.snapshot, {
    this.busy = false,
    this.fresh = false,
  });
  final OfflineSnapshot snapshot;
  final bool busy, fresh;
}

final offlineBridgeProvider = Provider<OfflineBridge>(
  (ref) => createOfflineBridge(),
);
final offlineControllerProvider =
    StateNotifierProvider.autoDispose<OfflineController, OfflineViewState>((
      ref,
    ) {
      final controller = OfflineController(ref.watch(offlineBridgeProvider));
      unawaited(controller.refresh());
      return controller;
    });

class OfflineController extends StateNotifier<OfflineViewState> {
  OfflineController(
    this.bridge, {
    // The web bridge bounds full cache verification at 60 s.
    this.timeout = const Duration(seconds: 65),
    this.commandTimeout = const Duration(seconds: 10),
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 120,
  }) : super(
         const OfflineViewState(OfflineSnapshot(phase: OfflinePhase.checking)),
       );

  final OfflineBridge bridge;
  final Duration timeout, commandTimeout, pollInterval;
  final int maxPolls;
  Future<void>? _running;
  Future<void>? _cancelling;
  Timer? _timer;
  bool _active = true, _disposed = false;
  int _generation = 0, _polls = 0;

  Future<void> refresh() {
    if (_disposed || !_active) return Future.value();
    if (_cancelling != null) return _cancelling!;
    if (_running != null) return _running!;
    _polls = 0;
    return _run(bridge.status);
  }

  /// Confirmation is tied to the last verified size, never to a stored flag.
  Future<void> prepare(OfflineSnapshot consent) {
    if (_disposed ||
        !_active ||
        _cancelling != null ||
        _running != null ||
        !state.fresh ||
        !identical(consent, state.snapshot) ||
        !consent.hasSize ||
        consent.requiresFreshStatus ||
        consent.inFlight ||
        consent.phase == OfflinePhase.ready ||
        consent.phase == OfflinePhase.unsupported) {
      return Future.value();
    }
    _polls = 0;
    final expectedPackageId = consent.packageId!;
    return _run(
      () => bridge.prepare(expectedPackageId),
      deadline: commandTimeout,
    );
  }

  Future<void> cancel() {
    return _cancelling ??= _cancel().whenComplete(() => _cancelling = null);
  }

  Future<void> _cancel() async {
    if (_disposed || !_active) return;
    // Serialize behind bounded status. Its response is invalidated immediately.
    _generation++;
    _timer?.cancel();
    final running = _running;
    if (running != null) await running;
    if (!_disposed && _active) {
      await _run(bridge.cancel, deadline: commandTimeout);
    }
  }

  Future<void> setActive(bool active) async {
    if (_disposed) return;
    _active = active;
    _generation++;
    _timer?.cancel();
    state = OfflineViewState(state.snapshot, busy: false);
    if (!active) return;
    final running = _running;
    if (running != null) await running;
    if (!_disposed && _active) await refresh();
  }

  Future<void> _run(
    Future<Object?> Function() operation, {
    Duration? deadline,
  }) {
    _timer?.cancel();
    final generation = ++_generation;
    state = OfflineViewState(state.snapshot, busy: true);
    // Start synchronously so repeated refresh calls share this operation.
    final result = Future<Object?>.sync(operation);
    final task = _complete(result, generation, deadline ?? timeout);
    _running = task;
    return task;
  }

  Future<void> _complete(
    Future<Object?> result,
    int generation,
    Duration deadline,
  ) async {
    OfflineSnapshot snapshot;
    try {
      snapshot = OfflineSnapshot.parse(await result.timeout(deadline));
    } on TimeoutException {
      snapshot = const OfflineSnapshot(
        phase: OfflinePhase.error,
        errorCode: 'timeout',
      );
    } on FormatException {
      snapshot = const OfflineSnapshot(
        phase: OfflinePhase.error,
        errorCode: 'protocol',
      );
    } catch (_) {
      // Never surface raw JS/network exceptions (they can contain URLs/secrets).
      snapshot = const OfflineSnapshot(
        phase: OfflinePhase.error,
        errorCode: 'bridge',
      );
    }
    _running = null;
    if (_disposed || !_active || generation != _generation) return;
    state = OfflineViewState(snapshot, fresh: true);
    if (snapshot.inFlight) {
      if (++_polls > maxPolls) {
        state = const OfflineViewState(
          OfflineSnapshot(phase: OfflinePhase.error, errorCode: 'timeout'),
        );
      } else {
        _timer = Timer(pollInterval, () {
          if (!_disposed && _active && _running == null) _run(bridge.status);
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    super.dispose();
  }
}
