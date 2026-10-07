import 'package:flutter/material.dart';

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

  static const List<AppThemeModeOption> themeModeOptions = [
    AppThemeModeOption(key: 'system', label: 'Sistema', mode: ThemeMode.system),
    AppThemeModeOption(key: 'dark', label: 'Escuro', mode: ThemeMode.dark),
    AppThemeModeOption(key: 'light', label: 'Claro', mode: ThemeMode.light),
  ];

  static ThemeMode themeModeByKey(String key) {
    final matches = themeModeOptions.where((item) => item.key == key).toList();
    return matches.isEmpty ? ThemeMode.dark : matches.first.mode;
  }

  static ThemeData light() {
    return _buildTheme(brightness: Brightness.light);
  }

  static ThemeData dark() {
    return _buildTheme(brightness: Brightness.dark);
  }

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    const lightBlue = Color(0xFF5A7DFA);
    const darkAccent = Color(0xFF1DB954);
    final primary = isDark ? darkAccent : lightBlue;
    final base =
        isDark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true);
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    final scaffold =
        isDark
            ? const Color(0xFF121212)
            : _blend(const Color(0xFFF7F9FD), primary, 0.08);
    final surface =
        isDark ? const Color(0xFF181818) : _blend(Colors.white, primary, 0.03);
    final surfaceContainer =
        isDark ? const Color(0xFF1E1E1E) : _blend(Colors.white, primary, 0.08);
    final surfaceContainerHigh =
        isDark
            ? const Color(0xFF282828)
            : _blend(const Color(0xFFF5F7FC), primary, 0.10);
    final outline =
        isDark
            ? const Color(0xFF3A3A3A)
            : _blend(const Color(0xFFD5DDEC), primary, 0.28);
    final textPrimary =
        isDark
            ? const Color(0xFFFFFFFF)
            : _blend(const Color(0xFF1F2A44), primary, 0.06);
    final textSecondary =
        isDark
            ? const Color(0xFFB3B3B3)
            : _blend(const Color(0xFF6E7891), primary, 0.18);
    final colorScheme = baseScheme.copyWith(
      primary: primary,
      secondary: isDark ? primary : baseScheme.secondary,
      tertiary: isDark ? primary : baseScheme.tertiary,
      surface: surface,
      onSurface: textPrimary,
      outline: outline,
      outlineVariant: outline.withValues(alpha: isDark ? 0.78 : 0.55),
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHigh,
      surfaceContainerLow:
          isDark
              ? const Color(0xFF151515)
              : _blend(Colors.white, primary, 0.04),
      surfaceContainerLowest:
          isDark
              ? const Color(0xFF0B0B0B)
              : _blend(Colors.white, primary, 0.02),
    );
    final palette = _buildPalette(
      isDark: isDark,
      primary: primary,
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
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceContainer,
        selectedColor: primary.withValues(alpha: isDark ? 0.18 : 0.18),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: isDark ? 0.18 : 0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : textSecondary.withValues(alpha: 0.95),
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
        color: primary,
        linearTrackColor: primary.withValues(alpha: isDark ? 0.14 : 0.16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
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
      ).copyWith(backgroundColor: primary),
    );
  }

  static AppThemePalette _buildPalette({
    required bool isDark,
    required Color primary,
    required Color surface,
  }) {
    if (isDark) {
      return AppThemePalette(
        successFill: const Color(0xFF1E1E1E),
        successBorder: const Color(0xFF3A3A3A),
        successForeground: primary,
        warningFill: const Color(0xFF1E1E1E),
        warningBorder: const Color(0xFF3A3A3A),
        warningForeground: const Color(0xFFB3B3B3),
        infoFill: const Color(0xFF1E1E1E),
        infoBorder: const Color(0xFF3A3A3A),
        infoForeground: primary,
        neutralFill: const Color(0xFF171717),
        neutralBorder: const Color(0xFF2A2A2A),
        neutralForeground: const Color(0xFF9A9A9A),
        glassBackground: Colors.black.withValues(alpha: 0.50),
        glassBorder: Colors.white.withValues(alpha: 0.06),
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
    );
  }

  static Color _blend(Color a, Color b, double t) {
    return Color.lerp(a, b, t.clamp(0, 1).toDouble()) ?? a;
  }
}
