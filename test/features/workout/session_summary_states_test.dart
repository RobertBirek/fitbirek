import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/workout_home_page.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/features/workout/data/workout_repository.dart';
import 'package:fitbirek_training/features/workout/providers/workout_providers.dart';
import 'package:fitbirek_training/features/workout/presentation/pages/session_summary_page.dart';

class SummaryRepository extends WorkoutRepository {
  SummaryRepository(super.db);
  int reads = 0;
  Completer<List<SetLogData>> result = Completer();
  @override
  Future<List<SetLogData>> getSetsForSession(int id) {
    reads++;
    return result.future;
  }
}

void main() {
  testWidgets(
    'read error stops loading; rebuild does not reload; explicit retry and history',
    (tester) async {
      await initializeDateFormatting('pl_PL');
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = SummaryRepository(db);
      final id = await repo.startSession();
      final router = createRouter(
        readAuthState: () => const AuthState.signedIn('test-account'),
        readOnboardingComplete: () => true,
        initialLocation: '/workout/summary/$id',
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          workoutRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(() async {
        router.dispose();
        container.dispose();
        await db.close();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.result.completeError(StateError('read failed'));
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Nie udało się odczytać podsumowania treningu.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      tester.element(find.byType(SessionSummaryPage)).markNeedsBuild();
      await tester.pump();
      expect(repo.reads, 1);
      repo.result = Completer();
      await tester.tap(find.text('Spróbuj ponownie'));
      await tester.pump();
      expect(repo.reads, 2);
      repo.result.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('Brak zalogowanych serii'), findsOneWidget);
      tester.element(find.byType(SessionSummaryPage)).markNeedsBuild();
      await tester.pumpAndSettle();
      expect(repo.reads, 2);
      router.go('/workout/summary/9999');
      await tester.pumpAndSettle();
      expect(find.text('Nie znaleziono treningu.'), findsOneWidget);
      expect(repo.reads, 3);
      await db.workoutDao.updateSession(
        id,
        WorkoutSessionsCompanion(deletedAtUtc: Value(DateTime.now().toUtc())),
      );
      router.go('/workout/summary/$id');
      await tester.pumpAndSettle();
      expect(find.text('Nie znaleziono treningu.'), findsOneWidget);
      expect(find.text('Brak zalogowanych serii'), findsNothing);
      expect(find.text('Powtórz trening'), findsNothing);
      expect(repo.reads, 4);
      await tester.tap(find.text('Przejdź do historii treningów'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/workout');
      expect(find.byType(WorkoutHomePage), findsOneWidget);
      expect(find.text('Brak historii treningów'), findsOneWidget);
      expect(find.byType(SessionSummaryPage), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
