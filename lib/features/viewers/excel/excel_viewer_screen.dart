import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/utils/file_utils.dart';
import '../document/models/xlsx_models.dart';
import '../document/parsers/xlsx_parser.dart';
import '../document/renderers/xlsx_renderer.dart';

class ExcelViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const ExcelViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<ExcelViewerScreen> createState() => _ExcelViewerScreenState();
}

class _ExcelViewerScreenState extends ConsumerState<ExcelViewerScreen> {
  bool _isLoading = true;
  String? _error;
  XlsxDocument? _document;
  double _zoomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSpreadsheet();
  }

  Future<void> _loadSpreadsheet() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _document = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final extension = FileUtils.getFileExtension(widget.filePath);

      if (extension == '.xlsx' ||
          extension == '.xlsm' ||
          extension == '.xlt' ||
          extension == '.xltx' ||
          extension == '.xltm') {
        _document = await XlsxParser.parse(widget.filePath);
      } else if (extension == '.xls') {
        _error = 'Binary .xls files are not supported. Please convert to .xlsx format.';
      } else if (extension == '.csv' ||
          extension == '.tsv' ||
          extension == '.psv' ||
          extension == '.ssv') {
        _error = 'CSV files are handled by the universal viewer. Please use that instead.';
      } else {
        throw Exception('Unsupported spreadsheet format');
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
          SnackBar(content: Text('Failed to open file externally: $e')),
        );
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
              onPressed: _loadSpreadsheet),
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
                      Text('Failed to load spreadsheet',
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
                        child: XlsxRenderer(
                            document: _document!,
                            textScaleFactor: _zoomFactor),
                      ),
                    )
                  : const Center(child: Text('No content to display')),
    );
  }
}
