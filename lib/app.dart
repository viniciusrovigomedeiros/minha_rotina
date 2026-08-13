import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/shared/widgets/main_shell.dart';
import 'state/user_settings_controller.dart';

class MinhaRotinaApp extends ConsumerWidget {
  const MinhaRotinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsControllerProvider).valueOrNull;
    final themeKey = settings?.themeKey ?? 'blue';
    final themeMode = AppTheme.themeModeByKey(
      settings?.themeModeKey ?? 'system',
    );

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeKey: themeKey),
      darkTheme: AppTheme.dark(themeKey: themeKey),
      themeMode: themeMode,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MainShell(),
    );
  }
}
