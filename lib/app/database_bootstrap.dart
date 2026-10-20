import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/schema_gate.dart';
import '../core/providers/database_provider.dart';
import 'theme.dart';

/// Above the router and every app consumer (including auth and sync).
class DatabaseBootstrap extends ConsumerWidget {
  const DatabaseBootstrap({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(databaseReadyProvider);
    if (!ready.isLoading && !ready.hasError && ready.hasValue) return child;

    final error = ready.error;
    final mismatch = error is DatabaseSchemaMismatch ? error : null;
    return MaterialApp(
      title: 'FitBirek',
      debugShowCheckedModeBanner: false,
      theme: FitBirekTheme.dark,
      // This gate must not create a temporary Navigator: its navigation
      // messages consume Flutter Web's initial URL before GoRouter exists.
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ready.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Wymagane bezpieczne otwarcie FitBirek'),
                          const SizedBox(height: 16),
                          Text(
                            mismatch == null
                                ? 'Nie udało się bezpiecznie otworzyć lokalnej bazy. Spróbuj ponownie. Nie usuwaj danych aplikacji.'
                                : mismatch.actual < mismatch.expected
                                ? 'Zamknij wszystkie karty i okna FitBirek, także to, i otwórz aplikację ponownie. Jeśli korzystasz z zainstalowanej aplikacji (PWA), zamknij ją całkowicie. Nie usuwaj danych aplikacji.'
                                : 'Lokalna baza pochodzi z nowszej wersji FitBirek. Otwórz aktualną wersję aplikacji. Nie usuwaj danych aplikacji.',
                          ),
                          if (mismatch != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Schemat bazy: ${mismatch.actual}; wymagany: ${mismatch.expected}.',
                            ),
                          ],
                          if (mismatch != null &&
                              mismatch.actual < mismatch.expected) ...[
                            const SizedBox(height: 12),
                            const Text(
                              '„Spróbuj ponownie” to opcjonalne sprawdzenie zgodności bazy, nie restart współdzielonego połączenia. Jeśli blokada pozostaje, konieczne jest pełne zamknięcie FitBirek zgodnie z instrukcją powyżej.',
                            ),
                          ],
                          const SizedBox(height: 12),
                          const Text(
                            'Lokalne dane i oczekujące zmiany nie zostały usunięte. Ta karta nie uruchomi synchronizacji do czasu bezpiecznego otwarcia bazy.',
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(appDatabaseProvider),
                            child: const Text('Spróbuj ponownie'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
