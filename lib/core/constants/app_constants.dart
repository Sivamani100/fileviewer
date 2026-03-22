class AppConstants {
  static const String appName = 'FileVault';
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String keyTheme = 'app_theme';
  static const String keyAccentColor = 'app_accent_color';
  static const String keyFileSortOrder = 'file_sort_order';
  static const String keyFileViewMode = 'file_view_mode';
  static const String keyShowHiddenFiles = 'show_hidden_files';
  static const String keyShowFileExtensions = 'show_file_extensions';
  static const String keyPdfScrollMode = 'pdf_scroll_mode';
  static const String keyCodeFontSize = 'code_font_size';
  static const String keyImageBackground = 'image_background';
  static const String keyRecentFiles = 'recent_files';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyFavorites = 'favorites';
  static const String keyOnboardingDone = 'onboarding_done';

  // Default values
  static const int defaultAccentColor = 0xFF1565C0;
  static const String defaultFileSortOrder = 'date_desc';
  static const String defaultFileViewMode = 'list';
  static const String defaultTheme = 'system';
  static const double defaultCodeFontSize = 14.0;
  static const String defaultImageBackground = 'black';
  static const String defaultPdfScrollMode = 'continuous';

  // File operation limits
  static const int maxRecentFiles = 50;
  static const int maxRecentSearches = 10;
  static const int maxSearchResults = 200;
  static const int maxArchiveExtractionDepth = 5;
  static const int maxArchiveExtractedFiles = 10000;
  static const int largeFileSizeThreshold = 50 * 1024 * 1024; // 50MB

  // Performance thresholds
  static const int maxFilesForFastLoad = 500;
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longPressDuration = Duration(milliseconds: 500);

  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double iconSize = 24.0;
  static const double fileIconSize = 40.0;
  static const double thumbnailSize = 60.0;

  // Grid layout
  static const int gridColumnsPortrait = 3;
  static const int gridColumnsLandscape = 5;
  static const double gridAspectRatio = 1.2;

  // Slideshow settings
  static const Duration defaultSlideshowDelay = Duration(seconds: 3);
  static const List<Duration> slideshowDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3),
    Duration(seconds: 4),
    Duration(seconds: 5),
  ];

  // Audio player settings
  static const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  // Font size ranges
  static const double minFontSize = 10.0;
  static const double maxFontSize = 24.0;
  static const double fontSizeStep = 2.0;

  // Zoom ranges
  static const double minZoom = 0.5;
  static const double maxZoomImage = 20.0;
  static const double maxZoomPdf = 10.0;

  // File size formatting
  static const List<String> fileSizeUnits = ['B', 'KB', 'MB', 'GB', 'TB'];

  // Supported accent colors
  static const Map<String, int> accentColors = {
    'Blue': 0xFF1565C0,
    'Green': 0xFF2E7D32,
    'Orange': 0xFFF4511E,
    'Purple': 0xFF6A1B9A,
    'Red': 0xFFE53935,
  };

  // Private constructor to prevent instantiation
  AppConstants._();
}
