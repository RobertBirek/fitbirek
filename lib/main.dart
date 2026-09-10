import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pl_PL');

  // Auth bootstrap awaits the exercise seed before starting sync, so pulled
  // favorites always have their catalog FK and the seed runs only once.
  runApp(const ProviderScope(child: FitBirekApp()));
}
