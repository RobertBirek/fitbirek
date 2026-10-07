import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/features/mentor/data/mentor_models.dart';

void main() {
  group('MentorProposal', () {
    test('accepts an unambiguous log_set proposal', () {
      final proposal = MentorProposal.fromJson({
        'id': 'c7f7e7d8-55db-4c40-8f86-68327f830321',
        'kind': 'log_set',
        'exercise_id': 'cw001',
        'weight_kg': 42.5,
        'reps': 8,
      });

      expect(proposal.isSafeToConfirm, isTrue);
    });

    test('rejects a log_set proposal lacking an identified exercise', () {
      final proposal = MentorProposal.fromJson({
        'id': 'c7f7e7d8-55db-4c40-8f86-68327f830321',
        'kind': 'log_set',
        'exercise_id': null,
        'weight_kg': 42.5,
        'reps': 8,
      });

      expect(proposal.isSafeToConfirm, isFalse);
    });
  });
}
