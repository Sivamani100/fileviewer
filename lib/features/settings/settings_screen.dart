import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(context, ref, 'Appearance', settings),
          _buildSection(context, ref, 'File Manager', settings),
          _buildSection(context, ref, 'Viewers', settings),
          _buildSection(context, ref, 'Storage', settings),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, WidgetRef ref, String title,
      SettingsState settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
        const SizedBox(height: 16),
        ..._buildSettingItems(context, ref, settings),
      ],
    );
  }

  List<Widget> _buildSettingItems(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    return [
      _buildThemeSetting(settings),
      _buildFileViewSetting(ref, settings),
      _buildStorageSetting(context, ref, settings),
      _buildAboutSetting(settings),
    ];
  }

  Widget _buildThemeSetting(SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Theme'),
      onTap: () {
        // Show theme selection dialog
      },
      trailing: const Icon(Icons.chevron_right),
      subtitle: Text(settings.themeMode == ThemeMode.dark ? 'Dark' : 'Light'),
    );
  }

  Widget _buildFileViewSetting(WidgetRef ref, SettingsState settings) {
    return ListTile(
      leading: const Icon(Icons.grid_view),
      title: const Text('Default View'),
      onTap: () {
        ref.read(settingsProvider.notifier).saveFileViewMode(
            settings.fileViewMode == 'grid' ? 'list' : 'grid');
      },
      trailing: Radio<String>(
        value: settings.fileViewMode,
        groupValue: settings.fileViewMode,
        onChanged: (String? value) {
          ref.read(settingsProvider.notifier).saveFileViewMode(value!);
        },
      ),
    );
  }

  Widget _buildStorageSetting(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Storage'),
          onTap: () {
            ref.read(settingsProvider.notifier).clearRecentFiles();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Recent files cleared')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_sweep),
          title: const Text('Clear Temp Files'),
          onTap: () {
            // Clear temp files logic
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: const Text('Temp files cleared')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutSetting(SettingsState settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('About'),
          onTap: () {
            // Show about dialog
          },
        ),
        ListTile(
          leading: const Icon(Icons.star),
          title: const Text('Rate App'),
          onTap: () {
            // Rate app logic
          },
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: const Text('Send Feedback'),
          onTap: () {
            // Send feedback logic
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('Licenses'),
          onTap: () {
            // Show licenses
          },
        ),
      ],
    );
  }
}
