import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_status_tile.dart';

void main() {
  testWidgets('shows retained queue and offers retry and logout', (
    tester,
  ) async {
    var retried = false;
    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncStatusTile(
            status: SyncStatus.offline,
            pending: 2,
            onRetry: () {
              retried = true;
            },
            onLogout: () {
              loggedOut = true;
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('2'), findsOneWidget);
    expect(find.textContaining('Offline'), findsOneWidget);
    await tester.tap(find.byTooltip('Synchronizuj teraz'));
    await tester.tap(find.text('Wyloguj'));
    expect(retried, isTrue);
    expect(loggedOut, isTrue);
  });
}
