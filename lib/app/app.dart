import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import 'database_bootstrap.dart';
import '../features/settings/providers/settings_provider.dart';

class FitBirekApp extends StatelessWidget {
  const FitBirekApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const DatabaseBootstrap(child: _ReadyApp());
}

class _ReadyApp extends ConsumerWidget {
  const _ReadyApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'FitBirek',
      debugShowCheckedModeBanner: false,
      theme: FitBirekTheme.light,
      darkTheme: FitBirekTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
      locale: const Locale('pl', 'PL'),
      supportedLocales: const [Locale('pl', 'PL')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
