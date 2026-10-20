import 'dart:async';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Test the plugin boundary without writing private bytes to temporary files.
// ignore: depend_on_referenced_packages
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitbirek_training/app/router.dart';
import 'package:fitbirek_training/core/database/app_database.dart';
import 'package:fitbirek_training/core/providers/database_provider.dart';
import 'package:fitbirek_training/core/providers/notification_provider.dart';
import 'package:fitbirek_training/core/push/push_provider.dart';
import 'package:fitbirek_training/core/services/backup_service.dart';
import 'package:fitbirek_training/features/auth/data/auth_repository.dart';
import 'package:fitbirek_training/features/auth/providers/auth_providers.dart';
import 'package:fitbirek_training/features/settings/presentation/pages/settings_backup_page.dart';
import '../../core/profile_collections_sync_test.dart' show CollectionServer;
import '../../core/push_settings_test.dart' show FakePush;
import '../schedule/schedule_router_start_test.dart' show LocalNotifications;
import 'package:fitbirek_training/core/sync/sync_service.dart';
import 'package:fitbirek_training/features/exercises/data/exercises_repository.dart';
import 'package:fitbirek_training/features/exercises/providers/exercises_providers.dart';

class BackupTestExercises extends ExercisesRepository {
  BackupTestExercises(super.db);
  @override
  Future<void> syncFromAssets() async {}
}

// Adversarial account replacement fixture only. Production SyncService keeps
// its stricter same-database account policy; the UI must also reject ABA itself.
class BackupTestSync extends SyncService {
  BackupTestSync(AppDatabase db) : super(db, CollectionServer());
  @override
  Future<void> bindAccount(String accountId) async {
    await db
        .into(db.syncState)
        .insertOnConflictUpdate(
          SyncStateCompanion.insert(
            id: const Value(1),
            accountId: accountId,
            // Deliberately restore the same ID on A-B-A: epoch must still win.
            deviceId: 'test-binding-$accountId',
            offlineAccess: const Value(true),
          ),
        );
  }

  @override
  void start() {}
}

class BackupTestAuthRepository extends Fake implements AuthRepository {
  String account = 'account';
  @override
  Future<AuthSession?> getSession() async => AuthSession(accountId: account);
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => AuthSession(accountId: account);
  @override
  Future<void> logout() async {}
}

class _DelayedBackup extends BackupService {
  _DelayedBackup(super.db);
  final exported = Completer<Uint8List>();
  int exports = 0, imports = 0;
  Completer<void>? importGate;
  final importRestored = Completer<void>();
  @override
  Future<Uint8List> exportToBytes() {
    exports++;
    return exported.future;
  }

  @override
  Future<ImportResult> importFromBytes(Uint8List bytes) async {
    imports++;
    final result = await super.importFromBytes(bytes);
    if (!importRestored.isCompleted) importRestored.complete();
    await importGate?.future;
    return result;
  }
}

class _Share extends SharePlatform {
  final calls = <List<XFile>>[];
  @override
  Future<ShareResult> shareXFiles(
    List<XFile> files, {
    String? subject,
    String? text,
    Rect? sharePositionOrigin,
    List<String>? fileNameOverrides,
  }) async {
    calls.add(files);
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

class _Picker extends FilePicker {
  final result = Completer<FilePickerResult?>();
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
  }) => result.future;
}

