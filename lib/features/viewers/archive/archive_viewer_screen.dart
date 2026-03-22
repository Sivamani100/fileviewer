import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

class ArchiveViewerScreen extends ConsumerStatefulWidget {
  final String filePath;

  const ArchiveViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<ArchiveViewerScreen> createState() =>
      _ArchiveViewerScreenState();
}

class _ArchiveViewerScreenState extends ConsumerState<ArchiveViewerScreen> {
  Archive? _archive;
  bool _isLoading = true;
  String? _error;
  List<ArchiveFile> _files = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchive() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final file = File(widget.filePath);
      final bytes = await file.readAsBytes();

      // Determine archive type and decode
      final extension = path.extension(widget.filePath).toLowerCase();
      Archive archive;

      switch (extension) {
        case '.zip':
          archive = ZipDecoder().decodeBytes(bytes);
          break;
        case '.tar':
          archive = TarDecoder().decodeBytes(bytes);
          break;
        case '.gz':
        case '.gzip':
          final decompressed = GZipDecoder().decodeBytes(bytes);
          if (widget.filePath.toLowerCase().endsWith('.tar.gz') ||
              widget.filePath.toLowerCase().endsWith('.tgz')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            archive = Archive();
            archive.addFile(ArchiveFile(
                path.basename(
                    widget.filePath.replaceAll(RegExp(r'\.gz|\.gzip\$'), '')),
                decompressed.length,
                decompressed));
          }
          break;
        case '.bz2':
        case '.bzip2':
          final decompressed = BZip2Decoder().decodeBytes(bytes);
          if (widget.filePath.toLowerCase().endsWith('.tar.bz2')) {
            archive = TarDecoder().decodeBytes(decompressed);
          } else {
            archive = Archive();
            archive.addFile(ArchiveFile(
                path.basename(
                    widget.filePath.replaceAll(RegExp(r'\.bz2|\.bzip2\$'), '')),
                decompressed.length,
                decompressed));
          }
          break;
        default:
          throw UnsupportedError('Unsupported archive format: $extension');
      }

      setState(() {
        _archive = archive;
        _files = archive.files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ArchiveFile> get _filteredFiles {
    if (_searchQuery.isEmpty) return _files;
    return _files
        .where((file) =>
            file.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    if (extension.isEmpty) return Icons.insert_drive_file;

    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mkv':
        return Icons.videocam;
      case '.mp3':
      case '.wav':
      case '.flac':
        return Icons.audiotrack;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.txt':
      case '.md':
        return Icons.text_snippet;
      case '.zip':
      case '.rar':
      case '.7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          File(widget.filePath).uri.pathSegments.last,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArchive,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load archive',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArchive,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_archive == null) {
      return const Center(
        child: Text('Unable to load archive'),
      );
    }

    final filteredFiles = _filteredFiles;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${filteredFiles.length} files (${_searchQuery.isNotEmpty ? "${_files.length} total" : ""})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredFiles.length,
            itemBuilder: (context, index) {
              final file = filteredFiles[index];
              final isDirectory = file.isFile == false;

              return ListTile(
                leading: Icon(
                  isDirectory ? Icons.folder : _getFileIcon(file.name),
                  color: isDirectory
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  file.name,
                  style: TextStyle(
                    fontWeight:
                        isDirectory ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle:
                    file.size > 0 ? Text(_formatFileSize(file.size)) : null,
                trailing: isDirectory
                    ? const Icon(Icons.chevron_right)
                    : PopupMenuButton<String>(
                        onSelected: (action) {
                          // Handle file actions
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'extract',
                            child: Text('Extract'),
                          ),
                          const PopupMenuItem(
                            value: 'view',
                            child: Text('View'),
                          ),
                        ],
                      ),
                onTap: () {
                  if (isDirectory) {
                    // Navigate to directory (not implemented for simplicity)
                  } else {
                    // Handle file tap
                    _showFileOptions(file);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFileOptions(ArchiveFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(path.basename(file.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Size: ${_formatFileSize(file.size)}'),
            const SizedBox(height: 8),
            Text('Compression: ${file.isCompressed ? 'compressed' : 'stored'}'),
            if (file.crc32 != null) ...[
              const SizedBox(height: 8),
              Text(
                  'CRC32: ${file.crc32!.toRadixString(16).padLeft(8, '0').toUpperCase()}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Extract file (not implemented for simplicity)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('File extraction not implemented')),
              );
            },
            child: const Text('Extract'),
          ),
        ],
      ),
    );
  }
}
