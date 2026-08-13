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

class AppThemeModeOption {
  const AppThemeModeOption({
    required this.key,
    required this.label,
    required this.mode,
  });

  final String key;
  final String label;
  final ThemeMode mode;
}

@immutable
class AppThemePalette extends ThemeExtension<AppThemePalette> {
  const AppThemePalette({
    required this.successFill,
    required this.successBorder,
    required this.successForeground,
    required this.warningFill,
    required this.warningBorder,
    required this.warningForeground,
    required this.infoFill,
    required this.infoBorder,
    required this.infoForeground,
    required this.neutralFill,
    required this.neutralBorder,
    required this.neutralForeground,
    required this.glassBackground,
    required this.glassBorder,
    required this.glassGradientStart,
    required this.glassGradientEnd,
  });

  final Color successFill;
  final Color successBorder;
  final Color successForeground;
  final Color warningFill;
  final Color warningBorder;
  final Color warningForeground;
  final Color infoFill;
  final Color infoBorder;
  final Color infoForeground;
  final Color neutralFill;
  final Color neutralBorder;
  final Color neutralForeground;
  final Color glassBackground;
  final Color glassBorder;
  final Color glassGradientStart;
  final Color glassGradientEnd;

  @override
  AppThemePalette copyWith({
    Color? successFill,
    Color? successBorder,
    Color? successForeground,
    Color? warningFill,
    Color? warningBorder,
    Color? warningForeground,
    Color? infoFill,
    Color? infoBorder,
    Color? infoForeground,
    Color? neutralFill,
    Color? neutralBorder,
    Color? neutralForeground,
    Color? glassBackground,
    Color? glassBorder,
    Color? glassGradientStart,
    Color? glassGradientEnd,
  }) {
    return AppThemePalette(
      successFill: successFill ?? this.successFill,
      successBorder: successBorder ?? this.successBorder,
      successForeground: successForeground ?? this.successForeground,
      warningFill: warningFill ?? this.warningFill,
      warningBorder: warningBorder ?? this.warningBorder,
      warningForeground: warningForeground ?? this.warningForeground,
      infoFill: infoFill ?? this.infoFill,
      infoBorder: infoBorder ?? this.infoBorder,
      infoForeground: infoForeground ?? this.infoForeground,
      neutralFill: neutralFill ?? this.neutralFill,
      neutralBorder: neutralBorder ?? this.neutralBorder,
      neutralForeground: neutralForeground ?? this.neutralForeground,
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      glassGradientStart: glassGradientStart ?? this.glassGradientStart,
      glassGradientEnd: glassGradientEnd ?? this.glassGradientEnd,
    );
  }

  @override
  AppThemePalette lerp(ThemeExtension<AppThemePalette>? other, double t) {
    if (other is! AppThemePalette) return this;
    return AppThemePalette(
      successFill: Color.lerp(successFill, other.successFill, t) ?? successFill,
      successBorder:
          Color.lerp(successBorder, other.successBorder, t) ?? successBorder,
      successForeground:
          Color.lerp(successForeground, other.successForeground, t) ??
          successForeground,
      warningFill: Color.lerp(warningFill, other.warningFill, t) ?? warningFill,
      warningBorder:
          Color.lerp(warningBorder, other.warningBorder, t) ?? warningBorder,
      warningForeground:
          Color.lerp(warningForeground, other.warningForeground, t) ??
          warningForeground,
      infoFill: Color.lerp(infoFill, other.infoFill, t) ?? infoFill,
      infoBorder: Color.lerp(infoBorder, other.infoBorder, t) ?? infoBorder,
      infoForeground:
          Color.lerp(infoForeground, other.infoForeground, t) ?? infoForeground,
      neutralFill: Color.lerp(neutralFill, other.neutralFill, t) ?? neutralFill,
      neutralBorder:
          Color.lerp(neutralBorder, other.neutralBorder, t) ?? neutralBorder,
      neutralForeground:
          Color.lerp(neutralForeground, other.neutralForeground, t) ??
          neutralForeground,
      glassBackground:
          Color.lerp(glassBackground, other.glassBackground, t) ??
          glassBackground,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t) ?? glassBorder,
      glassGradientStart:
          Color.lerp(glassGradientStart, other.glassGradientStart, t) ??
          glassGradientStart,
      glassGradientEnd:
          Color.lerp(glassGradientEnd, other.glassGradientEnd, t) ??
          glassGradientEnd,
    );
  }
}

