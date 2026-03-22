import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/xlsx_models.dart';

/// Parser for XLSX files (Excel spreadsheets)
class XlsxParser {
  static Future<XlsxDocument> parse(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Parse workbook properties
    final properties = await _parseWorkbookProperties(archive);

    // Parse worksheets
    final sheets = await _parseWorksheets(archive);

    return XlsxDocument(
      sheets: sheets,
      properties: properties,
    );
  }

  static Future<XlsxProperties> _parseWorkbookProperties(Archive archive) async {
    final coreFile = archive.findFile('docProps/core.xml');
    String title = 'Excel Workbook';
    String creator = 'Unknown';
    DateTime? created;
    DateTime? modified;

    if (coreFile != null) {
      final xml = XmlDocument.parse(utf8.decode(coreFile.content));
      title = xml.findElements('dc:title').firstOrNull?.text ?? title;
      creator = xml.findElements('dc:creator').firstOrNull?.text ?? creator;

      final createdStr = xml.findElements('dcterms:created').firstOrNull?.text;
      final modifiedStr = xml.findElements('dcterms:modified').firstOrNull?.text;

      if (createdStr != null) {
        created = DateTime.tryParse(createdStr);
      }
      if (modifiedStr != null) {
        modified = DateTime.tryParse(modifiedStr);
      }
    }

    return XlsxProperties(
      title: title,
      creator: creator,
      created: created,
      modified: modified,
    );
  }

  static Future<List<XlsxSheet>> _parseWorksheets(Archive archive) async {
    final workbookFile = archive.findFile('xl/workbook.xml');
    if (workbookFile == null) {
      throw Exception('Invalid XLSX: missing workbook.xml');
    }

    final workbookXml = XmlDocument.parse(utf8.decode(workbookFile.content));
    final sheets = <XlsxSheet>[];

    // Parse sheet references
    final sheetElements = workbookXml.findAllElements('sheet');
    for (final sheetElement in sheetElements) {
      final sheetName = sheetElement.getAttribute('name') ?? 'Sheet';
      final sheetId = sheetElement.getAttribute('sheetId');
      if (sheetId == null) continue;

      final sheetFile = archive.findFile('xl/worksheets/sheet$sheetId.xml');
      if (sheetFile != null) {
        final sheet = await _parseWorksheet(archive, sheetFile, sheetName);
        sheets.add(sheet);
      }
    }

    return sheets;
  }

  static Future<XlsxSheet> _parseWorksheet(Archive archive, ArchiveFile sheetFile, String sheetName) async {
    final xml = XmlDocument.parse(utf8.decode(sheetFile.content));
    final worksheet = xml.findElements('worksheet').first;

    // Parse sheet data
    final sheetData = worksheet.findElements('sheetData').first;
    final rows = <XlsxRow>[];

    // Parse rows
    for (final rowElement in sheetData.findAllElements('row')) {
      final rowIndex = int.tryParse(rowElement.getAttribute('r') ?? '1') ?? 1;
      final height = double.tryParse(rowElement.getAttribute('ht') ?? '');
      final hidden = rowElement.getAttribute('hidden') == '1';

      final cells = <XlsxCell>[];
      for (final cellElement in rowElement.findAllElements('c')) {
        final cell = _parseCell(cellElement);
        cells.add(cell);
      }

      rows.add(XlsxRow(
        rowIndex: rowIndex,
        cells: cells,
        height: height,
        hidden: hidden,
      ));
    }

    // Parse columns
    final columns = _parseColumns(worksheet);

    // Parse merged cells
    final mergedCells = _parseMergedCells(worksheet);

    // Parse styles (simplified)
    final cellStyles = <String, XlsxCellStyle>{};

    return XlsxSheet(
      name: sheetName,
      rows: rows,
      columns: columns,
      mergedCells: mergedCells,
      cellStyles: cellStyles,
    );
  }

