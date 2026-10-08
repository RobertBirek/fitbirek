import 'dart:convert';

import 'package:fitbirek_training/features/mentor/data/mentor_api.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_operations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OperationsApi implements MentorApi {
  @override
  void cancel() {}

  @override
  Future<MentorOperation?> operation(String requestId) async => MentorOperation(
    requestId: requestId,
    kind: 'chat',
    state: 'complete',
    sessionId: 'session',
  );

  @override
  Future<List<MentorOperation>> operations({
    String? sessionId,
    String? subjectId,
    String? kind,
  }) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('context changes the one-way idempotency fingerprint without persistence', () async {
    final api = _OperationsApi();
    final registry = MentorOperationRegistry('account-a');
    const selectedWeight = 'opaque-weight-selector-that-must-never-persist';

    final first = await (registry as dynamic).resolve(
      api,
      'chat',
      sessionId: 'session',
      text: 'Jak trenować?',
      selection: const {'training': true, 'weight': selectedWeight},
    ) as MentorOperation;
    final same = await (registry as dynamic).resolve(
      api,
      'chat',
      sessionId: 'session',
      text: 'Jak trenować?',
      selection: const {'weight': selectedWeight, 'training': true},
    ) as MentorOperation;
    final changed = await (registry as dynamic).resolve(
      api,
      'chat',
      sessionId: 'session',
      text: 'Jak trenować?',
      selection: const {'training': false, 'weight': selectedWeight},
    ) as MentorOperation;

    expect(same.requestId, first.requestId);
    expect(changed.requestId, isNot(first.requestId));
    final stored = (await SharedPreferences.getInstance()).getString(
      registry.storageKey,
    )!;
    expect(stored, isNot(contains(selectedWeight)));
    expect(jsonDecode(stored), everyElement(isA<Map>()));
  });
}
