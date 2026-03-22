import 'dart:ui';

/// XLSX document model
class XlsxDocument {
  final List<XlsxSheet> sheets;
  final XlsxProperties properties;

  XlsxDocument({
    required this.sheets,
    required this.properties,
  });
}

/// Workbook properties
class XlsxProperties {
  final String title;
  final String creator;
  final DateTime? created;
  final DateTime? modified;

  XlsxProperties({
    required this.title,
    required this.creator,
    this.created,
    this.modified,
  });
}

/// Individual worksheet
class XlsxSheet {
  final String name;
  final List<XlsxRow> rows;
  final List<XlsxColumn> columns;
  final List<XlsxMergedCell> mergedCells;
  final Map<String, XlsxCellStyle> cellStyles;
  final int? defaultRowHeight;
  final int? defaultColumnWidth;

  XlsxSheet({
    required this.name,
    required this.rows,
    required this.columns,
    required this.mergedCells,
    required this.cellStyles,
    this.defaultRowHeight,
    this.defaultColumnWidth,
  });
}

/// Worksheet row
class XlsxRow {
  final int rowIndex; // 1-based
  final List<XlsxCell> cells;
  final double? height;
  final bool? hidden;

  XlsxRow({
    required this.rowIndex,
    required this.cells,
    this.height,
    this.hidden,
  });
}

/// Worksheet column
class XlsxColumn {
  final int columnIndex; // 1-based
  final double? width;
  final bool? hidden;

  XlsxColumn({
    required this.columnIndex,
    this.width,
    this.hidden,
  });
}

/// Cell in a worksheet
class XlsxCell {
  final String address; // e.g., "A1", "B2"
  final int row; // 1-based
  final int column; // 1-based
  final XlsxCellValue value;
  final String? formula;
  final String? styleId;
  final XlsxDataType dataType;

  XlsxCell({
    required this.address,
    required this.row,
    required this.column,
    required this.value,
    this.formula,
    this.styleId,
    this.dataType = XlsxDataType.string,
  });
}

/// Cell value
class XlsxCellValue {
  final String? stringValue;
  final double? numberValue;
  final bool? boolValue;
  final DateTime? dateValue;

  XlsxCellValue({
    this.stringValue,
    this.numberValue,
    this.boolValue,
    this.dateValue,
  });

  String get displayValue {
    if (stringValue != null) return stringValue!;
    if (numberValue != null) return numberValue!.toString();
    if (boolValue != null) return boolValue! ? 'TRUE' : 'FALSE';
    if (dateValue != null) return dateValue!.toString();
    return '';
  }
}

/// Cell data types
enum XlsxDataType {
  string,
  number,
  boolean,
  date,
  formula,
}

/// Merged cell range
class XlsxMergedCell {
  final String ref; // e.g., "A1:B2"
  final int startRow;
  final int startColumn;
  final int endRow;
  final int endColumn;

  XlsxMergedCell({
    required this.ref,
    required this.startRow,
    required this.startColumn,
    required this.endRow,
    required this.endColumn,
  });
}

/// Cell style properties
class XlsxCellStyle {
  final Color? backgroundColor;
  final Color? fontColor;
  final double? fontSize;
  final String? fontFamily;
  final bool? bold;
  final bool? italic;
  final XlsxHorizontalAlignment? horizontalAlignment;
  final XlsxVerticalAlignment? verticalAlignment;
  final XlsxBorderStyle? borderTop;
  final XlsxBorderStyle? borderBottom;
  final XlsxBorderStyle? borderLeft;
  final XlsxBorderStyle? borderRight;

  XlsxCellStyle({
    this.backgroundColor,
    this.fontColor,
    this.fontSize,
    this.fontFamily,
    this.bold,
    this.italic,
    this.horizontalAlignment,
    this.verticalAlignment,
    this.borderTop,
    this.borderBottom,
    this.borderLeft,
    this.borderRight,
  });
}

/// Horizontal alignment
enum XlsxHorizontalAlignment {
  left,
  center,
  right,
  justify,
}

/// Vertical alignment
enum XlsxVerticalAlignment {
  top,
  middle,
  bottom,
}

/// Border style
class XlsxBorderStyle {
  final Color color;
  final XlsxBorderType type;

  XlsxBorderStyle({
    required this.color,
    required this.type,
  });
}

/// Border types
enum XlsxBorderType {
  none,
  thin,
  medium,
  thick,
  double,
}