import 'dart:async';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitbirek_training/app/theme.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/push/push_settings_tile.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/core/sync/sync_status_tile.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_backup_page.dart';
import 'package:fitbirek_training/features/settings/presentation/widgets/settings_section.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';
import 'settings_backup_authority_test.dart'
    show
        BackupTestAuthRepository,
        BackupTestExercises,
        BackupTestSync,
        initializeBackupTestAuth;
import '../../core/push_settings_test.dart' show FakePush;
import '../auth/offline_auth_test.dart' show SessionApi;

class _Picker extends FilePicker {
  final result = Completer<FilePickerResult?>();
  int calls = 0;
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) {
    calls++;
    expect(type, FileType.custom);
    expect(allowedExtensions, ['json']);
    expect(withData, isTrue);
    return result.future;
  }
}

class _Export extends BackupService {
  _Export(super.db);
  final result = Completer<Uint8List>();
  @override
  Future<Uint8List> exportToBytes() => result.future;
}

void main() {
  Future<AppDatabase> backup(
    WidgetTester tester, {
    bool delayedExport = false,
  }) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        pushClientProvider.overrideWithValue(FakePush()),
        authRepositoryProvider.overrideWithValue(BackupTestAuthRepository()),
        exercisesRepositoryProvider.overrideWithValue(BackupTestExercises(db)),
        syncServiceProvider.overrideWith((ref) => BackupTestSync(db)),
        if (delayedExport) backupServiceProvider.overrideWithValue(_Export(db)),
      ],
    );
    addTearDown(container.dispose);
    await initializeBackupTestAuth(tester, container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FitBirekTheme.dark,
          home: const SettingsBackupPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  for (final outcome in [
    'cancel',
    'missing bytes',
    'invalid JSON',
    'picker error',
  ]) {
    testWidgets('backup $outcome restores controls and does not mutate data', (
      tester,
    ) async {
      final picker = _Picker();
      FilePicker.platform = picker;
      final db = await backup(tester);
      await db
          .into(db.userProfiles)
          .insert(
            UserProfilesCompanion.insert(
              wiek: 40,
              wzrostCm: 180,
              wagaKg: 80,
              cel: 'sila',
              dostepnySprzet: '[]',
            ),
          );
      final profiles = await db.select(db.userProfiles).get();
      final queue = await db.syncDao.pendingOperations();
      await tester.tap(find.text('Import danych (JSON)'));
      await tester.pumpAndSettle();
      expect(
        picker.calls,
        0,
        reason: 'picker only after destructive confirmation',
      );
      await tester.tap(find.text('Zastąp dane'));
      await tester.pump();
      expect(picker.calls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      for (final title in ['Eksport danych (JSON)', 'Import danych (JSON)']) {
        expect(
          tester.widget<ListTile>(find.widgetWithText(ListTile, title)).enabled,
          isFalse,
        );
      }
      if (outcome == 'picker error') {
        picker.result.completeError(StateError('picker unavailable'));
      } else if (outcome == 'cancel') {
        picker.result.complete(null);
      } else {
        picker.result.complete(
          FilePickerResult([
            PlatformFile(
              name: 'backup.json',
              size: 3,
              bytes: outcome == 'missing bytes'
                  ? null
                  : Uint8List.fromList([1, 2, 3]),
            ),
          ]),
        );
      }
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ListTile>(
              find.widgetWithText(ListTile, 'Eksport danych (JSON)'),
            )
            .enabled,
        isTrue,
      );
      if (outcome == 'missing bytes') {
        expect(find.text('Nie udało się odczytać pliku.'), findsOneWidget);
      }
      if (outcome == 'invalid JSON') {
        expect(find.textContaining('Nieprawidłowy plik'), findsOneWidget);
      }
      if (outcome == 'picker error') {
        expect(find.textContaining('Import nie powiódł się'), findsOneWidget);
      }
      expect(await db.select(db.userProfiles).get(), profiles);
      expect(await db.syncDao.pendingOperations(), queue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets(
    'export busy disables both actions; error is visible and unlocks',
    (tester) async {
      await backup(tester, delayedExport: true);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(SettingsBackupPage)),
      );
      final service = c.read(backupServiceProvider) as _Export;
      await tester.tap(find.text('Eksport danych (JSON)'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<ListTile>(
              find.widgetWithText(ListTile, 'Import danych (JSON)'),
            )
            .enabled,
        isFalse,
      );
      service.result.completeError(StateError('export unavailable'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Eksport nie powiódł się'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<ListTile>(
              find.widgetWithText(ListTile, 'Import danych (JSON)'),
            )
            .enabled,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'compact sync preserves held queue, explanation and retry; logout hidden only when requested',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SettingsPageLayout(
                child: SettingsSection(
                  children: [
                    SyncStatusTile(
                      status: SyncStatus.conflict,
                      pending: 17,
                      onRetry: () => retries++,
                      onLogout: () {},
                      showLogout: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Kwarantanna'), findsOneWidget);
      expect(find.textContaining('wstrzymane): 17'), findsOneWidget);
      expect(
        find.textContaining('nie ponawia wstrzymanych operacji'),
        findsOneWidget,
      );
      expect(find.text('Wyloguj'), findsNothing);
      await tester.tap(find.byTooltip('Synchronizuj teraz'));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [true, false]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'push small text $scale dark $dark stays actionable with collapsed instructions and no automatic enable',
        (tester) async {
          tester.view.physicalSize = const Size(320, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final push = FakePush();
          final auth = AuthController(SessionApi());
          await auth.bootstrap();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                pushClientProvider.overrideWithValue(push),
                authStateProvider.overrideWith((ref) => auth),
              ],
              child: MaterialApp(
                theme: dark ? FitBirekTheme.dark : FitBirekTheme.light,
                home: Scaffold(
                  body: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: const SettingsPageLayout(
                      child: SettingsSection(children: [PushSettingsTile()]),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(push.enables, 0);
          final enableSize = tester.getSize(
            find.widgetWithText(FilledButton, 'Włącz Web Push'),
          );
          expect(enableSize.height, greaterThanOrEqualTo(48));
          expect(enableSize.width, greaterThanOrEqualTo(48));
          expect(find.textContaining('iPhone/iPad: Safari'), findsNothing);
          await tester.ensureVisible(find.text('Włącz Web Push'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Włącz Web Push'));
          expect(
            push.enables,
            1,
            reason: 'enable called synchronously in original click gesture',
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