extension AppThemePaletteContext on BuildContext {
  AppThemePalette get appPalette {
    final palette = Theme.of(this).extension<AppThemePalette>();
    assert(palette != null, 'AppThemePalette extension is missing from theme.');
    return palette!;
  }
}

class AppTheme {
  const AppTheme._();

  static const List<AppThemeOption> options = [
    AppThemeOption(key: 'blue', label: 'Azul', primary: Color(0xFF5A7DFA)),
    AppThemeOption(key: 'green', label: 'Verde', primary: Color(0xFF2FA36B)),
    AppThemeOption(key: 'purple', label: 'Roxo', primary: Color(0xFF8C63F7)),
    AppThemeOption(key: 'amber', label: 'Ambar', primary: Color(0xFFE59A2C)),
    AppThemeOption(key: 'teal', label: 'Turquesa', primary: Color(0xFF1BA7A1)),
    AppThemeOption(key: 'rose', label: 'Rosa', primary: Color(0xFFD95C84)),
    AppThemeOption(
      key: 'magenta',
      label: 'Magenta',
      primary: Color(0xFFE6007A),
    ),
    AppThemeOption(key: 'fuchsia', label: 'Fucsia', primary: Color(0xFFFF2DA6)),
    AppThemeOption(key: 'indigo', label: 'Indigo', primary: Color(0xFF4B63E6)),
    AppThemeOption(key: 'coral', label: 'Coral', primary: Color(0xFFDB6A55)),
  ];

  static const List<AppThemeModeOption> themeModeOptions = [
    AppThemeModeOption(key: 'system', label: 'Sistema', mode: ThemeMode.system),
    AppThemeModeOption(key: 'light', label: 'Claro', mode: ThemeMode.light),
    AppThemeModeOption(key: 'dark', label: 'Escuro', mode: ThemeMode.dark),
  ];

  static AppThemeOption optionByKey(String key) {
    final matches = options.where((item) => item.key == key).toList();
    return matches.isEmpty ? options.first : matches.first;
  }

  static ThemeMode themeModeByKey(String key) {
    final matches = themeModeOptions.where((item) => item.key == key).toList();
    return matches.isEmpty ? ThemeMode.system : matches.first.mode;
  }

  static ThemeData light({String themeKey = 'blue'}) {
    return _buildTheme(themeKey: themeKey, brightness: Brightness.light);
  }

  static ThemeData dark({String themeKey = 'blue'}) {
    return _buildTheme(themeKey: themeKey, brightness: Brightness.dark);
  }

