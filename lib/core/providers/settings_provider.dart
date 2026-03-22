import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

class SettingsState {
  final ThemeMode themeMode;
  final int accentColor;
  final String fileViewMode;
  final String fileSortOrder;
  final bool showHiddenFiles;
  final bool showFileExtensions;
  final String pdfScrollMode;
  final double codeFontSize;
  final String imageBackground;
  final List<String> recentFiles;
  final List<String> recentSearches;
  final List<String> favorites;
  final bool onboardingDone;

  const SettingsState({
    required this.themeMode,
    required this.accentColor,
    required this.fileViewMode,
    required this.fileSortOrder,
    required this.showHiddenFiles,
    required this.showFileExtensions,
    required this.pdfScrollMode,
    required this.codeFontSize,
    required this.imageBackground,
    required this.recentFiles,
    required this.recentSearches,
    required this.favorites,
    required this.onboardingDone,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? accentColor,
    String? fileViewMode,
    String? fileSortOrder,
    bool? showHiddenFiles,
    bool? showFileExtensions,
    String? pdfScrollMode,
    double? codeFontSize,
    String? imageBackground,
    List<String>? recentFiles,
    List<String>? recentSearches,
    List<String>? favorites,
    bool? onboardingDone,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      fileViewMode: fileViewMode ?? this.fileViewMode,
      fileSortOrder: fileSortOrder ?? this.fileSortOrder,
      showHiddenFiles: showHiddenFiles ?? this.showHiddenFiles,
      showFileExtensions: showFileExtensions ?? this.showFileExtensions,
      pdfScrollMode: pdfScrollMode ?? this.pdfScrollMode,
      codeFontSize: codeFontSize ?? this.codeFontSize,
      imageBackground: imageBackground ?? this.imageBackground,
      recentFiles: recentFiles ?? this.recentFiles,
      recentSearches: recentSearches ?? this.recentSearches,
      favorites: favorites ?? this.favorites,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          themeMode: AppTheme.getThemeMode(AppConstants.defaultTheme),
          accentColor: AppConstants.defaultAccentColor,
          fileViewMode: AppConstants.defaultFileViewMode,
          fileSortOrder: AppConstants.defaultFileSortOrder,
          showHiddenFiles: false,
          showFileExtensions: true,
          pdfScrollMode: AppConstants.defaultPdfScrollMode,
          codeFontSize: AppConstants.defaultCodeFontSize,
          imageBackground: AppConstants.defaultImageBackground,
          recentFiles: [],
          recentSearches: [],
          favorites: [],
          onboardingDone: false,
        ));

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeString =
          prefs.getString(AppConstants.keyTheme) ?? AppConstants.defaultTheme;
      final accentColor = prefs.getInt(AppConstants.keyAccentColor) ??
          AppConstants.defaultAccentColor;
      final fileViewMode = prefs.getString(AppConstants.keyFileViewMode) ??
          AppConstants.defaultFileViewMode;
      final fileSortOrder = prefs.getString(AppConstants.keyFileSortOrder) ??
          AppConstants.defaultFileSortOrder;
      final showHiddenFiles =
          prefs.getBool(AppConstants.keyShowHiddenFiles) ?? false;
      final showFileExtensions =
          prefs.getBool(AppConstants.keyShowFileExtensions) ?? true;
      final pdfScrollMode = prefs.getString(AppConstants.keyPdfScrollMode) ??
          AppConstants.defaultPdfScrollMode;
      final codeFontSize = prefs.getDouble(AppConstants.keyCodeFontSize) ??
          AppConstants.defaultCodeFontSize;
      final imageBackground =
          prefs.getString(AppConstants.keyImageBackground) ??
              AppConstants.defaultImageBackground;
      final recentFiles =
          prefs.getStringList(AppConstants.keyRecentFiles) ?? [];
      final recentSearches =
          prefs.getStringList(AppConstants.keyRecentSearches) ?? [];
      final favorites = prefs.getStringList(AppConstants.keyFavorites) ?? [];
      final onboardingDone =
          prefs.getBool(AppConstants.keyOnboardingDone) ?? false;

