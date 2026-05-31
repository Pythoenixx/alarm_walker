import 'package:alarm_walker/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primaryAlt,
      surface: Colors.white,
      surfaceContainerHighest: AppColors.lightContainer1,
      outline: AppColors.lightBackgroundText.withValues(alpha: 0.45),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightScaffold1,
      cardColor: Colors.white,
      dividerColor: AppColors.lightBackgroundText.withValues(alpha: 0.30),
      appBarTheme: const AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.lightScaffold1,
        foregroundColor: AppColors.lightBackgroundText,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.lightScaffold1,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: Colors.white,
        borderColor: AppColors.lightBackgroundText.withValues(alpha: 0.35),
        labelColor: AppColors.lightBackgroundText,
      ),
      filledButtonTheme: _filledButtonTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      chipTheme: _chipTheme(
        brightness: Brightness.light,
        selectedColor: AppColors.primary.withValues(alpha: 0.14),
        backgroundColor: AppColors.lightContainer1,
        labelColor: AppColors.lightBackgroundText,
      ),
      snackBarTheme: _snackBarTheme(Brightness.light),
      navigationRailTheme: _navigationRailTheme(),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.lightScaffold1,
        hourMinuteTextColor: AppColors.lightBackgroundText,
        dayPeriodTextColor: AppColors.lightBackgroundText,
        entryModeIconColor: AppColors.lightBackgroundText,
        dialTextColor: AppColors.lightBackgroundText,
        helpTextStyle: TextStyle(
          color: AppColors.darkBackgroundText,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryAlt,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.primaryAlt,
      secondary: AppColors.primaryLight,
      surface: AppColors.darkScaffold1,
      surfaceContainerHighest: AppColors.darkGrey,
      outline: AppColors.darkBackgroundText.withValues(alpha: 0.45),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkScaffold2,
      cardColor: AppColors.darkScaffold1,
      dividerColor: AppColors.darkBackgroundText.withValues(alpha: 0.28),
      appBarTheme: const AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkScaffold1,
        foregroundColor: AppColors.darkBackgroundText,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkScaffold1,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.darkScaffold1,
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: AppColors.darkScaffold1,
        borderColor: AppColors.darkBackgroundText.withValues(alpha: 0.35),
        labelColor: AppColors.darkBackgroundText,
      ),
      filledButtonTheme: _filledButtonTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      chipTheme: _chipTheme(
        brightness: Brightness.dark,
        selectedColor: AppColors.primaryAlt.withValues(alpha: 0.20),
        backgroundColor: AppColors.darkGrey.withValues(alpha: 0.65),
        labelColor: AppColors.darkBackgroundText,
      ),
      snackBarTheme: _snackBarTheme(Brightness.dark),
      navigationRailTheme: _navigationRailTheme(),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.darkScaffold2,
        hourMinuteTextColor: AppColors.darkBackgroundText,
        dayPeriodTextColor: AppColors.darkBackgroundText,
        dialTextColor: AppColors.darkBackgroundText,
        entryModeIconColor: AppColors.darkBackgroundText,
        dialBackgroundColor: AppColors.darkScaffold1,
        helpTextStyle: TextStyle(
          color: AppColors.darkBackgroundText,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  static InputDecorationThemeData _inputDecorationTheme({
    required Color fillColor,
    required Color borderColor,
    required Color labelColor,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: borderColor),
    );

    return InputDecorationThemeData(
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(color: labelColor),
      hintStyle: TextStyle(color: labelColor.withValues(alpha: 0.62)),
      prefixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return AppColors.primary;
        return labelColor;
      }),
      suffixIconColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return AppColors.primary;
        return labelColor;
      }),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border,
      enabledBorder: border,
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme() {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(96, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.primary.withValues(alpha: 0.45);
          }
          return AppColors.primary;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        iconColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: const WidgetStatePropertyAll(Size(96, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.primary.withValues(alpha: 0.45);
          }
          return AppColors.primary;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        iconColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.10),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  static ChipThemeData _chipTheme({
    required Brightness brightness,
    required Color selectedColor,
    required Color backgroundColor,
    required Color labelColor,
  }) {
    return ChipThemeData(
      brightness: brightness,
      selectedColor: selectedColor,
      backgroundColor: backgroundColor,
      disabledColor: backgroundColor.withValues(alpha: 0.45),
      labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: labelColor.withValues(alpha: 0.20)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }

  static SnackBarThemeData _snackBarTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkDeep : AppColors.darkScaffold1,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static NavigationRailThemeData _navigationRailTheme() {
    return NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
      ),
    );
  }
}
