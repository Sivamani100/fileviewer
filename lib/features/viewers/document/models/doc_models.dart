import 'dart:typed_data';
import 'dart:ui';

// Root document
class DocDocument {
  final List<DocBlock> blocks;
  final DocPageSetup pageSetup;

  DocDocument({required this.blocks, required this.pageSetup});
}

class DocPageSetup {
  final double marginTopPt;
  final double marginBottomPt;
  final double marginLeftPt;
  final double marginRightPt;

  const DocPageSetup({
    this.marginTopPt = 72,
    this.marginBottomPt = 72,
    this.marginLeftPt = 72,
    this.marginRightPt = 72,
  });
}

sealed class DocBlock {}

class DocParagraph extends DocBlock {
  final List<DocRun> runs;
  final DocParagraphStyle style;

  DocParagraph({required this.runs, required this.style});
}

class DocTable extends DocBlock {
  final List<List<DocTableCell>> rows;
  final List<double> columnWidthsPercent;

  DocTable({required this.rows, required this.columnWidthsPercent});
}

class DocImage extends DocBlock {
  final Uint8List bytes;
  final double? widthPt;
  final double? heightPt;
  final String? altText;

  DocImage({required this.bytes, this.widthPt, this.heightPt, this.altText});
}

class DocPageBreak extends DocBlock {}

class DocHorizontalRule extends DocBlock {}

class DocParagraphStyle {
  final DocHeadingLevel headingLevel;
  final DocListType listType;
  final int listLevel;
  final int? listNumber;
  final String? listGlyph;
  final DocParagraphAlignment alignment;
  final double spacingBeforePt;
  final double spacingAfterPt;
  final double lineHeightMultiplier;
  final Color? backgroundColor;
  final Color? headingColor;
  final double leftIndentPt;
  final double firstLineIndentPt;

  const DocParagraphStyle({
    this.headingLevel = DocHeadingLevel.none,
    this.listType = DocListType.none,
    this.listLevel = 0,
    this.listNumber,
    this.listGlyph,
    this.alignment = DocParagraphAlignment.left,
    this.spacingBeforePt = 0,
    this.spacingAfterPt = 8,
    this.lineHeightMultiplier = 1.15,
    this.backgroundColor,
    this.headingColor,
    this.leftIndentPt = 0,
    this.firstLineIndentPt = 0,
  });

  DocParagraphStyle copyWith({
    DocHeadingLevel? headingLevel,
    DocListType? listType,
    int? listLevel,
    int? listNumber,
    String? listGlyph,
    DocParagraphAlignment? alignment,
    double? spacingBeforePt,
    double? spacingAfterPt,
    double? lineHeightMultiplier,
    Color? backgroundColor,
    Color? headingColor,
    double? leftIndentPt,
    double? firstLineIndentPt,
  }) {
    return DocParagraphStyle(
      headingLevel: headingLevel ?? this.headingLevel,
      listType: listType ?? this.listType,
      listLevel: listLevel ?? this.listLevel,
      listNumber: listNumber ?? this.listNumber,
      listGlyph: listGlyph ?? this.listGlyph,
      alignment: alignment ?? this.alignment,
      spacingBeforePt: spacingBeforePt ?? this.spacingBeforePt,
      spacingAfterPt: spacingAfterPt ?? this.spacingAfterPt,
      lineHeightMultiplier: lineHeightMultiplier ?? this.lineHeightMultiplier,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      headingColor: headingColor ?? this.headingColor,
      leftIndentPt: leftIndentPt ?? this.leftIndentPt,
      firstLineIndentPt: firstLineIndentPt ?? this.firstLineIndentPt,
    );
  }
}

enum DocHeadingLevel { none, h1, h2, h3, h4, h5, h6 }

enum DocListType { none, bullet, numbered }

enum DocParagraphAlignment { left, center, right, justify }

class DocRun {
  final String text;
  final DocRunStyle style;

  DocRun({required this.text, required this.style});
}

class DocRunStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final double fontSizePt;
  final String fontFamily;
  final Color color;
  final Color? backgroundColor;
  final String? hyperlinkUrl;
  final bool superscript;
  final bool subscript;
  final double lineHeightMultiplier;

  const DocRunStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.fontSizePt = 11,
    this.fontFamily = 'Roboto',
    this.color = const Color(0xFF000000),
    this.backgroundColor,
    this.hyperlinkUrl,
    this.superscript = false,
    this.subscript = false,
    this.lineHeightMultiplier = 1.35,
  });

  DocRunStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    double? fontSizePt,
    String? fontFamily,
    Color? color,
    Color? backgroundColor,
    String? hyperlinkUrl,
    bool? superscript,
    bool? subscript,
    double? lineHeightMultiplier,
  }) {
    return DocRunStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      fontSizePt: fontSizePt ?? this.fontSizePt,
      fontFamily: fontFamily ?? this.fontFamily,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      hyperlinkUrl: hyperlinkUrl ?? this.hyperlinkUrl,
      superscript: superscript ?? this.superscript,
      subscript: subscript ?? this.subscript,
      lineHeightMultiplier: lineHeightMultiplier ?? this.lineHeightMultiplier,
    );
  }
}

class DocTableCell {
  final List<DocBlock> content;
  final int colSpan;
  final int rowSpan;
  final Color? backgroundColor;
  final DocTableBorder borders;

  DocTableCell({
    required this.content,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.backgroundColor,
    this.borders = const DocTableBorder(),
  });
}

class DocTableBorder {
  final Color color;
  final double widthPt;
  const DocTableBorder(
      {this.color = const Color(0xFFCCCCCC), this.widthPt = 0.5});
}
