import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/utils/file_utils.dart';
import '../document/models/pptx_models.dart';
import '../document/parsers/pptx_parser.dart';
import '../document/renderers/pptx_renderer.dart';

class PowerPointViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const PowerPointViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<PowerPointViewerScreen> createState() =>
      _PowerPointViewerScreenState();
}

class _PowerPointViewerScreenState
    extends ConsumerState<PowerPointViewerScreen> {
  bool _isLoading = true;
  String? _error;
  PptxDocument? _document;
  double _zoomFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _loadPresentation();
  }

  Future<void> _loadPresentation() async {
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

      if (extension == '.pptx' ||
          extension == '.pptm' ||
          extension == '.ppsx' ||
          extension == '.ppsm' ||
          extension == '.potx' ||
          extension == '.potm') {
        _document = await PptxParser.parse(widget.filePath);
      } else if (extension == '.ppt' ||
          extension == '.pps' ||
          extension == '.pot') {
        // For older .ppt files
        _error = 'Binary .ppt files are not supported. Please convert to .pptx format.';
      } else if (extension == '.odp') {
        _error = 'ODP files are not yet supported. Please convert to .pptx format.';
      } else {
        throw Exception('Unsupported presentation format');
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
              onPressed: _loadPresentation),
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
                      Text('Failed to load presentation',
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
                        child: PptxRenderer(
                            document: _document!,
                            textScaleFactor: _zoomFactor),
                      ),
                    )
                  : const Center(child: Text('No content to display')),
    );
  }
}
