import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextViewerScreen extends ConsumerStatefulWidget {
  final String filePath;

  const TextViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends ConsumerState<TextViewerScreen> {
  String? _content;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;
  List<int> _searchResults = [];
  int _currentSearchIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final file = File(widget.filePath);
      final bytes = await file.readAsBytes();

      // Try to detect encoding
      String content;
      try {
        // Try UTF-8 first
        content = utf8.decode(bytes);
      } catch (e) {
        // Fallback to latin1
        content = latin1.decode(bytes);
      }

      setState(() {
        _content = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _searchText(String query) {
    if (_content == null || query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = -1;
        _searchQuery = null;
      });
      return;
    }

    final results = <int>[];
    final content = _content!.toLowerCase();
    final searchQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = content.indexOf(searchQuery, start);
      if (index == -1) break;
      results.add(index);
      start = index + 1;
    }

    setState(() {
      _searchQuery = query;
      _searchResults = results;
      _currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });

    if (results.isNotEmpty) {
      _scrollToResult(0);
    }
  }

  void _nextSearchResult() {
    if (_searchResults.isEmpty) return;

    final nextIndex = (_currentSearchIndex + 1) % _searchResults.length;
    setState(() {
      _currentSearchIndex = nextIndex;
    });
    _scrollToResult(nextIndex);
  }

  void _previousSearchResult() {
    if (_searchResults.isEmpty) return;

    final prevIndex = _currentSearchIndex - 1;
    if (prevIndex < 0) {
      setState(() {
        _currentSearchIndex = _searchResults.length - 1;
      });
      _scrollToResult(_searchResults.length - 1);
    } else {
      setState(() {
        _currentSearchIndex = prevIndex;
      });
      _scrollToResult(prevIndex);
    }
  }

  void _scrollToResult(int index) {
    if (index < 0 || index >= _searchResults.length) return;

    // Approximate line height for scrolling
    const lineHeight = 20.0;
    final lineNumber =
        _content!.substring(0, _searchResults[index]).split('\n').length - 1;
    final offset = lineNumber * lineHeight;

    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
          if (_content != null) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _content!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Content copied to clipboard')),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFile,
          ),
        ],
        bottom: _searchQuery != null && _searchResults.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '${_currentSearchIndex + 1} of ${_searchResults.length} matches',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up),
                        onPressed: _previousSearchResult,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: _nextSearchResult,
                        iconSize: 20,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchQuery = null;
                            _searchResults.clear();
                            _currentSearchIndex = -1;
                          });
                        },
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
              )
            : null,
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
              'Failed to load file',
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
              onPressed: _loadFile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_content == null) {
      return const Center(
        child: Text('No content to display'),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        _content!,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search text',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop();
            _searchText(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchText(_searchController.text);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
