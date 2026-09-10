import 'package:flutter/material.dart';
import 'sync_service.dart';

class SyncStatusTile extends StatelessWidget {
  const SyncStatusTile({
    super.key,
    required this.status,
    required this.pending,
    required this.onRetry,
    required this.onLogout,
  });
  final SyncStatus status;
  final int pending;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        leading: const Icon(Icons.sync),
        title: Text(switch (status) {
          SyncStatus.idle => 'Synchronizacja gotowa',
          SyncStatus.syncing => 'Synchronizowanie…',
          SyncStatus.offline => 'Offline — dane zapisane na urządzeniu',
          SyncStatus.error => 'Błąd synchronizacji — dane zachowane',
          SyncStatus.conflict =>
            'Operacja wymaga weryfikacji — wyeksportuj kopię i skontaktuj się z administratorem',
          SyncStatus.signedOut => 'Zaloguj się, aby synchronizować',
        }),
        subtitle: Text('Oczekujące zmiany: $pending'),
        trailing: IconButton(
          tooltip: 'Synchronizuj teraz',
          onPressed: status == SyncStatus.syncing ? null : onRetry,
          icon: const Icon(Icons.refresh),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Wyloguj'),
        subtitle: const Text('Dane pozostaną przypisane do tego konta'),
        onTap: onLogout,
      ),
    ],
  );
}
