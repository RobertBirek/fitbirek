import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/progress/tests/domain/fitness_protocol.dart';
import 'package:fitbirek_training/features/progress/tests/providers/tests_providers.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/protocol_editor_page.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/protocol_detail_page.dart';
import 'package:fitbirek_training/features/progress/tests/presentation/pages/run_test_page.dart';
import 'package:fitbirek_training/features/progress/presentation/pages/progress_page.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'package:fitbirek_training/features/exercises/providers/exercise_variants_providers.dart';
import '../features/progress/fitness_ui_support.dart';

void main() {
  for (final path in [
    '/progress?section=body',
    '/progress?section=tests',
    '/progress?section=training',
    '/progress/tests/new?exerciseId=cw412',
    '/progress/tests/missing',
    '/progress/tests/missing/edit',
    '/progress/tests/missing/history',
    '/progress/run-test?exerciseId=cw412',
    '/progress/run-test?protocolId=missing',
  ]) {
    testWidgets('direct URL $path needs no extra', (tester) async {
      final fixture = await fitnessUiFixture();
      addTearDown(fixture.db.close);
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('ui@test.invalid'),
        readOnboardingComplete: () => true,
        initialLocation: path,
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(fixture.db),
            testsRepositoryProvider.overrideWithValue(fixture.repo),
            fitnessProtocolsProvider.overrideWith(
              (ref) => Stream.value(FitnessProtocolsView(isAvailable: true)),
            ),
            customFitnessResultsProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            legacyTestResultsProvider.overrideWith((ref) => Stream.value([])),
            allExercisesProvider.overrideWith((ref) => Stream.value([])),
            exerciseVariantsProvider.overrideWith(
              (ref, id) => Stream.value([]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      if (path.startsWith('/progress?')) {
        expect(
          tester.widget<ProgressPage>(find.byType(ProgressPage)).section,
          Uri.parse(path).queryParameters['section'],
        );
      } else if (path.contains('/new')) {
        expect(
          tester
              .widget<ProtocolEditorPage>(find.byType(ProtocolEditorPage))
              .exerciseId,
          'cw412',
        );
      } else if (path.contains('/edit')) {
        expect(
          tester
              .widget<ProtocolEditorPage>(find.byType(ProtocolEditorPage))
              .protocolId,
          'missing',
        );
      } else if (path.contains('run-test')) {
        final page = tester.widget<RunTestPage>(find.byType(RunTestPage));
        expect(page.exerciseId, path.contains('exerciseId') ? 'cw412' : null);
        expect(page.protocolId, path.contains('protocolId') ? 'missing' : null);
      } else {
        expect(
          tester
              .widget<ProtocolDetailPage>(find.byType(ProtocolDetailPage).last)
              .protocolId,
          'missing',
        );
      }
      expect(tester.takeException(), isNull);
      if (!path.startsWith('/progress?')) {
        expect(router.canPop(), isTrue);
        router.pop();
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          path.endsWith('/edit') || path.endsWith('/history')
              ? '/progress/tests/missing'
              : '/progress',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
