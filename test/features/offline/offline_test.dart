import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitbirek_training/features/offline/domain/offline_snapshot.dart';
import 'package:fitbirek_training/features/offline/data/offline_bridge.dart';
import 'package:fitbirek_training/features/offline/data/offline_bridge_stub.dart';
import 'package:fitbirek_training/features/offline/providers/offline_controller.dart';

Map<String, Object?> packet(String state, {int cached = 0}) => {
  'protocolVersion': 1,
  'state': state,
  'packageId': 'pack-a',
  'totalFiles': 2,
  'cachedFiles': cached,
  'totalBytes': 2097152,
  'cachedBytes': cached * 1048576,
  'errorCode': null,
  'message': null,
};

Map<String, Object?> reloadPacket({required bool withSize}) => {
  ...packet('error'),
  'packageId': withSize ? 'pack-b' : null,
  'totalFiles': withSize ? 3 : 0,
  'totalBytes': withSize ? 4194304 : 0,
  'errorCode': 'reloadRequired',
  'message': 'https://private.invalid/?secret=do-not-display',
};

class FakeBridge implements OfflineBridge {
  int statuses = 0, prepares = 0, cancels = 0;
  final preparedPackageIds = <String>[];
  Object? prepareResult;
  Object? value = packet('notReady');
  Future<Object?> Function()? read;
  @override
  Future<Object?> status() {
    statuses++;
    return read?.call() ?? Future.value(value);
  }

  @override
  Future<Object?> prepare(String expectedPackageId) async {
    prepares++;
    preparedPackageIds.add(expectedPackageId);
    return prepareResult ?? packet('downloading');
  }

  @override
  Future<Object?> cancel() async {
    cancels++;
    return packet('cancelled');
  }
}

