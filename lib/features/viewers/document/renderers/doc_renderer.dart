import 'dart:math';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/doc_models.dart';

class DocRenderer extends StatelessWidget {
  final DocDocument document;
  final double textScaleFactor;
  final bool isDarkMode;
  final double screenWidth;

  const DocRenderer({
    super.key,
    required this.document,
    required this.screenWidth,
    this.textScaleFactor = 1.0,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // The DocRenderer is inside a Container with margin: EdgeInsets.all(12)
    // So available width is screenWidth - 24
    // Content area has 24px padding on each side, so contentWidth = availableWidth - 48
    final availableWidth = screenWidth - 24;
    final contentWidthPt = availableWidth - 48;

    // Portrait should use a minimum A4-like width to avoid squeezing and display properly.
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    const double a4WidthPt = 595.0;
    final renderedWidth = isPortrait ? max(contentWidthPt, a4WidthPt) : contentWidthPt;
    final a4HeightPt = renderedWidth * 297.0 / 210.0;

    return Center(
      child: Container(
        width: renderedWidth,
        constraints: BoxConstraints(minHeight: a4HeightPt),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SelectionArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: document.pageSetup.marginLeftPt * 1.0,
              vertical: document.pageSetup.marginTopPt * 1.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: document.blocks
                  .map((block) => _buildBlock(context, block, contentWidthPt))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlock(
      BuildContext context, DocBlock block, double contentWidth) {
    if (block is DocParagraph)
      return _buildParagraph(context, block, contentWidth);
    if (block is DocTable) return _buildTable(context, block, contentWidth);
    if (block is DocImage) return _buildImage(block, contentWidth);
    if (block is DocPageBreak) return const SizedBox(height: 32);
    if (block is DocHorizontalRule) return const Divider(height: 24);
    return const SizedBox.shrink();
  }

  Widget _buildParagraph(
      BuildContext context, DocParagraph para, double contentWidth) {
    if (para.runs.isEmpty) {
      return SizedBox(height: para.style.spacingAfterPt * textScaleFactor);
    }

    // Apply heading-specific spacing
    double spacingBefore = para.style.spacingBeforePt;
    double spacingAfter = para.style.spacingAfterPt;

    switch (para.style.headingLevel) {
      case DocHeadingLevel.h1:
        spacingBefore = spacingBefore.clamp(18, double.infinity);
        spacingAfter = spacingAfter.clamp(8, double.infinity);
        break;
      case DocHeadingLevel.h2:
        spacingBefore = spacingBefore.clamp(14, double.infinity);
        spacingAfter = spacingAfter.clamp(6, double.infinity);
        break;
      case DocHeadingLevel.h3:
        spacingBefore = spacingBefore.clamp(12, double.infinity);
        spacingAfter = spacingAfter.clamp(4, double.infinity);
        break;
      default:
        spacingAfter = spacingAfter.clamp(8, double.infinity);
        break;
    }

    final child = para.style.listType != DocListType.none
        ? _buildListItem(context, para, contentWidth)
        : _buildRichText(context, para, contentWidth);

    return Padding(
      padding: EdgeInsets.only(
        top: spacingBefore * textScaleFactor * 0.5,
        bottom: spacingAfter * textScaleFactor * 0.5,
        left: para.style.leftIndentPt * textScaleFactor,
      ),
      child: child,
    );
  }

  Widget _buildListItem(
      BuildContext context, DocParagraph para, double contentWidth) {
    final style = para.style;
    final levelIndent = style.listLevel * 16.0 * textScaleFactor;

    final bulletChar = style.listGlyph ??
        (style.listType == DocListType.bullet
            ? (style.listLevel == 0
                ? '•'
                : style.listLevel == 1
                    ? '◦'
                    : '▪')
            : '${style.listNumber ?? 1}.');

    return Padding(
      padding: EdgeInsets.only(left: levelIndent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: bulletChar.length > 1 ? 28 : 18,
            child:
                Text(bulletChar, style: TextStyle(fontSize: 12 * textScaleFactor)),
          ),
          Expanded(
              child: _buildRichText(
                  context, para, contentWidth - levelIndent - (bulletChar.length > 1 ? 28 : 18))),
        ],
      ),
    );
  }

  Widget _buildRichText(
      BuildContext context, DocParagraph para, double contentWidth) {
    final spans = para.runs.map((run) => _buildTextSpan(run, para.style)).toList();

    return RichText(
      textAlign: _docAlignToTextAlign(para.style.alignment),
      textScaleFactor: textScaleFactor,
      text: TextSpan(children: spans),
    );
  }

  TextAlign _docAlignToTextAlign(DocParagraphAlignment alignment) {
    switch (alignment) {
      case DocParagraphAlignment.center:
        return TextAlign.center;
      case DocParagraphAlignment.right:
        return TextAlign.right;
      case DocParagraphAlignment.justify:
        return TextAlign.justify;
      case DocParagraphAlignment.left:
      default:
        return TextAlign.left;
    }
  }

  TextSpan _buildTextSpan(DocRun run, DocParagraphStyle paraStyle) {
    final s = run.style;
    final decorations = <TextDecoration>[];
    if (s.underline) decorations.add(TextDecoration.underline);
    if (s.strikethrough) decorations.add(TextDecoration.lineThrough);

    // For headings, use the paragraph's heading color if available
    Color textColor = s.color;
    if (paraStyle.headingLevel != DocHeadingLevel.none) {
      if (paraStyle.headingColor != null) {
        textColor = paraStyle.headingColor!;
      } else if (textColor == const Color(0xDD000000)) { // Default color
        textColor = const Color(0xFF2E74B5); // Blue theme color
      }
    }

    final baseStyle = TextStyle(
      fontWeight: s.bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: s.italic ? FontStyle.italic : FontStyle.normal,
      decoration: decorations.isNotEmpty
          ? TextDecoration.combine(decorations)
          : TextDecoration.none,
      fontSize: s.fontSizePt * textScaleFactor,
      color: isDarkMode ? _toLightColor(textColor) : textColor,
      backgroundColor: s.backgroundColor,
      height: s.lineHeightMultiplier,
      fontFamily: s.fontFamily,
    );

    if (s.hyperlinkUrl != null) {
      return TextSpan(
        text: run.text,
        style: baseStyle.copyWith(
            color: Colors.blue, decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _openUrl(s.hyperlinkUrl!),
      );
    }

    return TextSpan(text: run.text, style: baseStyle);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _toLightColor(Color color) {
    if (color.computeLuminance() < 0.2) {
      return Colors.white.withOpacity(0.87);
    }
    return color;
  }

  Widget _buildTable(
      BuildContext context, DocTable table, double contentWidth) {
    // Skip if the entire table has no visible content
    if (_isEntirelyEmpty(table)) return const SizedBox.shrink();

    // Header band pattern
    if (_isHeaderBandTable(table)) {
      return _buildHeaderBand(context, table, contentWidth);
    }

    // Normal table - use Flutter's native Table widget
    return SizedBox(
      width: contentWidth,
      child: Table(
        border: TableBorder.all(
          color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFCCCCCC),
          width: 0.5,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        columnWidths: _buildColumnWidths(table, contentWidth),
        children: table.rows.map((row) =>
          _buildTableRowNative(context, row, contentWidth, table)
        ).toList(),
      ),
    );
  }

  bool _isEntirelyEmpty(DocTable table) {
    for (final row in table.rows) {
      for (final cell in row) {
        if (!_isCellEmpty(cell)) return false;
      }
    }
    return true;
  }

  bool _isCellEmpty(DocTableCell cell) {
    if (cell.content.isEmpty) return true;
    for (final block in cell.content) {
      if (block is DocParagraph && block.runs.any((r) => r.text.trim().isNotEmpty)) {
        return false;
      }
    }
    return true;
  }

  bool _isHeaderBandTable(DocTable table) {
    if (table.rows.length != 1) return false;
    final row = table.rows.first;
    final emptyCells = row.where((c) => _isCellEmpty(c)).length;
    final contentCells = row.where((c) => !_isCellEmpty(c)).length;
    return emptyCells > 0 && contentCells == 1;
  }

  Map<int, TableColumnWidth> _buildColumnWidths(DocTable table, double contentWidth) {
    if (table.columnWidthsPercent.isEmpty) {
      // Equal distribution if no explicit widths
      final colCount = table.rows.isEmpty ? 1 : table.rows.first.length;
      return {for (int i = 0; i < colCount; i++) i: const FlexColumnWidth(1)};
    }

    final map = <int, TableColumnWidth>{};
    for (int i = 0; i < table.columnWidthsPercent.length; i++) {
      map[i] = FlexColumnWidth(table.columnWidthsPercent[i] / 100.0);
    }
    return map;
  }

  TableRow _buildTableRowNative(
    BuildContext context,
    List<DocTableCell> cells,
    double contentWidth,
    DocTable table,
  ) {
    return TableRow(
      children: cells.map((cell) {
        return TableCell(
          child: Container(
            decoration: BoxDecoration(
              color: cell.backgroundColor ??
                (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minHeight: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: cell.content.isEmpty
                ? [const SizedBox(height: 4)]
                : cell.content.map((block) {
                    // Calculate cell width based on column percentage
                    final cellFraction = table.columnWidthsPercent.isNotEmpty &&
                        cells.indexOf(cell) < table.columnWidthsPercent.length
                      ? table.columnWidthsPercent[cells.indexOf(cell)] / 100.0
                      : 1.0 / cells.length;
                    final cellWidth = (contentWidth * cellFraction) - 16;
                    return _buildBlock(context, block, cellWidth.clamp(30.0, contentWidth));
                  }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeaderBand(BuildContext context, DocTable table, double contentWidth) {
    // Find the non-empty cell
    final row = table.rows.first;
    final contentCell = row.firstWhere((c) => !_isCellEmpty(c));

    // Get background color of the content cell
    Color bgColor = contentCell.backgroundColor ??
      (isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFD9E2F3));

    // Collect all text runs from the cell
    final allRuns = <DocRun>[];
    DocParagraphStyle? paraStyle;
    for (final block in contentCell.content) {
      if (block is DocParagraph) {
        paraStyle = block.style;
        allRuns.addAll(block.runs);
      }
    }

    return SizedBox(
      width: contentWidth,
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: _buildNumberedBandOrSimpleBand(
          context, allRuns, row, bgColor, contentWidth
        ),
      ),
    );
  }

  // Detect if the band has a numbered badge (like "1 | OSI Model & TCP/IP Stack")
  Widget _buildNumberedBandOrSimpleBand(
    BuildContext context,
    List<DocRun> runs,
    List<DocTableCell> row,
    Color bgColor,
    double contentWidth,
  ) {
    // Check if first non-empty cell has a short number (1, 2, 3...)
    final cells = row.where((c) => !_isCellEmpty(c)).toList();

    if (cells.length >= 2) {
      // Two-content-cell band → number badge + title (like the numbered topics)
      final firstCellRuns = <DocRun>[];
      final secondCellRuns = <DocRun>[];
      for (final block in cells[0].content) {
        if (block is DocParagraph) firstCellRuns.addAll(block.runs);
      }
      for (final block in cells[1].content) {
        if (block is DocParagraph) secondCellRuns.addAll(block.runs);
      }

      final badgeText = firstCellRuns.map((r) => r.text).join().trim();
      final isNumberBadge = RegExp(r'^\d{1,2}$').hasMatch(badgeText);

      if (isNumberBadge) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Number badge
            Container(
              width: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
              ),
              alignment: Alignment.center,
              child: Text(
                badgeText,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * textScaleFactor,
                ),
              ),
            ),
            // Title area
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: cells[1].backgroundColor ??
                  const Color(0xFFE8ECF8),
                child: RichText(
                  textScaleFactor: textScaleFactor,
                  text: TextSpan(
                    children: secondCellRuns.map((r) => _buildTextSpan(r, const DocParagraphStyle())).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    // Simple full-width colored band
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: RichText(
        textScaleFactor: textScaleFactor,
        text: TextSpan(
          children: runs.map((r) => _buildTextSpan(r, const DocParagraphStyle())).toList(),
        ),
      ),
    );
  }

  Widget _buildTableRow(
    BuildContext context,
    List<DocTableCell> cells,
    double tableWidth,
    DocTable table,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(cells.length, (i) {
            final cell = cells[i];

            // Calculate this cell's width correctly
            double cellWidth;
            if (table.columnWidthsPercent.isNotEmpty &&
                i < table.columnWidthsPercent.length) {
              cellWidth = tableWidth * (table.columnWidthsPercent[i] / 100.0);
            } else {
              // Equal distribution if no explicit widths
              cellWidth = tableWidth / cells.length;
            }

            // Account for colSpan
            final spanWidth = cellWidth * cell.colSpan;

            // Inner content padding
            const cellPadding = 8.0;
            final innerWidth = spanWidth - (cellPadding * 2);

            return Container(
              width: spanWidth,
              decoration: BoxDecoration(
                color: cell.backgroundColor ??
                  (isDarkMode ? const Color(0xFF2A2A2A) : Colors.white),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFCCCCCC),
                  width: 0.5,
                ),
              ),
              padding: const EdgeInsets.all(cellPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: cell.content.isEmpty
                  ? [const SizedBox(height: 4)]  // Empty cell — show minimum height
                  : cell.content
                      .map((block) => _buildBlock(context, block, innerWidth.clamp(40.0, double.infinity)))
                      .toList(),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildImage(DocImage img, double contentWidth) {
    var width = img.widthPt ?? contentWidth;
    var height = img.heightPt ?? (contentWidth / 2);

    if (width > contentWidth) {
      final ratio = height / width;
      width = contentWidth;
      height = contentWidth * ratio;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Image.memory(img.bytes,
          width: width,
          height: height,
          fit: BoxFit.contain, errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.grey.shade200,
          width: width,
          height: 60,
          child: const Center(child: Text('[Image]')),
        );
      }),
    );
  }
}
