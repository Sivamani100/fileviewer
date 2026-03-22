import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/widgets/file_icon.dart';

class UnknownFileScreen extends ConsumerStatefulWidget {
  final String filePath;

  const UnknownFileScreen({super.key, required this.filePath});

  @override
  ConsumerState<UnknownFileScreen> createState() => _UnknownFileScreenState();
}

class _UnknownFileScreenState extends ConsumerState<UnknownFileScreen> {
  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;
    final extension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.') + 1)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unknown File'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FileIcon(
              filePath: widget.filePath,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              fileName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This file type is not supported',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final result = await OpenFilex.open(widget.filePath);
                    if (result.type != ResultType.done) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Could not open file: ${result.message}')),
                        );
                      }
                    }
                  },
                  child: const Text('Open with External App'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
