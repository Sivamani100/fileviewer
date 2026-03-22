import 'package:flutter/material.dart';
import '../models/xlsx_models.dart';

/// Renderer for XLSX (Excel) spreadsheets
class XlsxRenderer extends StatefulWidget {
  final XlsxDocument document;
  final double textScaleFactor;

  const XlsxRenderer({
    Key? key,
    required this.document,
    this.textScaleFactor = 1.0,
  }) : super(key: key);

  @override
  State<XlsxRenderer> createState() => _XlsxRendererState();
}

class _XlsxRendererState extends State<XlsxRenderer> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.document.sheets.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document.sheets.isEmpty) {
      return const Center(child: Text('No sheets found in workbook'));
    }

    return Column(
      children: [
        // Sheet tabs
        if (widget.document.sheets.length > 1)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: widget.document.sheets.map((sheet) {
                return Tab(text: sheet.name);
              }).toList(),
            ),
          ),

        // Sheet content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.document.sheets.map((sheet) {
              return _buildSheetView(sheet);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetView(XlsxSheet sheet) {
    // Determine the maximum column and row indices
    int maxColumn = 1;
    int maxRow = 1;

    for (final row in sheet.rows) {
      maxRow = maxRow > row.rowIndex ? maxRow : row.rowIndex;
      for (final cell in row.cells) {
        maxColumn = maxColumn > cell.column ? maxColumn : cell.column;
      }
    }

    // Create a grid of cells
    final gridData = _buildGridData(sheet, maxRow, maxColumn);

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: Container(
              color: Colors.white,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
                columnWidths: _buildColumnWidths(sheet, maxColumn),
                children: gridData.map((rowData) {
                  return TableRow(
                    children: rowData.map((cellData) {
                      return _buildCell(cellData, sheet);
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<int, TableColumnWidth> _buildColumnWidths(XlsxSheet sheet, int maxColumn) {
    final widths = <int, TableColumnWidth>{};

    // Set default width for all columns
    const defaultWidth = 100.0;
    for (int col = 1; col <= maxColumn; col++) {
      double width = defaultWidth;

      // Check if there's a custom width for this column
      final columnInfo = sheet.columns.firstWhere(
        (c) => c.columnIndex == col,
        orElse: () => XlsxColumn(columnIndex: col),
      );

      if (columnInfo.width != null) {
        // Convert Excel width units to pixels (approximate)
        width = columnInfo.width! * 7.0; // Rough conversion
      }

      widths[col] = FixedColumnWidth(width);
    }

    return widths;
  }

  List<List<_CellData>> _buildGridData(XlsxSheet sheet, int maxRow, int maxColumn) {
    final grid = <List<_CellData>>[];

    for (int row = 1; row <= maxRow; row++) {
      final rowData = <_CellData>[];

      for (int col = 1; col <= maxColumn; col++) {
        final cellData = _getCellData(sheet, row, col);
        rowData.add(cellData);
      }

      grid.add(rowData);
    }

    return grid;
  }

  _CellData _getCellData(XlsxSheet sheet, int row, int col) {
    // Check if this cell is part of a merged range
    final mergedCell = sheet.mergedCells.firstWhere(
      (merge) =>
          row >= merge.startRow && row <= merge.endRow &&
          col >= merge.startColumn && col <= merge.endColumn,
      orElse: () => XlsxMergedCell(ref: '', startRow: 0, startColumn: 0, endRow: 0, endColumn: 0),
    );

    if (mergedCell.ref.isNotEmpty) {
      // This is a merged cell
      if (row == mergedCell.startRow && col == mergedCell.startColumn) {
        // This is the top-left cell of the merged range
        final cell = _findCell(sheet, mergedCell.startRow, mergedCell.startColumn);
        return _CellData(
          value: cell?.value.displayValue ?? '',
          isMerged: true,
          mergedRows: mergedCell.endRow - mergedCell.startRow + 1,
          mergedCols: mergedCell.endColumn - mergedCell.startColumn + 1,
          style: sheet.cellStyles[cell?.styleId],
        );
      } else {
        // This is a covered cell in the merged range
        return _CellData(
          value: '',
          isMerged: true,
          isCovered: true,
          mergedRows: 1,
          mergedCols: 1,
        );
      }
    }

    // Regular cell
    final cell = _findCell(sheet, row, col);
    return _CellData(
      value: cell?.value.displayValue ?? '',
      style: sheet.cellStyles[cell?.styleId],
    );
  }

  XlsxCell? _findCell(XlsxSheet sheet, int row, int col) {
    final xlsxRow = sheet.rows.firstWhere(
      (r) => r.rowIndex == row,
      orElse: () => XlsxRow(rowIndex: row, cells: []),
    );

    return xlsxRow.cells.firstWhere(
      (c) => c.column == col,
      orElse: () => XlsxCell(
        address: '${_columnNumberToName(col)}$row',
        row: row,
        column: col,
        value: XlsxCellValue(),
      ),
    );
  }

  Widget _buildCell(_CellData cellData, XlsxSheet sheet) {
    if (cellData.isCovered) {
      // Don't render covered cells in merged ranges
      return Container();
    }

    final style = cellData.style;
    final backgroundColor = style?.backgroundColor ?? Colors.white;
    final textColor = style?.fontColor ?? Colors.black;

    TextAlign textAlign = TextAlign.left;
    if (style?.horizontalAlignment != null) {
      switch (style!.horizontalAlignment!) {
        case XlsxHorizontalAlignment.center:
          textAlign = TextAlign.center;
          break;
        case XlsxHorizontalAlignment.right:
          textAlign = TextAlign.right;
          break;
        case XlsxHorizontalAlignment.justify:
          textAlign = TextAlign.justify;
          break;
        default:
          textAlign = TextAlign.left;
      }
    }

    FontWeight fontWeight = style?.bold == true ? FontWeight.bold : FontWeight.normal;
    FontStyle fontStyle = style?.italic == true ? FontStyle.italic : FontStyle.normal;

    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: backgroundColor,
      child: SingleChildScrollView(
        child: Text(
          cellData.value,
          textAlign: textAlign,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: (style?.fontSize ?? 11),
            fontFamily: style?.fontFamily ?? 'Arial',
            fontWeight: fontWeight,
            fontStyle: fontStyle,
          ),
        ),
      ),
    );
  }

  String _columnNumberToName(int columnNumber) {
    String result = '';
    while (columnNumber > 0) {
      columnNumber--;
      result = String.fromCharCode('A'.codeUnitAt(0) + (columnNumber % 26)) + result;
      columnNumber = (columnNumber / 26).floor();
    }
    return result;
  }
}

class _CellData {
  final String value;
  final bool isMerged;
  final bool isCovered;
  final int mergedRows;
  final int mergedCols;
  final XlsxCellStyle? style;

  _CellData({
    required this.value,
    this.isMerged = false,
    this.isCovered = false,
    this.mergedRows = 1,
    this.mergedCols = 1,
    this.style,
  });
}