import 'package:flutter/material.dart';
import '../../core/widgets/file_icon.dart';
import '../../core/utils/file_utils.dart';
import '../../core/constants/supported_formats.dart';
import '../../core/constants/file_category.dart';

class FileInfoSheet extends StatelessWidget {
  final String filePath;

  const FileInfoSheet({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final fileName = FileUtils.getFileName(filePath);
    final extension = FileUtils.getFileExtension(filePath);
    final category = SupportedFormats.getCategoryFromExtension(extension);

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File icon and name
                Row(
                  children: [
                    FileIcon(
                      filePath: filePath,
                      size: 60,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (category != null) ...[
                            Text(
                              category.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // File actions
                Wrap(
                  spacing: 8,
                  children: [
                    _buildActionButton(
                      context,
                      Icons.open_in_new,
                      'Open',
                      () {
                        Navigator.of(context).pop();
                        // Navigate to file viewer
                      },
                    ),
                    _buildActionButton(
                      context,
                      Icons.share,
                      'Share',
                      () {
                        Navigator.of(context).pop();
                        // Share file
                      },
                    ),
                    _buildActionButton(
                      context,
                      Icons.star_border,
                      'Favorite',
                      () {
                        Navigator.of(context).pop();
                        // Add to favorites
                      },
                    ),
                    _buildActionButton(
                      context,
                      Icons.delete,
                      'Delete',
                      () {
                        Navigator.of(context).pop();
                        // Delete file
                      },
                    ),
                  ],
                ),

                // File details
                if (category != null) ...[
                  const Divider(height: 24),
                  FutureBuilder<int>(
                    future: FileUtils.getFileSize(filePath),
                    builder: (context, snapshot) {
                      final size = snapshot.data ?? 0;
                      return _buildInfoRow(context, 'Size',
                          FileUtils.getFileSizeFormatted(size));
                    },
                  ),
                  _buildInfoRow(context, 'Type', category.displayName),
                  FutureBuilder<DateTime?>(
                    future: FileUtils.getLastModified(filePath),
                    builder: (context, snapshot) {
                      final modified = snapshot.data ?? DateTime.now();
                      return _buildInfoRow(context, 'Modified',
                          FileUtils.formatTimestamp(modified));
                    },
                  ),
                  _buildInfoRow(context, 'Path', filePath),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          foregroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