Future<void> initializeBackupTestAuth(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final controller = container.read(authStateProvider.notifier);
  await tester.pump(); // drain the provider's scheduled bootstrap first
  await controller.bootstrap();
  expect(container.read(authStateProvider).isSignedIn, isTrue);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<
    ({
      ProviderContainer container,
      _DelayedBackup backup,
      BackupTestAuthRepository api,
      _Share share,
    })
  >
  mount(WidgetTester tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final backup = _DelayedBackup(db);
    final api = BackupTestAuthRepository();
    final share = _Share();
    final oldShare = SharePlatform.instance;
    SharePlatform.instance = share;
    addTearDown(() => SharePlatform.instance = oldShare);
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        backupServiceProvider.overrideWithValue(backup),
        authRepositoryProvider.overrideWithValue(api),
        pushClientProvider.overrideWithValue(FakePush()),
        notificationServiceProvider.overrideWithValue(LocalNotifications()),
        syncServiceProvider.overrideWith((ref) => BackupTestSync(db)),
        exercisesRepositoryProvider.overrideWithValue(BackupTestExercises(db)),
      ],
    );
    addTearDown(() async {
      c.dispose();
      await db.close();
    });
    // Keep the production auth provider: it maintains the passive authority epoch.
    await initializeBackupTestAuth(tester, c);
    final router = createRouter(
      readAuthState: () => c.read(authStateProvider),
      readOnboardingComplete: () => true,
      initialLocation: '/settings/backup',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return (container: c, backup: backup, api: api, share: share);
  }

  testWidgets(
    'delayed export then real back and footer logout never shares old private bytes',
    (tester) async {
      final f = await mount(tester);
      await tester.tap(find.text('Eksport danych (JSON)'));
      await tester.pump();
      expect(f.backup.exports, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Wyloguj'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wyloguj'));
      await tester.pumpAndSettle();
      expect(f.container.read(authStateProvider).isSignedOut, isTrue);
      f.backup.exported.complete(Uint8List.fromList([11, 22, 33]));
      await tester.pumpAndSettle();
      expect(f.share.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'mounted export A-B-A rejects stale epoch despite same final account',
    (tester) async {
      final f = await mount(tester);
      final page = tester.element(find.byType(SettingsBackupPage));
      final authority = f.container.read(cachedAuthWriteAuthorityProvider);
      final epoch = authority.epoch;
      final binding = (await f.backup.db.syncDao.readState())!.deviceId;
      await tester.tap(find.text('Eksport danych (JSON)'));
      await tester.pump();
      await tester.runAsync(() async {
        f.api.account = 'other-account';
        await f.container
            .read(authStateProvider.notifier)
            .login('b', 'password');
        f.api.account = 'account';
        await f.container
            .read(authStateProvider.notifier)
            .login('a', 'password');
      });
      await tester.pump();
      expect(tester.element(find.byType(SettingsBackupPage)), same(page));
      expect(authority.epoch, greaterThan(epoch));
      expect(authority.state?.accountId, 'account');
      expect((await f.backup.db.syncDao.readState())!.deviceId, binding);
      f.backup.exported.complete(Uint8List.fromList([11, 22, 33]));
      await tester.pumpAndSettle();
      expect(f.share.calls, isEmpty);
      expect(find.textContaining('Eksport gotowy'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('current account exports and shares exactly once', (
    tester,
  ) async {
    final f = await mount(tester);
    await tester.tap(find.text('Eksport danych (JSON)'));
    await tester.pump();
    final bytes = Uint8List.fromList([11, 22, 33]);
    f.backup.exported.complete(bytes);
    await tester.pumpAndSettle();
    expect(f.share.calls, hasLength(1));
    expect(await f.share.calls.single.single.readAsBytes(), bytes);
    expect(find.textContaining('Eksport gotowy'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'delayed import picker then back and logout cannot invoke destructive import',
    (tester) async {
      final f = await mount(tester);
      final picker = _Picker();
      FilePicker.platform = picker;
      await tester.tap(find.text('Import danych (JSON)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zastąp dane'));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Wyloguj'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wyloguj'));
      await tester.pumpAndSettle();
      picker.result.complete(
        FilePickerResult([
          PlatformFile(
            name: 'backup.json',
            size: 2,
            bytes: Uint8List.fromList([123, 125]),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(f.backup.imports, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'import picker A-B-A never applies the previous account selection',
    (tester) async {
      final f = await mount(tester);
      final picker = _Picker();
      FilePicker.platform = picker;
      await tester.tap(find.text('Import danych (JSON)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zastąp dane'));
      await tester.pump();
      await tester.runAsync(() async {
        f.api.account = 'other-account';
        await f.container
            .read(authStateProvider.notifier)
            .login('b', 'password');
        f.api.account = 'account';
        await f.container
            .read(authStateProvider.notifier)
            .login('a', 'password');
      });
      picker.result.complete(
        FilePickerResult([
          PlatformFile(
            name: 'backup.json',
            size: 2,
            bytes: Uint8List.fromList([123, 125]),
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(f.backup.imports, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('durable revocation before export completes prevents Share', (
    tester,
  ) async {
    final f = await mount(tester);
    await tester.tap(find.text('Eksport danych (JSON)'));
    await tester.pump();
    await f.backup.db.syncDao.lockOfflineAccess();
    f.backup.exported.complete(Uint8List.fromList([11, 22, 33]));
    await tester.pumpAndSettle();
    expect(f.share.calls, isEmpty);
    expect(find.textContaining('Eksport gotowy'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'export completing during the back transition is cancelled before dispose',
    (tester) async {
      final f = await mount(tester);
      await tester.tap(find.text('Eksport danych (JSON)'));
      await tester.pump();
      await tester.pageBack();
      f.backup.exported.complete(Uint8List.fromList([11, 22, 33]));
      await tester.pumpAndSettle();
      expect(f.share.calls, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  for (final cancel in [true, false]) {
    testWidgets(
      'real restore cancel=$cancel rolls back on back or commits for current account',
      (tester) async {
        final f = await mount(tester);
        final db = f.backup.db;
        final bytes = await BackupService(db).exportToBytes();
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
        final before = await db.select(db.userProfiles).get();
        final picker = _Picker();
        FilePicker.platform = picker;
        f.backup.importGate = Completer<void>();
        await tester.tap(find.text('Import danych (JSON)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Zastąp dane'));
        await tester.pump();
        picker.result.complete(
          FilePickerResult([
            PlatformFile(name: 'backup.json', size: bytes.length, bytes: bytes),
          ]),
        );
        for (
          var frame = 0;
          frame < 50 && !f.backup.importRestored.isCompleted;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 1));
        }
        expect(f.backup.importRestored.isCompleted, isTrue);
        if (cancel) {
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
        f.backup.importGate!.complete();
        await tester.pumpAndSettle();
        expect(
          await db.select(db.userProfiles).get(),
          cancel ? before : isEmpty,
        );
        expect(
          find.textContaining('Import zakończony'),
          cancel ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }
}
