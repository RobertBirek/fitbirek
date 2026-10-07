import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_operations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mentor_flow_test.dart' as fixtures;

class _WireApi extends fixtures.ApiFake {
  final result = MentorOperation.fromJson({
    'request_id': '65a2c338-38af-44a2-a2e3-a2b7d463137c',
    'kind': 'message', // Exact FastAPI operation kind, not a fake UI-only name.
    'state': 'complete',
    'session_id': 'session',
    'subject_id': null,
    'user_text': 'Plan',
    'created_at': '2026-09-14T00:00:00Z',
    'response': {
      'id': 'b0d3282b-fb96-465b-b856-c6e94a9fcaf8',
      'role': 'assistant',
      'text': 'Odzyskana odpowiedź',
      'proposal': null,
      'created_at': '2026-09-14T00:00:01Z',
    },
  });
  @override
  Future<List<MentorOperation>> operations({
    String? sessionId,
    String? subjectId,
    String? kind,
  }) async {
    expect(kind, 'message');
    return [result];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'actual backend message kind recovers debit after local metadata loss',
    () async {
      SharedPreferences.setMockInitialValues({});
      final api = _WireApi();
      final operation = await MentorOperationRegistry(
        'owner',
      ).resolve(api, 'chat', sessionId: 'session', text: 'Plan');
      expect(operation.requestId, api.result.requestId);
      expect(operation.response?.text, 'Odzyskana odpowiedź');
    },
  );
}
