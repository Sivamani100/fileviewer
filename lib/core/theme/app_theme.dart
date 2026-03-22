import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static const Map<String, int> accentColors = AppConstants.accentColors;

  static ThemeData lightTheme(int accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(accentColor),
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
        surfaceVariant: const Color(0xFFF5F5F5),
        background: const Color(0xFFFAFAFA),
        onBackground: const Color(0xFF1A1A2E),
        onSurface: const Color(0xFF212121),
        error: const Color(0xFFC62828),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: 4,
        ),
      ),
      iconTheme: const IconThemeData(
        size: AppConstants.iconSize,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  static ThemeData darkTheme(int accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Color(accentColor),
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
        surfaceVariant: const Color(0xFF1E1E1E),
        background: const Color(0xFF0D0D0D),
        onBackground: const Color(0xFFE0E0E0),
        onSurface: const Color(0xFFEEEEEE),
        error: const Color(0xFFEF9A9A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A2A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF151515),
        selectedItemColor: Color(0xFF90CAF9),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        color: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppConstants.borderRadius)),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: 4,
        ),
      ),
      iconTheme: const IconThemeData(
        size: AppConstants.iconSize,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE0E0E0),
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
        titleLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
        titleMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE0E0E0),
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFFE0E0E0),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFFE0E0E0),
        ),
        labelSmall: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          fontWeight: FontWeight.normal,
          color: Color(0xFFE0E0E0),
        ),
      ),
    );
  }

  static ThemeMode getThemeMode(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String getThemeModeString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  static Future<void> saveThemePreference(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyTheme, theme);
  }

  static Future<String> getThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyTheme) ?? AppConstants.defaultTheme;
  }

  static Future<void> saveAccentColorPreference(int color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyAccentColor, color);
  }

  static Future<int> getAccentColorPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyAccentColor) ??
        AppConstants.defaultAccentColor;
  }
}
