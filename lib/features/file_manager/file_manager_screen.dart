import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/permissions_utils.dart';
import '../../core/utils/size_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/file_icon.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/loading_shimmer.dart';
import '../../routes/app_router.dart';

class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? lastModified;
  final bool isSelected;

  const FileItem({
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.size = 0,
    this.lastModified,
    this.isSelected = false,
  });

  FileItem copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    int? size,
    DateTime? lastModified,
    bool? isSelected,
  }) {
    return FileItem(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class FolderCategory {
  final String title;
  final String path;
  final IconData icon;
  final Color color;

  const FolderCategory({
    required this.title,
    required this.path,
    required this.icon,
    required this.color,
  });
}

class FileManagerScreen extends ConsumerStatefulWidget {
  final String currentPath;

  const FileManagerScreen({super.key, this.currentPath = ''});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  List<FileItem> _files = [];
  List<FileItem> _selectedFiles = [];
  bool _isLoading = true;
  String? _error;
  String _currentPath = '';
  String _sortOrder = AppConstants.defaultFileSortOrder;
  bool _isGridView = false;

  final List<FolderCategory> _categories = const [
    FolderCategory(
      title: 'All Files',
      path: '/storage/emulated/0',
      icon: Icons.folder_open,
      color: Colors.blue,
    ),
    FolderCategory(
      title: 'Documents',
      path: '/storage/emulated/0/Documents',
      icon: Icons.description,
      color: Colors.deepPurple,
    ),
    FolderCategory(
      title: 'Images',
      path: '/storage/emulated/0/Pictures',
      icon: Icons.image,
      color: Colors.orange,
    ),
    FolderCategory(
      title: 'Videos',
      path: '/storage/emulated/0/Movies',
      icon: Icons.movie,
      color: Colors.red,
    ),
    FolderCategory(
      title: 'Music',
      path: '/storage/emulated/0/Music',
      icon: Icons.music_note,
      color: Colors.green,
    ),
    FolderCategory(
      title: 'Downloads',
      path: '/storage/emulated/0/Download',
      icon: Icons.download,
      color: Colors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDirectory();
      }
    });
  }

  Future<void> _loadDirectory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _selectedFiles = [];
    });

    try {
      // Check and request file permissions
      final hasPermission = await PermissionsUtils.hasFilePermissions();
      if (!hasPermission) {
        final granted =
            await PermissionsUtils.requestFilePermissionsWithFallback();
        if (!granted) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error =
                  'File access permission denied. Please enable it in app settings.';
            });
          }
          return;
        }
      }

      final settings = ref.read(settingsProvider);
      final currentPath = widget.currentPath;
      _currentPath = currentPath;

      if (currentPath.isEmpty) {
        if (mounted) {
          setState(() {
            _files = [];
            _isLoading = false;
            _error = null;
          });
        }
        return;
      }

      if (!await Directory(currentPath).exists()) {
        if (mounted) {
          setState(() {
            _files = [];
            _isLoading = false;
            _error = 'Directory not found: $currentPath';
          });
        }
        return;
      }

      final fileNames = await FileUtils.listDirectory(currentPath,
          includeHidden: settings.showHiddenFiles);
      final files = <FileItem>[];

      for (final fileName in fileNames) {
        final filePath = FileUtils.joinPaths(currentPath, fileName);
        final isDirectory = FileUtils.isDirectory(filePath);
        final size = isDirectory ? 0 : await FileUtils.getFileSize(filePath);
        final lastModified = await FileUtils.getLastModified(filePath);

        files.add(FileItem(
          name: fileName,
          path: filePath,
          isDirectory: isDirectory,
          size: size,
          lastModified: lastModified,
        ));
      }

      if (mounted) {
        setState(() {
          _files = files;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load directory: $e';
        });
      }
    }
  }

  Future<void> _refreshDirectory() async {
    await _loadDirectory();
  }

  Future<void> _navigateToDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _selectedFiles = [];
    });

    final encodedPath = Uri.encodeComponent(path);
    context.push('/files?path=$encodedPath');
  }

  Future<void> _navigateToParent() async {
    if (_currentPath.isEmpty) return;
    final parentPath = FileUtils.getParentDirectory(_currentPath);
    if (parentPath == _currentPath) return;
    await _navigateToDirectory(parentPath);
  }

  Future<void> _toggleFileSelection(FileItem file) async {
    setState(() {
      final index = _files.indexWhere((item) => item.path == file.path);
      if (index >= 0) {
        final updatedFile = _files[index].copyWith(isSelected: !file.isSelected);
        _files[index] = updatedFile;

        if (updatedFile.isSelected) {
          _selectedFiles.add(updatedFile);
        } else {
          _selectedFiles.removeWhere((item) => item.path == updatedFile.path);
        }
      }
    });
  }

  Future<void> _openFile(FileItem file) async {
    if (file.isDirectory) {
      _navigateToDirectory(file.path);
      return;
    }

    final encodedPath = Uri.encodeComponent(file.path);
    final viewerRoute = AppRouter.getViewerRouteForFile(file.path);
    context.push('$viewerRoute?path=$encodedPath');
  }

  Future<void> _deleteSelectedFiles() async {
    for (final file in _selectedFiles) {
      try {
        await FileUtils.deleteFile(file.path);
      } catch (e) {
        // Handle error
      }
    }
    await _refreshDirectory();
    setState(() {
      _selectedFiles.clear();
    });
  }

  Future<void> _createNewFolder() async {
    // Show dialog for folder name
    final controller = TextEditingController();
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      final currentPath = widget.currentPath.isEmpty
          ? '/storage/emulated/0'
          : widget.currentPath;
      final newFolderPath = FileUtils.joinPaths(currentPath, folderName);

      try {
        await FileUtils.createDirectory(newFolderPath);
        await _refreshDirectory();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder created successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    _sortOrder = settings.fileSortOrder;
    _isGridView = settings.fileViewMode == 'grid';

    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: widget.currentPath.isEmpty ||
                widget.currentPath == '/storage/emulated/0'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateToParent,
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.pushNamed('/search'),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              setState(() {
                _sortOrder = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'name_asc',
                child: Text('Name (A → Z)'),
              ),
              const PopupMenuItem<String>(
                value: 'name_desc',
                child: Text('Name (Z → A)'),
              ),
              const PopupMenuItem<String>(
                value: 'date_asc',
                child: Text('Date (Oldest first)'),
              ),
              const PopupMenuItem<String>(
                value: 'date_desc',
                child: Text('Date (Newest first)'),
              ),
              const PopupMenuItem<String>(
                value: 'size_asc',
                child: Text('Size (Smallest first)'),
              ),
              const PopupMenuItem<String>(
                value: 'size_desc',
                child: Text('Size (Largest first)'),
              ),
              const PopupMenuItem<String>(
                value: 'type_asc',
                child: Text('Type (A → Z)'),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
          if (_selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedFiles,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (widget.currentPath.isEmpty
              ? _buildCategoryView()
              : _buildFileList()),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewFolder,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getAppBarTitle() {
    if (widget.currentPath.isEmpty ||
        widget.currentPath == '/storage/emulated/0') {
      return 'FileVault';
    }

    final pathSegments = widget.currentPath.split('/');
    if (pathSegments.length > 1) {
      return pathSegments.last;
    }

    return pathSegments.last;
  }

  Widget _buildCategoryView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: _categories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: SizeUtils.calculateGridColumns(
            MediaQuery.of(context).size.width,
          ),
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () async {
              final directory = Directory(category.path);
              if (await directory.exists()) {
                await _navigateToDirectory(category.path);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Folder not found: ${category.title}'),
                  ),
                );
              }
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: category.color.withOpacity(0.15),
                      child: Icon(
                        category.icon,
                        color: category.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      category.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      category.path,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileList() {
    if (_files.isEmpty) {
      return EmptyStateWidget(
        title: 'This folder is empty',
        subtitle: 'Tap the + button to create a new folder',
        onAction: _createNewFolder,
      );
    }

    final sortedFiles = _sortFiles(_files);

    if (_isGridView) {
      return _buildGridView(sortedFiles);
    } else {
      return _buildListView(sortedFiles);
    }
  }

  List<FileItem> _sortFiles(List<FileItem> files) {
    final folders = files.where((file) => file.isDirectory).toList();
    final regularFiles = files.where((file) => !file.isDirectory).toList();

    List<FileItem> sortedFolders;
    List<FileItem> sortedRegularFiles;

    switch (_sortOrder) {
      case 'name_asc':
        folders.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        regularFiles.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'name_desc':
        folders.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        regularFiles.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case 'date_asc':
        folders.sort((a, b) => (a.lastModified ?? DateTime.now())
            .compareTo(b.lastModified ?? DateTime.now()));
        regularFiles.sort((a, b) => (a.lastModified ?? DateTime.now())
            .compareTo(b.lastModified ?? DateTime.now()));
        break;
      case 'date_desc':
        folders.sort((a, b) => (b.lastModified ?? DateTime.now())
            .compareTo(a.lastModified ?? DateTime.now()));
        regularFiles.sort((a, b) => (b.lastModified ?? DateTime.now())
            .compareTo(a.lastModified ?? DateTime.now()));
        break;
      case 'size_asc':
        folders.sort((a, b) => a.size.compareTo(b.size));
        regularFiles.sort((a, b) => a.size.compareTo(b.size));
        break;
      case 'size_desc':
        folders.sort((a, b) => b.size.compareTo(a.size));
        regularFiles.sort((a, b) => b.size.compareTo(a.size));
        break;
      case 'type_asc':
        folders.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        regularFiles.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'type_desc':
        folders.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        regularFiles.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      default: // date_desc
        folders.sort((a, b) => (b.lastModified ?? DateTime.now())
            .compareTo(a.lastModified ?? DateTime.now()));
        regularFiles.sort((a, b) => (b.lastModified ?? DateTime.now())
            .compareTo(a.lastModified ?? DateTime.now()));
        break;
    }

    sortedFolders = [...folders, ...regularFiles];
    return sortedFolders;
  }

  Widget _buildGridView(List<FileItem> files) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: SizeUtils.calculateGridColumns(
            MediaQuery.of(context).size.width,
          ),
          childAspectRatio: AppConstants.gridAspectRatio,
        ),
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return FileItemCard(
            file: file,
            onTap: () => _openFile(file),
            onLongPress: () => _toggleFileSelection(file),
          );
        },
      ),
    );
  }

  Widget _buildListView(List<FileItem> files) {
    return RefreshIndicator(
      onRefresh: _refreshDirectory,
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return FileItemCard(
            file: file,
            onTap: () => _openFile(file),
            onLongPress: () => _toggleFileSelection(file),
          );
        },
      ),
    );
  }
}

class FileItemCard extends StatelessWidget {
  final FileItem file;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FileItemCard(
      {super.key, required this.file, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FileIcon(
                filePath: file.path,
                size: 40,
                color: file.isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : null,
                isSelected: file.isSelected,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: file.isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${file.isDirectory ? "" : FileUtils.getFileSizeFormatted(file.size)} • ${file.lastModified != null ? SizeUtils.formatTimestamp(file.lastModified!) : ""}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
