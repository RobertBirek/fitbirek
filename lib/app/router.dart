import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/presentation/pages/onboarding_flow_page.dart';
import '../features/onboarding/providers/user_profile_provider.dart';
import '../features/home/presentation/pages/main_shell.dart';
import '../features/home/presentation/pages/today_page.dart';
import '../features/exercises/presentation/pages/exercises_list_page.dart';
import '../features/exercises/presentation/pages/exercise_detail_page.dart';
import '../features/workout/presentation/pages/workout_home_page.dart';
import '../features/workout/presentation/pages/active_session_page.dart';
import '../features/workout/presentation/pages/session_summary_page.dart';
import '../features/progress/presentation/pages/progress_page.dart';
import '../features/progress/measurements/presentation/pages/add_measurement_page.dart';
import '../features/progress/tests/presentation/pages/run_test_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/pages/edit_profile_page.dart';
import '../features/calculator/presentation/pages/calculator_page.dart';
import '../features/planner/presentation/pages/planner_page.dart';

/// Konfiguracja GoRouter - deep links + guard onboardingu.
/// Onboarding jest wymagany raz - redirect sprawdza flag onboardingZakonczony
/// z UserProfileRepository (single-user, lokalna baza).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      final repo = ref.read(userProfileRepositoryProvider);
      final profile = await repo.getProfileOnce();
      final completed = profile?.onboardingZakonczony ?? false;
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!completed && !isOnboardingRoute) return '/onboarding';
      if (completed && isOnboardingRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlowPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exercises',
                builder: (context, state) => const ExercisesListPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ExerciseDetailPage(
                      exerciseId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workout',
                builder: (context, state) => const WorkoutHomePage(),
                routes: [
                  GoRoute(
                    path: 'session',
                    builder: (context, state) => const ActiveSessionPage(),
                  ),
                  GoRoute(
                    path: 'summary/:sessionId',
                    builder: (context, state) => SessionSummaryPage(
                      sessionId: int.parse(state.pathParameters['sessionId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressPage(),
                routes: [
                  GoRoute(
                    path: 'add-measurement',
                    builder: (context, state) => const AddMeasurementPage(),
                  ),
                  GoRoute(
                    path: 'run-test',
                    builder: (context, state) => const RunTestPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'edit-profile',
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'calculator',
                    builder: (context, state) => const CalculatorPage(),
                  ),
                  GoRoute(
                    path: 'planner',
                    builder: (context, state) => const PlannerPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
