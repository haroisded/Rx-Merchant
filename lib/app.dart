import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/db/providers.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';

/// The one theme of the app (00-overview, section 7.1): Material 3, light and
/// dark, both built from a single seed. Widgets take every colour from
/// `Theme.of(context).colorScheme`; this seed is the only literal colour.
abstract final class AppTheme {
  static const _seed = Colors.teal;

  static ThemeData get light => _from(Brightness.light);
  static ThemeData get dark => _from(Brightness.dark);

  static ThemeData _from(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
    // Form fields are outlined everywhere (section 7.1, "Form view").
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // System Settings' Language; the device language until it is read.
      locale: switch (ref.watch(systemSettingsProvider).value?.language) {
        final code? => Locale(code),
        null => null,
      },
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
