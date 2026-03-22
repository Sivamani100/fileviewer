import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/file_icon.dart';
import '../../core/widgets/empty_state.dart';

class RecentsScreen extends ConsumerWidget {
  const RecentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final recentFiles = settings.recentFiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Files'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              ref.read(settingsProvider.notifier).clearRecentFiles();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Recent files cleared')),
              );
            },
          ),
        ],
      ),
      body: recentFiles.isEmpty
          ? EmptyStateWidget(
              title: 'No recent files',
              subtitle: 'Tap the + button to add files',
              animationPath: 'assets/lottie/empty_files.json',
              onAction: () => context.pushNamed('/files'),
            )
          : ListView.builder(
              itemCount: recentFiles.length,
              itemBuilder: (context, index) {
                final filePath = recentFiles[index];
                final fileTime = DateTime.fromMillisecondsSinceEpoch(
                    recentFiles.length - index - 1);
                final now = DateTime.now();
                final timeDiff = now.difference(fileTime);

                String timeAgo;
                if (timeDiff.inDays > 0) {
                  timeAgo = '${timeDiff.inDays} days ago';
                } else if (timeDiff.inHours > 0) {
                  timeAgo = '${timeDiff.inHours} hours ago';
                } else {
                  timeAgo = 'Just now';
                }

                return ListTile(
                  leading: FileIcon(
                    filePath: filePath,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    filePath,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                  ),
                  subtitle: Text(
                    timeAgo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                  onTap: () => context.pushNamed('/files'),
                );
              },
            ),
    );
  }
}
