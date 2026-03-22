import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import '../../../core/constants/file_category.dart';
import '../../../core/utils/file_utils.dart';

class UniversalFileViewerScreen extends ConsumerStatefulWidget {
  final String filePath;
  const UniversalFileViewerScreen({super.key, required this.filePath});

  @override
  ConsumerState<UniversalFileViewerScreen> createState() =>
      _UniversalFileViewerScreenState();
}

class _UniversalFileViewerScreenState
    extends ConsumerState<UniversalFileViewerScreen> {
  bool _isLoading = true;
  String? _error;
  String? _textContent;
  List<List<String>>? _tableData;
  Map<String, dynamic>? _metadata;
  String? _payloadType;
  Uint8List? _binaryData;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _textContent = null;
      _tableData = null;
      _metadata = {};
      _payloadType = null;
      _binaryData = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final extension =
          FileUtils.getFileExtension(widget.filePath).toLowerCase();
      final fileName = FileUtils.getFileName(widget.filePath);
      final fileSize = await FileUtils.getFileSize(widget.filePath);
      final lastModified = await FileUtils.getLastModified(widget.filePath);

      _metadata = {
        'File Name': fileName,
        'File Size': FileUtils.getFileSizeFormatted(fileSize),
        'Extension': extension,
        'Last Modified': lastModified != null
            ? FileUtils.formatTimestamp(lastModified)
            : 'Unknown',
        'Path': widget.filePath,
      };

      // Try to determine content type and load appropriately
      if (_isTextBasedFile(extension)) {
        await _loadAsText(file, extension);
      } else if (_isSpreadsheetFile(extension)) {
        await _loadAsSpreadsheet(file, extension);
      } else if (_isArchiveFile(extension)) {
        await _loadAsArchive(file, extension);
      } else if (_isStructuredDataFile(extension)) {
        await _loadAsStructuredData(file, extension);
      } else {
        await _loadAsBinary(file, extension);
      }
    } catch (e) {
      _error = e.toString();
    }

    setState(() {
      _isLoading = false;
    });
  }

  bool _isTextBasedFile(String ext) {
    return [
      '.txt',
      '.md',
      '.xml',
      '.json',
      '.yaml',
      '.yml',
      '.toml',
      '.ini',
      '.cfg',
      '.conf',
      '.log',
      '.html',
      '.htm',
      '.css',
      '.js',
      '.py',
      '.java',
      '.cpp',
      '.c',
      '.h',
      '.hpp',
      '.dart',
      '.rs',
      '.go',
      '.php',
      '.rb',
      '.sh',
      '.bash',
      '.ps1',
      '.sql',
      '.r',
      '.lua',
      '.pl',
      '.tcl',
      '.scala',
      '.kt',
      '.swift',
      '.m',
      '.r',
      '.rmd',
      '.tex',
      '.csv',
      '.tsv'
    ].contains(ext);
  }

  bool _isSpreadsheetFile(String ext) {
    return [
      '.xlsx',
      '.xls',
      '.xlsm',
      '.xltx',
      '.xltm',
      '.xlt',
      '.csv',
      '.tsv',
      '.ods'
    ].contains(ext);
  }

  bool _isArchiveFile(String ext) {
    return [
      '.zip',
      '.rar',
      '.7z',
      '.tar',
      '.gz',
      '.bz2',
      '.xz',
      '.tgz',
      '.tbz2',
      '.txz'
    ].contains(ext);
  }

  bool _isStructuredDataFile(String ext) {
    return ['.json', '.xml', '.yaml', '.yml', '.toml', '.plist', '.ini', '.cfg']
        .contains(ext);
  }

  Future<void> _loadAsText(File file, String extension) async {
    try {
      String content;
      final bytes = await file.readAsBytes();

      // Try different encodings
      try {
        content = utf8.decode(bytes);
      } catch (e) {
        try {
          content = latin1.decode(bytes);
        } catch (e) {
          content = 'Binary file - cannot display as text';
        }
      }

      // Special handling for different text formats
      if (extension == '.json') {
        try {
          final jsonData = json.decode(content);
          content = const JsonEncoder.withIndent('  ').convert(jsonData);
          _payloadType = 'JSON Data';
        } catch (e) {
          _payloadType = 'Text (JSON-like)';
        }
      } else if (extension == '.xml') {
        try {
          final document = XmlDocument.parse(content);
          content = document.toXmlString(pretty: true);
          _payloadType = 'XML Document';
        } catch (e) {
          _payloadType = 'Text (XML-like)';
        }
      } else if (['.yaml', '.yml'].contains(extension)) {
        try {
          final yamlData = loadYaml(content);
          content = json.encode(yamlData);
          _payloadType = 'YAML Data (converted to JSON)';
        } catch (e) {
          _payloadType = 'Text (YAML-like)';
        }
      } else if (extension == '.csv' || extension == '.tsv') {
        final delimiter = extension == '.csv' ? ',' : '\t';
        try {
          final rows =
              CsvToListConverter(fieldDelimiter: delimiter).convert(content);
          _tableData = rows
              .map(
                  (row) => row.map((value) => value?.toString() ?? '').toList())
              .toList();
          _payloadType = 'Spreadsheet Data';
          return;
        } catch (e) {
          _payloadType = 'Text (CSV-like)';
        }
      } else {
        _payloadType = 'Text File';
      }

      _textContent = content;
    } catch (e) {
      _error = 'Failed to load as text: $e';
    }
  }

  Future<void> _loadAsSpreadsheet(File file, String extension) async {
    try {
      final bytes = await file.readAsBytes();

      if (extension == '.csv' || extension == '.tsv') {
        final delimiter = extension == '.csv' ? ',' : '\t';
        final content = utf8.decode(bytes);
        final rows =
            CsvToListConverter(fieldDelimiter: delimiter).convert(content);
        _tableData = rows
            .map((row) => row.map((value) => value?.toString() ?? '').toList())
            .toList();
      } else {
        // Excel files
        final excel = excel_pkg.Excel.decodeBytes(bytes);
        if (excel.tables.isEmpty) {
          _error = 'Empty workbook';
          return;
        }
        final sheet = excel.tables.values.first;
        _tableData = sheet.rows
            .map((row) =>
                row.map((cell) => cell?.value?.toString() ?? '').toList())
            .toList();
      }

      _payloadType = 'Spreadsheet';
    } catch (e) {
      _error = 'Failed to load spreadsheet: $e';
    }
  }

  Future<void> _loadAsArchive(File file, String extension) async {
    try {
      final bytes = await file.readAsBytes();
      Archive? archive;

      if (extension == '.zip') {
        archive = ZipDecoder().decodeBytes(bytes);
      } else if (extension == '.tar') {
        archive = TarDecoder().decodeBytes(bytes);
      } else if (extension == '.gz' || extension == '.tgz') {
        final decompressed = GZipDecoder().decodeBytes(bytes);
        if (extension == '.tgz') {
          archive = TarDecoder().decodeBytes(decompressed);
        } else {
          _textContent = utf8.decode(decompressed);
          _payloadType = 'Compressed Text';
          return;
        }
      }

      if (archive != null) {
        _tableData = [
          ['Name', 'Size', 'Modified', 'Permissions'],
          ...archive.map((file) => [
                file.name,
                file.size?.toString() ?? '0',
                file.lastModTime?.toString() ?? 'Unknown',
                file.mode?.toString() ?? 'Unknown'
              ])
        ];
        _payloadType = 'Archive Contents';
      } else {
        _payloadType = 'Archive File';
      }
    } catch (e) {
      _error = 'Failed to load archive: $e';
    }
  }

  Future<void> _loadAsStructuredData(File file, String extension) async {
    try {
      final content = await file.readAsString();

      if (extension == '.json') {
        final data = json.decode(content);
        _textContent = const JsonEncoder.withIndent('  ').convert(data);
        _payloadType = 'JSON Data';
      } else if (extension == '.xml') {
        final document = XmlDocument.parse(content);
        _textContent = document.toXmlString(pretty: true);
        _payloadType = 'XML Document';
      } else if (['.yaml', '.yml'].contains(extension)) {
        final data = loadYaml(content);
        _textContent = json.encode(data);
        _payloadType = 'YAML Data';
      } else {
        _textContent = content;
        _payloadType = 'Configuration File';
      }
    } catch (e) {
      _error = 'Failed to load structured data: $e';
    }
  }

  Future<void> _loadAsBinary(File file, String extension) async {
    try {
      _binaryData = await file.readAsBytes();
      _payloadType = 'Binary File';

      // Try to detect if it's actually text
      try {
        final text = utf8.decode(_binaryData!);
        if (_isPrintableText(text)) {
          _textContent = text;
          _payloadType = 'Text File (Binary Detected)';
          _binaryData = null;
        }
      } catch (e) {
        // Not text, keep as binary
      }
    } catch (e) {
      _error = 'Failed to load binary file: $e';
    }
  }

  bool _isPrintableText(String text) {
    // Check if most characters are printable
    final printableChars = text.runes
        .where((rune) =>
            (rune >= 32 && rune <= 126) ||
            rune == 10 ||
            rune == 13 ||
            rune == 9)
        .length;
    return printableChars / text.length > 0.8;
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
    final fileName = FileUtils.getFileName(widget.filePath);

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
            onPressed: _loadFile,
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata section
          if (_metadata != null) ...[
            const Text('File Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._metadata!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text('${entry.key}:',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      Expanded(child: Text(entry.value.toString())),
                    ],
                  ),
                )),
            const Divider(height: 32),
          ],

          // Content type
          if (_payloadType != null) ...[
            Text('Content Type: $_payloadType',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
          ],

          // Table data (spreadsheets, archives)
          if (_tableData != null && _tableData!.isNotEmpty) ...[
            Text('Data Preview (${_tableData!.length - 1} rows):',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: _tableData!.first
                    .map((header) => DataColumn(
                        label: Text(header,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))))
                    .toList(),
                rows: _tableData!
                    .skip(1)
                    .take(50)
                    .map((row) => DataRow(
                          cells:
                              row.map((cell) => DataCell(Text(cell))).toList(),
                        ))
                    .toList(),
              ),
            ),
            if (_tableData!.length > 51) ...[
              const SizedBox(height: 8),
              Text('... and ${_tableData!.length - 51} more rows',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ]

          // Text content
          else if (_textContent != null) ...[
            const Text('Content Preview:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    _textContent!.length > 10000
                        ? '${_textContent!.substring(0, 10000)}...\n\n[Content truncated - ${(_textContent!.length - 10000)} more characters]'
                        : _textContent!,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ]

          // Binary data
          else if (_binaryData != null) ...[
            const Text('Binary Data Preview:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    _formatHexDump(_binaryData!),
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
            ),
          ]

          // Fallback
          else ...[
            const Text('File Preview:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            const Text(
                'This file type can be previewed using an external application.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open externally'),
              onPressed: _openExternally,
            ),
          ],
        ],
      ),
    );
  }

  String _formatHexDump(Uint8List data) {
    final buffer = StringBuffer();
    const bytesPerLine = 16;

    for (var i = 0; i < data.length; i += bytesPerLine) {
      final lineData = data.sublist(
          i, i + bytesPerLine > data.length ? data.length : i + bytesPerLine);

      // Offset
      buffer.write('${i.toString().padLeft(8, '0')}: ');

      // Hex bytes
      for (var j = 0; j < bytesPerLine; j++) {
        if (j < lineData.length) {
          buffer.write('${lineData[j].toRadixString(16).padLeft(2, '0')} ');
        } else {
          buffer.write('   ');
        }
      }

      // ASCII representation
      buffer.write(' ');
      for (var j = 0; j < lineData.length; j++) {
        final char = lineData[j];
        buffer
            .write(char >= 32 && char <= 126 ? String.fromCharCode(char) : '.');
      }

      buffer.writeln();
    }

    return buffer.toString();
  }
}
