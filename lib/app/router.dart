import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/providers/auth_providers.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
  return createRouter(
    readAuthState: () => ref.read(authStateProvider),
    readOnboardingComplete: () {
      final profile = ref.read(userProfileStreamProvider);
      return profile.when(
        data: (value) => value?.onboardingZakonczony ?? false,
        loading: () => null,
        error: (_, _) => false,
      );
    },
    refreshListenable: refresh,
  );
});

GoRouter createRouter({
  required AuthState Function() readAuthState,
  required bool? Function() readOnboardingComplete,
  Listenable? refreshListenable,
  String initialLocation = '/bootstrap',
}) {
  final pendingLocation = _PendingProtectedLocation();
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: (context, state) => _authRedirect(
      authState: readAuthState(),
      onboardingComplete: readOnboardingComplete(),
      location: state.uri.path,
      requestedLocation: state.uri.toString(),
      pendingLocation: pendingLocation,
    ),
    routes: [
      GoRoute(
        path: '/bootstrap',
        builder: (context, state) => const _BootstrapPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
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
                path: '/today',
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
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, _) => notifyListeners());
    ref.listen(userProfileStreamProvider, (_, _) => notifyListeners());
  }
}

String? authRedirect({
  required AuthState authState,
  required bool? onboardingComplete,
  required String location,
}) {
  return _authRedirect(
    authState: authState,
    onboardingComplete: onboardingComplete,
    location: location,
    requestedLocation: location,
    pendingLocation: _PendingProtectedLocation(),
  );
}

String? _authRedirect({
  required AuthState authState,
  required bool? onboardingComplete,
  required String location,
  required String requestedLocation,
  required _PendingProtectedLocation pendingLocation,
}) {
  if (authState.isLoading) {
    pendingLocation.capture(location, requestedLocation);
    return location == '/bootstrap' ? null : '/bootstrap';
  }
  if (authState.isSignedOut) {
    return location == '/login' ? null : '/login';
  }
  if (onboardingComplete == null) {
    return location == '/bootstrap' ? null : '/bootstrap';
  }
  if (!onboardingComplete) {
    return location == '/onboarding' ? null : '/onboarding';
  }
  if (location == '/bootstrap' ||
      location == '/login' ||
      location == '/onboarding') {
    return pendingLocation.take() ?? '/today';
  }
  return null;
}

class _PendingProtectedLocation {
  String? _location;

  void capture(String location, String requestedLocation) {
    if (location == '/bootstrap' ||
        location == '/login' ||
        location == '/onboarding') {
      return;
    }
    _location = requestedLocation;
  }

  String? take() {
    final location = _location;
    _location = null;
    return location;
  }
}

class _BootstrapPage extends StatelessWidget {
  const _BootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
