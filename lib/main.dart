import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/settings_provider.dart';
import 'core/utils/permissions_utils.dart';
import 'routes/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: FileVaultApp(),
    ),
  );
}

class FileVaultApp extends ConsumerStatefulWidget {
  const FileVaultApp({super.key});

  @override
  ConsumerState<FileVaultApp> createState() => _FileVaultAppState();
}

class _FileVaultAppState extends ConsumerState<FileVaultApp> {
  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSubscription;

  @override
  void initState() {
    super.initState();

    // Request file permissions on app start
    PermissionsUtils.requestFilePermissions();

    // Handle sharing intents when the app is running
    _mediaStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> files) {
      if (files.isNotEmpty) {
        _handleIncomingFile(files.first.path);
      }
    }, onError: (err) {
      // ignore errors
    });

    // Handle sharing intents that launched the app
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> files) {
      if (files.isNotEmpty) {
        _handleIncomingFile(files.first.path);
      }
    });
  }

  @override
  void dispose() {
    _mediaStreamSubscription?.cancel();
    super.dispose();
  }

  void _handleIncomingFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) return;

    final route = AppRouter.getViewerRouteForFile(filePath);
    final encodedPath = Uri.encodeComponent(filePath);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppRouter.router.go('$route?path=$encodedPath');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(settingsProvider).themeMode;
    final accentColor = ref.watch(settingsProvider).accentColor;

    return MaterialApp.router(
      title: 'FileVault',
      themeMode: themeMode,
      theme: themeMode == ThemeMode.dark
          ? AppTheme.darkTheme(accentColor)
          : AppTheme.lightTheme(accentColor),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
