import 'dart:ui';

/// PPTX document model
class PptxDocument {
  final List<PptxSlide> slides;
  final PptxPresentationProperties properties;

  PptxDocument({
    required this.slides,
    required this.properties,
  });
}

/// Presentation properties
class PptxPresentationProperties {
  final int slideWidth;
  final int slideHeight;
  final String title;

  PptxPresentationProperties({
    required this.slideWidth,
    required this.slideHeight,
    required this.title,
  });
}

/// Individual slide
class PptxSlide {
  final int slideNumber;
  final List<PptxShape> shapes;
  final Color? backgroundColor;
  final String? title;

  PptxSlide({
    required this.slideNumber,
    required this.shapes,
    this.backgroundColor,
    this.title,
  });
}

/// Shape on a slide (text box, image, etc.)
class PptxShape {
  final PptxShapeType type;
  final Rect bounds; // Position and size in EMU coordinates
  final PptxShapeContent content;
  final int? rotation; // Rotation in degrees
  final Color? fillColor;
  final PptxShapeStyle? style;

  PptxShape({
    required this.type,
    required this.bounds,
    required this.content,
    this.rotation,
    this.fillColor,
    this.style,
  });
}

/// Shape types
enum PptxShapeType {
  textBox,
  picture,
  rectangle,
  ellipse,
  line,
  table,
}

/// Shape content
class PptxShapeContent {
  final PptxTextContent? textContent;
  final PptxImageContent? imageContent;
  final PptxTableContent? tableContent;

  PptxShapeContent({
    this.textContent,
    this.imageContent,
    this.tableContent,
  });
}

/// Text content for shapes
class PptxTextContent {
  final List<PptxParagraph> paragraphs;

  PptxTextContent({required this.paragraphs});
}

/// Paragraph in text content
class PptxParagraph {
  final List<PptxTextRun> runs;
  final PptxParagraphStyle style;

  PptxParagraph({
    required this.runs,
    required this.style,
  });
}

/// Text run with formatting
class PptxTextRun {
  final String text;
  final PptxTextStyle style;

  PptxTextRun({
    required this.text,
    required this.style,
  });
}

/// Text style properties
class PptxTextStyle {
  final Color? color;
  final double? fontSize;
  final String? fontFamily;
  final bool? bold;
  final bool? italic;
  final bool? underline;

  PptxTextStyle({
    this.color,
    this.fontSize,
    this.fontFamily,
    this.bold,
    this.italic,
    this.underline,
  });
}

/// Paragraph style properties
class PptxParagraphStyle {
  final PptxTextAlignment? alignment;
  final double? lineSpacing;
  final double? spaceBefore;
  final double? spaceAfter;

  PptxParagraphStyle({
    this.alignment,
    this.lineSpacing,
    this.spaceBefore,
    this.spaceAfter,
  });
}

/// Text alignment
enum PptxTextAlignment {
  left,
  center,
  right,
  justified,
}

/// Image content for shapes
class PptxImageContent {
  final String imagePath; // Path to extracted image file
  final String? altText;

  PptxImageContent({
    required this.imagePath,
    this.altText,
  });
}

/// Table content for shapes
class PptxTableContent {
  final List<PptxTableRow> rows;

  PptxTableContent({required this.rows});
}

/// Table row
class PptxTableRow {
  final List<PptxTableCell> cells;

  PptxTableRow({required this.cells});
}

/// Table cell
class PptxTableCell {
  final PptxTextContent content;
  final Color? backgroundColor;
  final int? rowSpan;
  final int? colSpan;

  PptxTableCell({
    required this.content,
    this.backgroundColor,
    this.rowSpan,
    this.colSpan,
  });
}

/// Shape style properties
class PptxShapeStyle {
  final Color? lineColor;
  final double? lineWidth;
  final PptxLineStyle? lineStyle;
  final PptxFillStyle? fillStyle;

  PptxShapeStyle({
    this.lineColor,
    this.lineWidth,
    this.lineStyle,
    this.fillStyle,
  });
}

/// Line style
enum PptxLineStyle {
  solid,
  dash,
  dot,
  dashDot,
}

/// Fill style
enum PptxFillStyle {
  solid,
  gradient,
  pattern,
  none,
}