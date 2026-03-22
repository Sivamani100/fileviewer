import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/file_utils.dart';
import '../features/file_manager/file_manager_screen.dart';
import '../features/recents/recents_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/viewers/pdf/pdf_viewer_screen.dart';
import '../features/viewers/image/image_viewer_screen.dart';
import '../features/viewers/audio/audio_player_screen.dart';
import '../features/viewers/video/video_player_screen.dart';
import '../features/viewers/code/code_viewer_screen.dart';
import '../features/viewers/archive/archive_viewer_screen.dart';
import '../features/viewers/epub/epub_viewer_screen.dart';
import '../features/viewers/email/email_viewer_screen.dart';
import '../features/viewers/apk/apk_viewer_screen.dart';
import '../features/viewers/word/word_viewer_screen.dart';
import '../features/viewers/excel/excel_viewer_screen.dart';
import '../features/viewers/powerpoint/powerpoint_viewer_screen.dart';
import '../features/file_info/file_info_sheet.dart';

import '../features/viewers/text/text_viewer_screen.dart';
import '../features/viewers/html/html_viewer_screen.dart';
import '../features/viewers/universal/universal_viewer_screen.dart';

class UnknownFileScreen extends StatelessWidget {
  final String filePath;
  const UnknownFileScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unknown File')),
      body: const Center(child: Text('Unknown file type')),
    );
  }
}

class AppRouter {
  static const String initialLocation = '/files';

  static String getViewerRouteForFile(String filePath) {
    if (FileUtils.isPdfFile(filePath)) return '/viewer/pdf';
    if (FileUtils.isWordFile(filePath)) return '/viewer/word';
    if (FileUtils.isExcelFile(filePath)) return '/viewer/excel';
    if (FileUtils.isPowerPointFile(filePath)) return '/viewer/powerpoint';
    if (FileUtils.isTextFile(filePath)) return '/viewer/text';
    if (FileUtils.isImageFile(filePath)) return '/viewer/image';
    if (FileUtils.isAudioFile(filePath)) return '/viewer/audio';
    if (FileUtils.isVideoFile(filePath)) return '/viewer/video';
    if (FileUtils.isArchiveFile(filePath)) return '/viewer/archive';
    if (FileUtils.isCodeFile(filePath)) return '/viewer/code';
    if (FileUtils.isHtmlFile(filePath)) return '/viewer/html';
    if (FileUtils.isEbookFile(filePath)) return '/viewer/epub';
    if (FileUtils.isEmailFile(filePath)) return '/viewer/email';
    if (FileUtils.isApkFile(filePath)) return '/viewer/apk';
    // Document files (docx, doc, rtf, odt, pages) go to universal viewer
    if (FileUtils.isDocumentFile(filePath)) return '/viewer/universal';
    return '/viewer/unknown';
  }

  static final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      // File Manager
      GoRoute(
        path: '/files',
        name: 'FileManagerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return FileManagerScreen(currentPath: path);
        },
      ),

      // Recents
      GoRoute(
        path: '/recents',
        name: 'RecentsRoute',
        builder: (context, state) => const RecentsScreen(),
      ),

      // Search
      GoRoute(
        path: '/search',
        name: 'SearchRoute',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchScreen(initialQuery: query);
        },
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'SettingsRoute',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Viewers
      GoRoute(
        path: '/viewer/pdf',
        name: 'PdfViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return PdfViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/image',
        name: 'ImageViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return ImageViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/audio',
        name: 'AudioPlayerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return AudioPlayerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/video',
        name: 'VideoPlayerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return VideoPlayerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/code',
        name: 'CodeViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return CodeViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/archive',
        name: 'ArchiveViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return ArchiveViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/epub',
        name: 'EpubReaderRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return EpubViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/email',
        name: 'EmailViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return EmailViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/apk',
        name: 'ApkViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return ApkViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/word',
        name: 'WordViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return WordViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/excel',
        name: 'ExcelViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return ExcelViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/powerpoint',
        name: 'PowerPointViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return PowerPointViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/universal',
        name: 'UniversalViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return UniversalFileViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/text',
        name: 'TextViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return TextViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/viewer/html',
        name: 'HtmlViewerRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return HtmlViewerScreen(filePath: path);
        },
      ),
      GoRoute(
        path: '/file-info',
        name: 'FileInfoRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return FileInfoSheet(filePath: path);
        },
      ),

      // Unknown file fallback
      GoRoute(
        path: '/viewer/unknown',
        name: 'UnknownFileRoute',
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return UnknownFileScreen(filePath: path);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text('Page not found'),
      ),
    ),
  );
}
