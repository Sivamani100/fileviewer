import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/widgets/file_icon.dart';
import '../../core/widgets/empty_state.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;

  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<String> _recentSearches = [];
  List<String> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch(widget.initialQuery);
    }
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    ref.read(settingsProvider.notifier).loadSettings();
    final settingsState = ref.read(settingsProvider);
    setState(() {
      _recentSearches = settingsState.recentSearches;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      // Simulate search - in real app, this would search through files
      await Future.delayed(const Duration(milliseconds: 500));

      final mockResults = [
        '/storage/emulated/0/Document1.pdf',
        '/storage/emulated/0/Document2.docx',
        '/storage/emulated/0/Image1.jpg',
        '/storage/emulated/0/Video1.mp4',
        '/storage/emulated/0/Audio1.mp3',
      ];

      setState(() {
        _isSearching = false;
        _searchResults = mockResults;
        _addToRecentSearches(query);
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  void _addToRecentSearches(String query) {
    ref.read(settingsProvider.notifier).addToRecentSearches(query);
    _loadRecentSearches();
  }

  void _navigateToFile(String filePath) {
    final encodedPath = Uri.encodeComponent(filePath);
    context.pushNamed('/viewer/unknown?path=$encodedPath');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Files'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onSubmitted: (value) {
                if (value != null && value.isNotEmpty) {
                  _performSearch(value!);
                }
              },
            ),
          ),
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _recentSearches.map((search) {
                      return ActionChip(
                        label: Text(search),
                        onPressed: () {
                          _searchController.text = search;
                          _performSearch(search);
                        },
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          if (_isSearching) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final filePath = _searchResults[index];
                  final fileName = filePath.split('/').last;

                  return ListTile(
                    leading: FileIcon(
                      filePath: filePath,
                      size: 40,
                    ),
                    title: Text(fileName),
                    subtitle: Text(filePath),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _navigateToFile(filePath),
                  );
                },
              ),
            ),
          ] else ...[
            const Expanded(
              child: EmptyStateWidget(
                title: 'Search for files',
                subtitle: 'Enter a search term above',
                animationPath: 'assets/lottie/search.json',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
