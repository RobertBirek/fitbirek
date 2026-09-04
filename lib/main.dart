import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/providers/database_provider.dart';
import 'features/exercises/providers/exercises_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL');

  runApp(
    ProviderScope(
      overrides: const [],
      child: const _AppBootstrap(),
    ),
  );
}

/// Wrapper inicjalizujący import bazy ćwiczeń z assets przy pierwszym starcie.
class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = ref.read(appDatabaseProvider);
    final repo = ref.read(exercisesRepositoryProvider);
    // Wymuszamy inicjalizację bazy (touch), następnie import startowy.
    // ignore: unused_local_variable
    final _ = db;
    await repo.importFromAssetsIfEmpty();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF1A1D23),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
          ),
        ),
      );
    }
    return const FitBirekApp();
  }
}