  static ThemeData _buildTheme({
    required String themeKey,
    required Brightness brightness,
  }) {
    final option = optionByKey(themeKey);
    final isDark = brightness == Brightness.dark;
    final base =
        isDark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true);
    final baseScheme = ColorScheme.fromSeed(
      seedColor: option.primary,
      brightness: brightness,
    );
    final scaffold =
        isDark
            ? _blend(const Color(0xFF090909), option.primary, 0.03)
            : _blend(const Color(0xFFF7F9FD), option.primary, 0.08);
    final surface =
        isDark
            ? _blend(const Color(0xFF121212), option.primary, 0.04)
            : _blend(Colors.white, option.primary, 0.03);
    final surfaceContainer =
        isDark
            ? _blend(const Color(0xFF181818), option.primary, 0.05)
            : _blend(Colors.white, option.primary, 0.08);
    final surfaceContainerHigh =
        isDark
            ? _blend(const Color(0xFF202020), option.primary, 0.05)
            : _blend(const Color(0xFFF5F7FC), option.primary, 0.10);
    final outline =
        isDark
            ? _blend(const Color(0xFF3A3A3A), option.primary, 0.08)
            : _blend(const Color(0xFFD5DDEC), option.primary, 0.28);
    final textPrimary =
        isDark
            ? _blend(const Color(0xFFF5F5F5), option.primary, 0.02)
            : _blend(const Color(0xFF1F2A44), option.primary, 0.06);
    final textSecondary =
        isDark
            ? _blend(const Color(0xFFA7A7A7), option.primary, 0.02)
            : _blend(const Color(0xFF6E7891), option.primary, 0.18);
    final colorScheme = baseScheme.copyWith(
      primary: option.primary,
      secondary: baseScheme.secondary,
      tertiary: baseScheme.tertiary,
      surface: surface,
      onSurface: textPrimary,
      outline: outline,
      outlineVariant: outline.withValues(alpha: isDark ? 0.78 : 0.55),
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHigh,
      surfaceContainerLow:
          isDark
              ? _blend(const Color(0xFF141414), option.primary, 0.03)
              : _blend(Colors.white, option.primary, 0.04),
      surfaceContainerLowest:
          isDark
              ? const Color(0xFF0D0D0D)
              : _blend(Colors.white, option.primary, 0.02),
    );
    final palette = _buildPalette(
      isDark: isDark,
      primary: option.primary,
      surface: surface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      colorScheme: colorScheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: base.textTheme
          .apply(bodyColor: textPrimary, displayColor: textPrimary)
          .copyWith(
            headlineSmall: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
            titleLarge: TextStyle(
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
            labelSmall: TextStyle(color: textSecondary),
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
        selectedColor: option.primary.withValues(alpha: isDark ? 0.18 : 0.18),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: option.primary.withValues(alpha: isDark ? 0.18 : 0.16),
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
        linearTrackColor: option.primary.withValues(
          alpha: isDark ? 0.14 : 0.16,
        ),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
      ).copyWith(backgroundColor: option.primary),
    );
  }

  static AppThemePalette _buildPalette({
    required bool isDark,
    required Color primary,
    required Color surface,
  }) {
    if (isDark) {
      return AppThemePalette(
        successFill: const Color(0xFF16281F),
        successBorder: const Color(0xFF27543C),
        successForeground: const Color(0xFF7FD6A8),
        warningFill: const Color(0xFF332512),
        warningBorder: const Color(0xFF715629),
        warningForeground: const Color(0xFFF0C267),
        infoFill: _blend(const Color(0xFF171717), primary, 0.08),
        infoBorder: _blend(const Color(0xFF2A2A2A), primary, 0.16),
        infoForeground: _blend(const Color(0xFFC8D5FF), primary, 0.06),
        neutralFill: const Color(0xFF171717),
        neutralBorder: const Color(0xFF2A2A2A),
        neutralForeground: const Color(0xFF9A9A9A),
        glassBackground: Colors.black.withValues(alpha: 0.50),
        glassBorder: Colors.white.withValues(alpha: 0.06),
        glassGradientStart: Colors.white.withValues(alpha: 0.06),
        glassGradientEnd: surface.withValues(alpha: 0.08),
      );
    }

    return const AppThemePalette(
      successFill: Color(0xFFE3F3EA),
      successBorder: Color(0xFFC8E7D8),
      successForeground: Color(0xFF2E9E6E),
      warningFill: Color(0xFFF6EAD9),
      warningBorder: Color(0xFFEFD9BC),
      warningForeground: Color(0xFFB9832C),
      infoFill: Color(0xFFEAF2FF),
      infoBorder: Color(0xFFC8DAFF),
      infoForeground: Color(0xFF4268D6),
      neutralFill: Color(0xFFF4F6FB),
      neutralBorder: Color(0xFFE1E6F1),
      neutralForeground: Color(0xFF98A3BA),
      glassBackground: Color(0x33FFFFFF),
      glassBorder: Color(0x3DFFFFFF),
      glassGradientStart: Color(0x57FFFFFF),
      glassGradientEnd: Color(0x24FFFFFF),
    );
  }

  static Color _blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t.clamp(0, 1).toDouble()) ?? a;
  }
}
