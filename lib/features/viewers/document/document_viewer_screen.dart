import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/utils/file_utils.dart';

class DocumentViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const DocumentViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<DocumentViewerScreen> createState() =>
      _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends ConsumerState<DocumentViewerScreen> {
  bool _isLoading = true;
  String? _error;
  String? _textContent;
  List<List<String>>? _tableData;
  String? _payloadType;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _textContent = null;
      _tableData = null;
      _payloadType = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final extension = FileUtils.getFileExtension(widget.filePath);

      if (extension == '.csv' ||
          extension == '.tsv' ||
          extension == '.psv' ||
          extension == '.ssv') {
        final raw = await file.readAsString();
        final delimiter = extension == '.csv'
            ? ','
            : extension == '.tsv'
                ? '\t'
                : extension == '.psv'
                    ? '|'
                    : ';';
        final rows = CsvToListConverter(fieldDelimiter: delimiter).convert(raw);
        _tableData = rows
            .map((row) => row.map((value) => value?.toString() ?? '').toList())
            .toList();
        _payloadType = 'Spreadsheet';
      } else if (extension == '.xlsx' ||
          extension == '.xls' ||
          extension == '.xlsm' ||
          extension == '.xlt' ||
          extension == '.xltx' ||
          extension == '.xltm') {
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        if (excel.tables.isEmpty) {
          _error = 'Empty workbook';
        } else {
          final sheet = excel.tables.values.first;
          _tableData = sheet.rows
              .map((row) =>
                  row.map((cell) => cell?.value?.toString() ?? '').toList())
              .toList();
          _payloadType = 'Spreadsheet';
        }
      } else if (extension == '.txt' ||
          extension == '.md' ||
          extension == '.xml' ||
          extension == '.json' ||
          extension == '.log' ||
          extension == '.cfg' ||
          extension == '.conf') {
        _textContent = await file.readAsString();
        _payloadType = 'Text';
      } else if (extension == '.pdf') {
        _textContent = null;
        _payloadType = 'PDF';
      } else if (extension == '.doc' ||
          extension == '.docx' ||
          extension == '.ppt' ||
          extension == '.pptx' ||
          extension == '.pptm' ||
          extension == '.pot' ||
          extension == '.xls' ||
          extension == '.xlsx') {
        _payloadType = 'Office Document';
      } else {
        _payloadType = 'Unknown Document Type';
      }
    } catch (e) {
      _error = e.toString();
    }

    setState(() {
      _isLoading = false;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openExternally,
            tooltip: 'Open with external app',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocument,
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error loading file: $_error',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open externally'),
                        onPressed: _openExternally,
                      ),
                    ],
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_payloadType == 'Spreadsheet' && _tableData != null) {
      final List<DataColumn> columns = _tableData!.isNotEmpty
          ? List.generate(
              _tableData!.first.length,
              (index) => DataColumn(
                label: Text('C${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          : <DataColumn>[];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: _tableData!
              .take(100)
              .map((row) => DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList()))
              .toList(),
        ),
      );
    }

    if (_payloadType == 'Text' && _textContent != null) {
      return SingleChildScrollView(
        child: Text(_textContent!),
      );
    }

    if (_payloadType == 'PDF') {
      return const Center(
        child: Text(
            'This is a PDF document that opens with the PDF viewer automatically.'),
      );
    }

    if (_payloadType == 'Office Document') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'This file type is not rendered natively in-app (DOC/DOCX/PPT/XLSX).',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'Select "Open with external app" to use your device configured Office viewer.',
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open externally'),
            onPressed: _openExternally,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('File preview is not available for this document type.',
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text('Detected type: ${_payloadType ?? 'unknown'}',
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open externally'),
          onPressed: _openExternally,
        ),
      ],
    );
  }
}
