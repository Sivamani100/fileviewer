import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.filePath),
      );

      // Wait for the document to load
      await _pdfController!.document.then((document) {
        setState(() {
          _totalPages = document.pagesCount;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          if (_pdfController != null && !_isLoading) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPdf,
            ),
          ],
        ],
        bottom: _totalPages > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 1
                            ? () => _pdfController?.previousPage(
                                  curve: Curves.easeInOut,
                                  duration: const Duration(milliseconds: 300),
                                )
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          '$_currentPage / $_totalPages',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < _totalPages
                            ? () => _pdfController?.nextPage(
                                  curve: Curves.easeInOut,
                                  duration: const Duration(milliseconds: 300),
                                )
                            : null,
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
              'Failed to load PDF',
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
              onPressed: _loadPdf,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pdfController == null) {
      return const Center(
        child: Text('Unable to load PDF'),
      );
    }

    return PdfView(
      controller: _pdfController!,
      scrollDirection: Axis.vertical,
      onDocumentLoaded: (document) {
        setState(() {
          _totalPages = document.pagesCount;
        });
      },
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        errorBuilder: (context, error) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error rendering page',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
