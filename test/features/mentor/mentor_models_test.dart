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

  group('MentorSettings', () {
    test('reads mentor customization returned by the server', () {
      final dynamic settings = MentorSettings.fromJson({
        'persona': 'Pomagaj spokojnie.',
        'revision': 7,
        'active_model_profile_key': 'gpt-6-luna',
        'model_profiles': [
          {
            'key': 'gpt-6-luna',
            'identifier': 'gpt-6-luna',
            'label': 'GPT-6 Luna',
            'quality_class': 'ekonomiczny',
            'cost_warning': 'Niski koszt.',
          },
        ],
        'context_consents': {
          'training': true,
          'profile': false,
          'weight': true,
          'note': false,
          'apple_health': true,
        },
      });

      expect(settings.persona, 'Pomagaj spokojnie.');
      expect(settings.revision, 7);
      expect(settings.activeModelProfileKey, 'gpt-6-luna');
      expect(settings.modelProfiles.single.label, 'GPT-6 Luna');
      expect(settings.modelProfiles.single.qualityClass, 'ekonomiczny');
      expect(settings.contextConsents.training, isTrue);
      expect(settings.contextConsents.profile, isFalse);
      expect(settings.contextConsents.weight, isTrue);
      expect(settings.contextConsents.note, isFalse);
      expect(settings.contextConsents.appleHealth, isTrue);
    });

    test('defaults absent mentor customization safely', () {
      final dynamic settings = MentorSettings.fromJson({});

      expect(settings.persona, isEmpty);
      expect(settings.revision, 0);
      expect(settings.activeModelProfileKey, isNull);
      expect(settings.modelProfiles, isEmpty);
      expect(settings.contextConsents.training, isFalse);
      expect(settings.contextConsents.profile, isFalse);
      expect(settings.contextConsents.weight, isFalse);
      expect(settings.contextConsents.note, isFalse);
      expect(settings.contextConsents.appleHealth, isFalse);
    });
  });
}
