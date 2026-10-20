import 'package:flutter/material.dart';
import 'sync_service.dart';

class SyncStatusTile extends StatelessWidget {
  const SyncStatusTile({
    super.key,
    required this.status,
    required this.pending,
    required this.onRetry,
    required this.onLogout,
    this.showLogout = true,
  });
  final SyncStatus status;
  final int pending;
  final VoidCallback onRetry;
  final VoidCallback onLogout;
  final bool showLogout;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        titleAlignment: ListTileTitleAlignment.top,
        leading: const Icon(Icons.sync),
        title: Text(switch (status) {
          SyncStatus.idle => 'Synchronizacja gotowa',
          SyncStatus.syncing => 'Synchronizowanie…',
          SyncStatus.offline => 'Offline — dane zapisane na urządzeniu',
          SyncStatus.error => 'Błąd synchronizacji — dane zachowane',
          SyncStatus.conflict =>
            'Kwarantanna synchronizacji — część danych wymaga weryfikacji',
          SyncStatus.signedOut => 'Zaloguj się, aby synchronizować',
        }),
        subtitle: Text(
          status == SyncStatus.conflict
              ? 'Lokalne zmiany oczekujące (także wstrzymane): $pending. '
                    'Zachowano dane do odzyskania. Synchronizuj teraz nie ponawia wstrzymanych operacji; '
                    'pobiera poprawione dane i synchronizuje niezależne zmiany. '
                    'Przed ręczną naprawą zachowaj kopię i skontaktuj się z administratorem.'
              : 'Oczekujące zmiany: $pending',
        ),
        trailing: IconButton(
          tooltip: 'Synchronizuj teraz',
          onPressed: status == SyncStatus.syncing ? null : onRetry,
          icon: const Icon(Icons.refresh),
        ),
      ),
      if (showLogout)
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Wyloguj'),
          subtitle: const Text('Dane pozostaną przypisane do tego konta'),
          onTap: onLogout,
        ),
    ],
  );
}
