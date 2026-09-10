import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/presentation/pages/login_page.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';

void main() {
  testWidgets(
    'shows a generic error and clears busy state on network failure',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => AuthController(_NetworkFailingAuthApi()),
            ),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'me@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.tap(find.text('Zaloguj się'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nie udało się zalogować. Sprawdź dane i spróbuj ponownie.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _NetworkFailingAuthApi implements AuthApi {
  @override
  Future<AuthSession?> getSession() async => null;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    return Future.error(
      DioException(
        requestOptions: RequestOptions(path: '/api/auth/login'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
  }

  @override
  Future<void> logout() async {}
}