      state = SettingsState(
        themeMode: AppTheme.getThemeMode(themeString),
        accentColor: accentColor,
        fileViewMode: fileViewMode,
        fileSortOrder: fileSortOrder,
        showHiddenFiles: showHiddenFiles,
        showFileExtensions: showFileExtensions,
        pdfScrollMode: pdfScrollMode,
        codeFontSize: codeFontSize,
        imageBackground: imageBackground,
        recentFiles: recentFiles,
        recentSearches: recentSearches,
        favorites: favorites,
        onboardingDone: onboardingDone,
      );
    } catch (e) {
      // Keep default values if loading fails
    }
  }

  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.keyTheme, AppTheme.getThemeModeString(themeMode));
    state = state.copyWith(themeMode: themeMode);
  }

  Future<void> saveAccentColor(int accentColor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyAccentColor, accentColor);
    state = state.copyWith(accentColor: accentColor);
  }

  Future<void> saveFileViewMode(String fileViewMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyFileViewMode, fileViewMode);
    state = state.copyWith(fileViewMode: fileViewMode);
  }

  Future<void> saveFileSortOrder(String fileSortOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyFileSortOrder, fileSortOrder);
    state = state.copyWith(fileSortOrder: fileSortOrder);
  }

  Future<void> saveShowHiddenFiles(bool showHiddenFiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyShowHiddenFiles, showHiddenFiles);
    state = state.copyWith(showHiddenFiles: showHiddenFiles);
  }

  Future<void> saveShowFileExtensions(bool showFileExtensions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyShowFileExtensions, showFileExtensions);
    state = state.copyWith(showFileExtensions: showFileExtensions);
  }

  Future<void> savePdfScrollMode(String pdfScrollMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPdfScrollMode, pdfScrollMode);
    state = state.copyWith(pdfScrollMode: pdfScrollMode);
  }

  Future<void> saveCodeFontSize(double codeFontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyCodeFontSize, codeFontSize);
    state = state.copyWith(codeFontSize: codeFontSize);
  }

  Future<void> saveImageBackground(String imageBackground) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyImageBackground, imageBackground);
    state = state.copyWith(imageBackground: imageBackground);
  }

  Future<void> addToRecentFiles(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    var updatedRecentFiles = List<String>.from(state.recentFiles);

    // Remove if already exists and move to front
    updatedRecentFiles.remove(filePath);
    updatedRecentFiles.insert(0, filePath);

    // Keep only the most recent files
    if (updatedRecentFiles.length > AppConstants.maxRecentFiles) {
      updatedRecentFiles =
          updatedRecentFiles.take(AppConstants.maxRecentFiles).toList();
    }

    await prefs.setStringList(AppConstants.keyRecentFiles, updatedRecentFiles);
    state = state.copyWith(recentFiles: updatedRecentFiles);
  }

  Future<void> removeFromRecentFiles(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedRecentFiles = List<String>.from(state.recentFiles);
    updatedRecentFiles.remove(filePath);
    await prefs.setStringList(AppConstants.keyRecentFiles, updatedRecentFiles);
    state = state.copyWith(recentFiles: updatedRecentFiles);
  }

  Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keyRecentFiles, []);
    state = state.copyWith(recentFiles: []);
  }

  Future<void> addToRecentSearches(String query) async {
    final prefs = await SharedPreferences.getInstance();
    var updatedRecentSearches = List<String>.from(state.recentSearches);

    // Remove if already exists and move to front
    updatedRecentSearches.remove(query);
    updatedRecentSearches.insert(0, query);

    // Keep only the most recent searches
    if (updatedRecentSearches.length > AppConstants.maxRecentSearches) {
      updatedRecentSearches =
          updatedRecentSearches.take(AppConstants.maxRecentSearches).toList();
    }

    await prefs.setStringList(
        AppConstants.keyRecentSearches, updatedRecentSearches);
    state = state.copyWith(recentSearches: updatedRecentSearches);
  }

  Future<void> addToFavorites(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedFavorites = List<String>.from(state.favorites);

    if (!updatedFavorites.contains(filePath)) {
      updatedFavorites.add(filePath);
      await prefs.setStringList(AppConstants.keyFavorites, updatedFavorites);
      state = state.copyWith(favorites: updatedFavorites);
    }
  }

  Future<void> removeFromFavorites(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedFavorites = List<String>.from(state.favorites);
    updatedFavorites.remove(filePath);
    await prefs.setStringList(AppConstants.keyFavorites, updatedFavorites);
    state = state.copyWith(favorites: updatedFavorites);
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingDone, true);
    state = state.copyWith(onboardingDone: true);
  }
}

// Provider for the settings state
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
