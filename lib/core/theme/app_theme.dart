import 'package:flutter/material.dart';

class AppThemeOption {
  const AppThemeOption({
    required this.key,
    required this.label,
    required this.primary,
  });

  final String key;
  final String label;
  final Color primary;
}

class AppTheme {
  const AppTheme._();

  static const List<AppThemeOption> options = [
    AppThemeOption(key: 'blue', label: 'Azul', primary: Color(0xFF5A7DFA)),
    AppThemeOption(key: 'green', label: 'Verde', primary: Color(0xFF2FA36B)),
    AppThemeOption(key: 'purple', label: 'Roxo', primary: Color(0xFF8C63F7)),
    AppThemeOption(key: 'amber', label: 'Âmbar', primary: Color(0xFFE59A2C)),
    AppThemeOption(key: 'teal', label: 'Turquesa', primary: Color(0xFF1BA7A1)),
    AppThemeOption(key: 'rose', label: 'Rosa', primary: Color(0xFFD95C84)),
    AppThemeOption(
      key: 'magenta',
      label: 'Magenta',
      primary: Color(0xFFE6007A),
    ),
    AppThemeOption(
      key: 'fuchsia',
      label: 'Fúcsia',
      primary: Color(0xFFFF2DA6),
    ),
    AppThemeOption(key: 'indigo', label: 'Índigo', primary: Color(0xFF4B63E6)),
    AppThemeOption(key: 'coral', label: 'Coral', primary: Color(0xFFDB6A55)),
  ];

  static AppThemeOption optionByKey(String key) {
    final matches = options.where((item) => item.key == key).toList();
    return matches.isEmpty ? options.first : matches.first;
  }

  static ThemeData light({String themeKey = 'blue'}) {
    final option = optionByKey(themeKey);
    final base = ThemeData.light(useMaterial3: true);
    final baseScheme = ColorScheme.fromSeed(
      seedColor: option.primary,
      brightness: Brightness.light,
    );
    final scaffold = _blend(const Color(0xFFF7F9FD), option.primary, 0.08);
    final surface = _blend(Colors.white, option.primary, 0.03);
    final surfaceContainer = _blend(Colors.white, option.primary, 0.08);
    final outline = _blend(const Color(0xFFD5DDEC), option.primary, 0.28);
    final textPrimary = _blend(const Color(0xFF1F2A44), option.primary, 0.06);
    final textSecondary = _blend(const Color(0xFF6E7891), option.primary, 0.18);
    final colorScheme = baseScheme.copyWith(
      primary: option.primary,
      secondary: baseScheme.secondary,
      tertiary: baseScheme.tertiary,
      surface: surface,
      outline: outline,
      outlineVariant: outline.withValues(alpha: 0.55),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
        ),
      ),
      textTheme: base.textTheme
          .apply(bodyColor: textPrimary, displayColor: textPrimary)
          .copyWith(
            headlineSmall: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
            titleMedium: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
            titleSmall: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: TextStyle(color: textPrimary),
            bodySmall: TextStyle(color: textSecondary),
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: option.primary, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceContainer,
        selectedColor: option.primary.withValues(alpha: 0.18),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: option.primary.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color:
                selected
                    ? option.primary
                    : textSecondary.withValues(alpha: 0.95),
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? textPrimary : textSecondary,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.35),
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: option.primary,
        linearTrackColor: option.primary.withValues(alpha: 0.16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: option.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: option.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static Color _blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t.clamp(0, 1).toDouble()) ?? a;
  }
}