void main() {
  for (final withSize in [false, true]) {
    test(
      'accepts terminal reloadRequired withSize=$withSize without ready',
      () {
        final snapshot = OfflineSnapshot.parse(
          reloadPacket(withSize: withSize),
        );
        expect(snapshot.phase, OfflinePhase.error);
        expect(snapshot.errorCode, 'reloadRequired');
        expect(snapshot.requiresReload, true);
        expect(snapshot.hasSize, withSize);
        expect(snapshot.inFlight, false);
        expect(snapshot.requiresFreshStatus, false);
      },
    );

    testWidgets(
      'reloadRequired withSize=$withSize blocks prepare and stays passive until fresh consent',
      (tester) async {
        final bridge = FakeBridge()..value = reloadPacket(withSize: withSize);
        final controller = OfflineController(bridge);
        addTearDown(controller.dispose);
        await controller.refresh();
        final oldConsent = controller.state.snapshot;
        await controller.prepare(oldConsent);
        expect(controller.state.snapshot.phase, OfflinePhase.error);
        expect(controller.state.snapshot.errorCode, 'reloadRequired');
        await tester.pump(const Duration(seconds: 30));
        expect(bridge.prepares, 0);
        expect(bridge.cancels, 0);
        expect(bridge.statuses, 1);

        await controller.refresh();
        await controller.prepare(controller.state.snapshot);
        expect(bridge.statuses, 2);
        expect(bridge.prepares, 0);
        expect(bridge.cancels, 0);

        await controller.setActive(false);
        await tester.pump(const Duration(seconds: 30));
        expect(bridge.statuses, 2);
        await controller.setActive(true);
        expect(bridge.statuses, 3);
        expect(controller.state.snapshot.errorCode, 'reloadRequired');
        expect(bridge.prepares, 0);

        bridge.value = {
          ...packet('notReady'),
          'packageId': 'pack-b',
          'totalFiles': 3,
          'totalBytes': 4194304,
        };
        await controller.refresh();
        await controller.prepare(oldConsent);
        expect(bridge.prepares, 0);
        expect(controller.state.snapshot.phase, OfflinePhase.notReady);
        await controller.prepare(controller.state.snapshot);
        expect(bridge.preparedPackageIds, ['pack-b']);
        expect(bridge.cancels, 0);
        await controller.setActive(false);
      },
    );
  }
  for (final phase in OfflinePhase.values.where(
    (p) => p != OfflinePhase.error,
  )) {
    test(
      'rejects reloadRequired in ${phase.name}, not a polling or ready state',
      () {
        expect(
          () => OfflineSnapshot.parse({
            ...packet(phase.name, cached: phase == OfflinePhase.ready ? 2 : 0),
            'errorCode': 'reloadRequired',
          }),
          throwsFormatException,
        );
      },
    );
  }
  for (final phase in ['checking', 'downloading', 'notReady']) {
    testWidgets(
      'invalid $phase/reloadRequired becomes terminal protocol error',
      (tester) async {
        final bridge = FakeBridge()
          ..value = {...packet(phase), 'errorCode': 'reloadRequired'};
        final controller = OfflineController(bridge);
        addTearDown(controller.dispose);
        await controller.refresh();
        expect(controller.state.snapshot.phase, OfflinePhase.error);
        expect(controller.state.snapshot.errorCode, 'protocol');
        await tester.pump(const Duration(seconds: 30));
        expect(bridge.statuses, 1);
        expect(bridge.prepares, 0);
        expect(bridge.cancels, 0);
      },
    );
  }
  test('prepare sends exactly the ID of the confirmed snapshot', () async {
    final bridge = FakeBridge();
    final controller = OfflineController(bridge);
    addTearDown(controller.dispose);
    await controller.refresh();
    final consent = controller.state.snapshot;
    // Server changes after status, before prepare: never substitute the new ID.
    bridge.value = {...packet('notReady'), 'packageId': 'pack-b'};
    await controller.prepare(consent);
    expect(bridge.preparedPackageIds, ['pack-a']);
  });
  test(
    'packageChanged response requires fresh status before consenting to B',
    () async {
      final bridge = FakeBridge()
        ..prepareResult = {
          ...packet('error'),
          'packageId': 'pack-b',
          'totalFiles': 3,
          'totalBytes': 4194304,
          'errorCode': 'packageChanged',
        };
      final controller = OfflineController(bridge);
      addTearDown(controller.dispose);
      await controller.refresh();
      final consentA = controller.state.snapshot;
      await controller.prepare(consentA);
      expect(controller.state.snapshot.packageId, 'pack-b');
      expect(controller.state.snapshot.errorCode, 'packageChanged');
      await controller.prepare(consentA);
      await controller.prepare(controller.state.snapshot);
      expect(bridge.prepares, 1);
      expect(bridge.statuses, 1);
      bridge.value = {
        ...packet('notReady'),
        'packageId': 'pack-b',
        'totalFiles': 3,
        'totalBytes': 4194304,
      };
      await controller.refresh();
      bridge.prepareResult = {
        ...packet('downloading'),
        'packageId': 'pack-b',
        'totalFiles': 3,
        'totalBytes': 4194304,
      };
      await controller.prepare(controller.state.snapshot);
      expect(bridge.preparedPackageIds, ['pack-a', 'pack-b']);
    },
  );
  test('packageChanged must be a terminal error, never downloading', () {
    expect(
      () => OfflineSnapshot.parse({
        ...packet('downloading'),
        'errorCode': 'packageChanged',
      }),
      throwsFormatException,
    );
    final error = OfflineSnapshot.parse({
      ...packet('error'),
      'errorCode': 'packageChanged',
    });
    expect(error.phase, OfflinePhase.error);
    expect(error.errorCode, 'packageChanged');
    expect(error.requiresReload, false);
  });
  test(
    'unsupported or old protocol prepare never falls back to an unbound request',
    () async {
      for (final response in [
        packet('unsupported'),
        {...packet('error'), 'protocolVersion': 0},
      ]) {
        final bridge = FakeBridge()..prepareResult = response;
        final controller = OfflineController(bridge);
        await controller.refresh();
        await controller.prepare(controller.state.snapshot);
        expect(bridge.preparedPackageIds, ['pack-a']);
        expect(controller.state.snapshot.phase, isNot(OfflinePhase.ready));
        expect(controller.state.snapshot.inFlight, false);
        controller.dispose();
      }
    },
  );
  test(
    'status budget covers the bridge verification timeout, commands stay short',
    () {
      final controller = OfflineController(FakeBridge());
      addTearDown(controller.dispose);
      expect(controller.timeout, greaterThan(const Duration(seconds: 60)));
      expect(controller.commandTimeout, const Duration(seconds: 10));
    },
  );
  test(
    'repeated cancel while reading coalesces without overlapping commands',
    () async {
      final late = Completer<Object?>();
      final bridge = FakeBridge()..read = () => late.future;
      final controller = OfflineController(bridge);
      addTearDown(controller.dispose);
      final status = controller.refresh();
      final cancel1 = controller.cancel();
      final cancel2 = controller.cancel();
      late.complete(packet('downloading'));
      await Future.wait([status, cancel1, cancel2]);
      expect(bridge.cancels, 1);
    },
  );
  test(
    'provider disposal ignores stale status; reopening verifies anew',
    () async {
      final late = Completer<Object?>();
      final bridge = FakeBridge()..read = () => late.future;
      final container = ProviderContainer(
        overrides: [offlineBridgeProvider.overrideWithValue(bridge)],
      );
      final subscription = container.listen(
        offlineControllerProvider,
        (_, _) {},
      );
      expect(bridge.statuses, 1);
      subscription.close();
      container.dispose();
      late.complete(packet('ready', cached: 2));
      await Future<void>.delayed(Duration.zero);
      bridge.read = null;
      final reopened = ProviderContainer(
        overrides: [offlineBridgeProvider.overrideWithValue(bridge)],
      );
      addTearDown(reopened.dispose);
      final next = reopened.listen(offlineControllerProvider, (_, _) {});
      addTearDown(next.close);
      await Future<void>.delayed(Duration.zero);
      expect(bridge.statuses, 2);
      expect(
        reopened.read(offlineControllerProvider).snapshot.phase,
        OfflinePhase.notReady,
      );
      expect(bridge.prepares, 0);
    },
  );
  test('native adapter reports unsupported, including prepare', () async {
    final bridge = UnsupportedOfflineBridge();
    for (final result in [
      await bridge.status(),
      await bridge.prepare('pack-a'),
      await bridge.cancel(),
    ]) {
      expect(OfflineSnapshot.parse(result).phase, OfflinePhase.unsupported);
    }
  });
  test('accepts each v1 state and formats actual MiB', () {
    for (final state in OfflinePhase.values) {
      final snapshot = OfflineSnapshot.parse(
        packet(state.name, cached: state == OfflinePhase.ready ? 2 : 0),
      );
      expect(snapshot.phase, state);
      expect(snapshot.requiresReload, false);
      expect(snapshot.sizeLabel, '2.00 MiB');
    }
  });
  test('rejects malformed protocol, counters and false ready', () {
    for (final change in <Map<String, Object?>>[
      {'protocolVersion': 2},
      {'state': 'unknown'},
      {'totalBytes': -1},
      {'cachedFiles': 3},
      {'cachedBytes': 3000000},
      {'totalFiles': 2.5},
      {'state': 'ready'},
      {'state': 'ready', 'packageId': null},
      {'errorCode': 123},
      {'message': []},
    ]) {
      expect(
        () => OfflineSnapshot.parse({...packet('notReady'), ...change}),
        throwsFormatException,
      );
    }
    expect(() => OfflineSnapshot.parse(null), throwsFormatException);
  });
  test('status never downloads, prepare and cancel are explicit', () async {
    final bridge = FakeBridge();
    final controller = OfflineController(bridge);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(bridge.prepares, 0);
    expect(controller.state.snapshot.phase, OfflinePhase.notReady);
    await controller.prepare(controller.state.snapshot);
    expect(bridge.prepares, 1);
    expect(controller.state.snapshot.phase, OfflinePhase.downloading);
    await controller.cancel();
    expect(controller.state.snapshot.phase, OfflinePhase.cancelled);
  });
  test('refresh verifies ready again and can revoke it', () async {
    final bridge = FakeBridge()..value = packet('ready', cached: 2);
    final controller = OfflineController(bridge);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.state.snapshot.phase, OfflinePhase.ready);
    bridge.value = packet('notReady');
    await controller.refresh();
    expect(controller.state.snapshot.phase, OfflinePhase.notReady);
  });
  test(
    'bounded timeout can be retried; late result cannot overwrite retry',
    () async {
      final late = Completer<Object?>();
      final bridge = FakeBridge()..read = () => late.future;
      final controller = OfflineController(
        bridge,
        timeout: const Duration(milliseconds: 5),
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.state.snapshot.errorCode, 'timeout');
      bridge.read = null;
      await controller.refresh();
      late.complete(packet('ready', cached: 2));
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.snapshot.phase, OfflinePhase.notReady);
    },
  );
  test(
    'no overlapping status; suspend invalidates result, resume verifies',
    () async {
      final late = Completer<Object?>();
      final bridge = FakeBridge()..read = () => late.future;
      final controller = OfflineController(bridge);
      final first = controller.refresh();
      unawaited(controller.refresh());
      expect(bridge.statuses, 1);
      controller.setActive(false);
      late.complete(packet('ready', cached: 2));
      await first;
      expect(controller.state.fresh, false);
      bridge.read = null;
      await controller.setActive(true);
      expect(controller.state.snapshot.phase, OfflinePhase.notReady);
      expect(bridge.statuses, 2);
      controller.dispose();
    },
  );
  test('dispose ignores pending completion', () async {
    final late = Completer<Object?>();
    final controller = OfflineController(
      FakeBridge()..read = () => late.future,
    );
    final request = controller.refresh();
    controller.dispose();
    late.complete(packet('ready', cached: 2));
    await request;
  });
  test('malformed ready is protocol error, never a ready UI state', () async {
    final controller = OfflineController(
      FakeBridge()..value = packet('ready', cached: 3),
    );
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(controller.state.snapshot.phase, OfflinePhase.error);
    expect(controller.state.snapshot.errorCode, 'protocol');
  });
  test(
    'consent for an old snapshot cannot start a new package download',
    () async {
      final bridge = FakeBridge();
      final controller = OfflineController(bridge);
      addTearDown(controller.dispose);
      await controller.refresh();
      final old = controller.state.snapshot;
      bridge.value = {
        ...packet('notReady'),
        'packageId': 'pack-b',
        'totalBytes': 4194304,
      };
      await controller.refresh();
      await controller.prepare(old);
      expect(bridge.prepares, 0);
    },
  );
  testWidgets('poll is bounded, pauses in background and refreshes on resume', (
    tester,
  ) async {
    final bridge = FakeBridge()..value = packet('downloading', cached: 1);
    final controller = OfflineController(
      bridge,
      pollInterval: const Duration(seconds: 1),
      maxPolls: 2,
    );
    await controller.refresh();
    expect(bridge.statuses, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(bridge.statuses, 2);
    await controller.setActive(false);
    await tester.pump(const Duration(seconds: 5));
    expect(bridge.statuses, 2);
    await controller.setActive(true);
    expect(bridge.statuses, 3);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(controller.state.snapshot.errorCode, 'timeout');
    final count = bridge.statuses;
    await tester.pump(const Duration(seconds: 10));
    expect(bridge.statuses, count);
    controller.dispose();
  });
  test(
    'cancellation waits for status and invalidates its late ready',
    () async {
      final late = Completer<Object?>();
      final bridge = FakeBridge()..read = () => late.future;
      final controller = OfflineController(bridge);
      addTearDown(controller.dispose);
      final refresh = controller.refresh();
      final cancel = controller.cancel();
      expect(bridge.cancels, 0);
      late.complete(packet('ready', cached: 2));
      await refresh;
      await cancel;
      expect(controller.state.snapshot.phase, OfflinePhase.cancelled);
      expect(bridge.cancels, 1);
    },
  );
}
