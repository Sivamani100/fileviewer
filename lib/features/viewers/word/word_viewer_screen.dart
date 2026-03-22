import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/utils/file_utils.dart';
import '../document/models/doc_models.dart';
import '../document/parsers/docx_parser.dart';
import '../document/parsers/odt_parser.dart';
import '../document/parsers/rtf_parser.dart';
import '../document/renderers/doc_renderer.dart';

class WordViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const WordViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<WordViewerScreen> createState() => _WordViewerScreenState();
}

class _WordViewerScreenState extends ConsumerState<WordViewerScreen> {
  bool _isLoading = true;
  String? _error;
  DocDocument? _document;
  double _zoomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _document = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) throw Exception('File not found');

      final extension =
          FileUtils.getFileExtension(widget.filePath).toLowerCase();
      if (extension == '.docx' ||
          extension == '.docm' ||
          extension == '.dotx' ||
          extension == '.dotm') {
        _document = await DocxParser.parse(widget.filePath);
      } else if (extension == '.odt') {
        _document = await OdtParser.parse(widget.filePath);
      } else if (extension == '.rtf') {
        _document = await RtfParser.parse(widget.filePath);
      } else if (extension == '.doc' || extension == '.dot') {
        _error =
            'Binary .doc files are not supported, please convert to .docx or .odt';
      } else {
        _error = 'Unsupported format: $extension';
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternally() async {
    try {
      await OpenFilex.open(widget.filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open externally: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = File(widget.filePath).uri.pathSegments.last;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => setState(
                  () => _zoomFactor = (_zoomFactor + 0.1).clamp(0.5, 2.5))),
          IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => setState(
                  () => _zoomFactor = (_zoomFactor - 0.1).clamp(0.5, 2.5))),
          IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open externally',
              onPressed: _openExternally),
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload',
              onPressed: _loadDocument),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Failed to load document',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                          onPressed: _openExternally,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open externally')),
                    ],
                  ),
                )
              : _document != null
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color:
                                isDark ? const Color(0xFF2A2A2A) : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ]),
                        child: DocRenderer(
                            document: _document!,
                            textScaleFactor: _zoomFactor,
                            isDarkMode: isDark,
                            screenWidth:
                                MediaQuery.of(context).size.width - 16),
                      ),
                    )
                  : const Center(child: Text('No content to display')),
    );
  }
}
