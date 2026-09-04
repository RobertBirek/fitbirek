import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'router.dart';
import 'theme.dart';
import '../features/settings/providers/settings_provider.dart';

class FitBirekApp extends ConsumerWidget {
  const FitBirekApp({super.key});

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
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