  static XlsxCell _parseCell(XmlElement cellElement) {
    final address = cellElement.getAttribute('r') ?? 'A1';
    final cellRef = _parseCellReference(address);
    final type = cellElement.getAttribute('t') ?? 'str';
    final style = cellElement.getAttribute('s');

    final valueElement = cellElement.findElements('v').firstOrNull;
    final formulaElement = cellElement.findElements('f').firstOrNull;

    final value = _parseCellValue(valueElement?.text ?? '', type);
    final formula = formulaElement?.text;

    XlsxDataType dataType;
    switch (type) {
      case 'n':
        dataType = XlsxDataType.number;
        break;
      case 'b':
        dataType = XlsxDataType.boolean;
        break;
      case 'd':
        dataType = XlsxDataType.date;
        break;
      case 'str':
      default:
        dataType = XlsxDataType.string;
        break;
    }

    return XlsxCell(
      address: address,
      row: cellRef.row,
      column: cellRef.column,
      value: value,
      formula: formula,
      styleId: style,
      dataType: dataType,
    );
  }

  static XlsxCellValue _parseCellValue(String value, String type) {
    switch (type) {
      case 'n':
        final numValue = double.tryParse(value);
        return XlsxCellValue(numberValue: numValue);
      case 'b':
        final boolValue = value == '1' || value.toLowerCase() == 'true';
        return XlsxCellValue(boolValue: boolValue);
      case 'd':
        final dateValue = DateTime.tryParse(value);
        return XlsxCellValue(dateValue: dateValue);
      default:
        return XlsxCellValue(stringValue: value);
    }
  }

  static List<XlsxColumn> _parseColumns(XmlElement worksheet) {
    final cols = worksheet.findElements('cols').firstOrNull;
    if (cols == null) return [];

    final columns = <XlsxColumn>[];
    for (final colElement in cols.findAllElements('col')) {
      final min = int.tryParse(colElement.getAttribute('min') ?? '1') ?? 1;
      final max = int.tryParse(colElement.getAttribute('max') ?? '1') ?? 1;
      final width = double.tryParse(colElement.getAttribute('width') ?? '');
      final hidden = colElement.getAttribute('hidden') == '1';

      for (int colIndex = min; colIndex <= max; colIndex++) {
        columns.add(XlsxColumn(
          columnIndex: colIndex,
          width: width,
          hidden: hidden,
        ));
      }
    }

    return columns;
  }

  static List<XlsxMergedCell> _parseMergedCells(XmlElement worksheet) {
    final mergeCells = worksheet.findElements('mergeCells').firstOrNull;
    if (mergeCells == null) return [];

    final mergedCells = <XlsxMergedCell>[];
    for (final mergeCell in mergeCells.findAllElements('mergeCell')) {
      final ref = mergeCell.getAttribute('ref') ?? '';
      final range = _parseCellRange(ref);
      if (range != null) {
        mergedCells.add(XlsxMergedCell(
          ref: ref,
          startRow: range.startRow,
          startColumn: range.startColumn,
          endRow: range.endRow,
          endColumn: range.endColumn,
        ));
      }
    }

    return mergedCells;
  }

  static _CellReference _parseCellReference(String ref) {
    final match = RegExp(r'^([A-Z]+)(\d+)$').firstMatch(ref);
    if (match == null) return _CellReference(1, 1);

    final colStr = match.group(1)!;
    final rowStr = match.group(2)!;

    final column = _columnNameToNumber(colStr);
    final row = int.tryParse(rowStr) ?? 1;

    return _CellReference(row, column);
  }

  static _CellRange? _parseCellRange(String range) {
    final parts = range.split(':');
    if (parts.length != 2) return null;

    final start = _parseCellReference(parts[0]);
    final end = _parseCellReference(parts[1]);

    return _CellRange(start.row, start.column, end.row, end.column);
  }

  static int _columnNameToNumber(String columnName) {
    int result = 0;
    for (int i = 0; i < columnName.length; i++) {
      result = result * 26 + (columnName.codeUnitAt(i) - 'A'.codeUnitAt(0) + 1);
    }
    return result;
  }

  static String _columnNumberToName(int columnNumber) {
    String result = '';
    while (columnNumber > 0) {
      columnNumber--;
      result = String.fromCharCode('A'.codeUnitAt(0) + (columnNumber % 26)) + result;
      columnNumber = (columnNumber / 26).floor();
    }
    return result;
  }
}

class _CellReference {
  final int row;
  final int column;

  _CellReference(this.row, this.column);
}

class _CellRange {
  final int startRow;
  final int startColumn;
  final int endRow;
  final int endColumn;

  _CellRange(this.startRow, this.startColumn, this.endRow, this.endColumn);
}