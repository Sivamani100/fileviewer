import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:highlight/languages/all.dart' as languages;

class CodeViewerScreen extends ConsumerStatefulWidget {
  final String filePath;

  const CodeViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<CodeViewerScreen> createState() => _CodeViewerScreenState();
}

class _CodeViewerScreenState extends ConsumerState<CodeViewerScreen> {
  String? _content;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  String? _language;
  bool _showLineNumbers = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        content = utf8.decode(bytes);
      } catch (e) {
        content = latin1.decode(bytes);
      }

      // Detect language based on file extension
      final extension = widget.filePath.split('.').last.toLowerCase();
      _language = _getLanguageFromExtension(extension);

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

  String? _getLanguageFromExtension(String extension) {
    switch (extension) {
      case 'dart':
        return 'dart';
      case 'py':
      case 'python':
        return 'python';
      case 'js':
      case 'javascript':
        return 'javascript';
      case 'ts':
      case 'typescript':
        return 'typescript';
      case 'java':
        return 'java';
      case 'kt':
      case 'kotlin':
        return 'kotlin';
      case 'cpp':
      case 'cc':
      case 'cxx':
        return 'cpp';
      case 'c':
        return 'c';
      case 'h':
        return 'c';
      case 'hpp':
        return 'cpp';
      case 'cs':
        return 'csharp';
      case 'php':
        return 'php';
      case 'rb':
        return 'ruby';
      case 'go':
        return 'go';
      case 'rs':
        return 'rust';
      case 'swift':
        return 'swift';
      case 'sh':
      case 'bash':
        return 'bash';
      case 'sql':
        return 'sql';
      case 'html':
        return 'html';
      case 'xml':
        return 'xml';
      case 'css':
        return 'css';
      case 'scss':
      case 'sass':
        return 'scss';
      case 'less':
        return 'less';
      case 'json':
        return 'json';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'md':
        return 'markdown';
      case 'dockerfile':
        return 'dockerfile';
      default:
        return null;
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
          if (_content != null) ...[
            IconButton(
              icon: Icon(_showLineNumbers
                  ? Icons.format_list_numbered
                  : Icons.format_list_bulleted),
              onPressed: () {
                setState(() {
                  _showLineNumbers = !_showLineNumbers;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _content!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard')),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFile,
          ),
        ],
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

    final lines = _content!.split('\n');

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showLineNumbers)
                Container(
                  width: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      lines.length,
                      (index) => Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: _language != null
                      ? HighlightView(
                          _content!,
                          language: _language!,
                          theme: Theme.of(context).brightness == Brightness.dark
                              ? {
                                  'root': TextStyle(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  'keyword':
                                      TextStyle(color: const Color(0xFF7C4DFF)),
                                  'string':
                                      TextStyle(color: const Color(0xFF388E3C)),
                                  'comment':
                                      TextStyle(color: const Color(0xFF757575)),
                                  'number':
                                      TextStyle(color: const Color(0xFFF57C00)),
                                  'function':
                                      TextStyle(color: const Color(0xFF1976D2)),
                                  'class':
                                      TextStyle(color: const Color(0xFFD32F2F)),
                                }
                              : {},
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        )
                      : SelectableText(
                          _content!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
