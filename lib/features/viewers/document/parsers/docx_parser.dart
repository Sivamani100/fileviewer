import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/doc_models.dart';

class DocxParser {
  static Future<DocDocument> parse(String filePath) async {
    return compute(_parseIsolate, filePath);
  }

  static DocDocument _parseIsolate(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) {
      throw Exception('Invalid DOCX: document.xml is missing');
    }
    final docXml =
        XmlDocument.parse(utf8.decode(documentFile.content as List<int>));

    final styleFile = archive.findFile('word/styles.xml');
    final stylesMap = styleFile != null
        ? _parseStyles(
            XmlDocument.parse(utf8.decode(styleFile.content as List<int>)))
        : <String, DocParagraphStyle>{};

    final numberingFile = archive.findFile('word/numbering.xml');
    final numberingMap = numberingFile != null
        ? _parseNumbering(
            XmlDocument.parse(utf8.decode(numberingFile.content as List<int>)))
        : <String, _NumberingDef>{};

    final relsFile = archive.findFile('word/_rels/document.xml.rels');
    final relsMap = relsFile != null
        ? _parseRelationships(
            XmlDocument.parse(utf8.decode(relsFile.content as List<int>)))
        : <String, String>{};

    final imageMap = <String, Uint8List>{};
    for (final file in archive.files) {
      if (file.name.startsWith('word/media/')) {
        imageMap[file.name] = Uint8List.fromList(file.content as List<int>);
      }
    }

    final bodyElementList = docXml.findAllElements('w:body');
    if (bodyElementList.isEmpty) {
      throw Exception('Invalid DOCX: missing w:body');
    }
    final body = bodyElementList.first;

    final blocks = <DocBlock>[];
    for (final child in body.children.whereType<XmlElement>()) {
      switch (child.name.local) {
        case 'p':
          final paragraph = _parseParagraph(
              child, stylesMap, numberingMap, relsMap, imageMap);
          if (paragraph != null) blocks.add(paragraph);
          break;
        case 'tbl':
          blocks.add(
              _parseTable(child, stylesMap, numberingMap, relsMap, imageMap));
          break;
        case 'sectPr':
          // Could parse section break and page setup in the future.
          break;
      }
    }

    return DocDocument(blocks: blocks, pageSetup: const DocPageSetup());
  }

  static DocParagraph? _parseParagraph(
    XmlElement pElement,
    Map<String, DocParagraphStyle> stylesMap,
    Map<String, _NumberingDef> numberingMap,
    Map<String, String> relsMap,
    Map<String, Uint8List> imageMap,
  ) {
    final runs = <DocRun>[];

    final pPr = pElement.findElements('w:pPr').firstOrNull;
    final paraStyle = _parseParagraphProperties(pPr, stylesMap, numberingMap);

    for (final child in pElement.children.whereType<XmlElement>()) {
      switch (child.name.local) {
        case 'r':
          final rPr = child.findElements('w:rPr').firstOrNull;
          final runStyle = _parseRunProperties(rPr, paraStyle);
          for (final rchild in child.children.whereType<XmlElement>()) {
            switch (rchild.name.local) {
              case 't':
                final text = rchild.text;
                if (text.isNotEmpty)
                  runs.add(DocRun(text: text, style: runStyle));
                break;
              case 'br':
                runs.add(DocRun(text: '\n', style: runStyle));
                break;
              case 'tab':
                runs.add(DocRun(text: '\t', style: runStyle));
                break;
            }
          }
          break;

        case 'hyperlink':
          final rId = child.getAttribute('r:id');
          final url = rId != null ? relsMap[rId] : null;
          for (final r in child.findElements('w:r')) {
            final rPr = r.findElements('w:rPr').firstOrNull;
            final baseStyle = _parseRunProperties(rPr, paraStyle);
            final style = baseStyle.copyWith(
              color: const Color(0xFF0000FF),
              underline: true,
              hyperlinkUrl: url,
            );
            final text = r.findElements('w:t').map((e) => e.text).join();
            if (text.isNotEmpty) runs.add(DocRun(text: text, style: style));
          }
          break;

        case 'drawing':
        case 'pict':
          final imageBlock = _extractInlineImage(child, relsMap, imageMap);
          if (imageBlock != null) {
            if (runs.isNotEmpty) {
              // flush current text as paragraph and leave image as separate block at the outer loop.
            }
            runs.add(DocRun(text: '\n[Image]\n', style: const DocRunStyle()));
          }
          break;
      }
    }

    return DocParagraph(runs: runs, style: paraStyle);
  }

  static DocParagraphStyle _parseParagraphProperties(
    XmlElement? pPr,
    Map<String, DocParagraphStyle> stylesMap,
    Map<String, _NumberingDef> numberingMap,
  ) {
    if (pPr == null) return const DocParagraphStyle();

    final styleId =
        pPr.findElements('w:pStyle').firstOrNull?.getAttribute('w:val') ??
            'Normal';
    DocParagraphStyle base = stylesMap[styleId] ?? const DocParagraphStyle();

    DocHeadingLevel headingLevel = base.headingLevel;
    final lower = styleId.toLowerCase();
    if (lower.contains('heading1'))
      headingLevel = DocHeadingLevel.h1;
    else if (lower.contains('heading2'))
      headingLevel = DocHeadingLevel.h2;
    else if (lower.contains('heading3'))
      headingLevel = DocHeadingLevel.h3;
    else if (lower.contains('heading4'))
      headingLevel = DocHeadingLevel.h4;
    else if (lower.contains('heading5'))
      headingLevel = DocHeadingLevel.h5;
    else if (lower.contains('heading6')) headingLevel = DocHeadingLevel.h6;

    var listType = base.listType;
    var listLevel = base.listLevel;
    int? listNumber;
    String? listGlyph;

    final numPr = pPr.findElements('w:numPr').firstOrNull;
    if (numPr != null) {
      final numId =
          numPr.findElements('w:numId').firstOrNull?.getAttribute('w:val');
      final ilvl =
          numPr.findElements('w:ilvl').firstOrNull?.getAttribute('w:val');
      listLevel = int.tryParse(ilvl ?? '0') ?? 0;
      if (numId != null && numberingMap.containsKey(numId)) {
        final def = numberingMap[numId]!;
        listType = def.isBullet ? DocListType.bullet : DocListType.numbered;
        listNumber = def.currentNumber;
        listGlyph = def.levelGlyphs[listLevel] ?? (def.isBullet ? '•' : '1.');
      }
    }

    final jc = pPr.findElements('w:jc').firstOrNull?.getAttribute('w:val');
    DocParagraphAlignment alignment = DocParagraphAlignment.left;
    switch (jc) {
      case 'center':
        alignment = DocParagraphAlignment.center;
        break;
      case 'right':
        alignment = DocParagraphAlignment.right;
        break;
      case 'both':
      case 'distribute':
        alignment = DocParagraphAlignment.justify;
        break;
    }

    final spacing = pPr.findElements('w:spacing').firstOrNull;
    final beforeTwips =
        int.tryParse(spacing?.getAttribute('w:before') ?? '0') ?? 0;
    final afterTwips =
        int.tryParse(spacing?.getAttribute('w:after') ?? '120') ?? 120;
    final spacingBefore = beforeTwips / 20.0;
    final spacingAfter = afterTwips / 20.0;

    final ind = pPr.findElements('w:ind').firstOrNull;
    final leftTwips = int.tryParse(ind?.getAttribute('w:left') ?? '0') ?? 0;
    final firstLineTwips =
        int.tryParse(ind?.getAttribute('w:firstLine') ?? '0') ?? 0;
    final leftIndent = leftTwips / 20.0;
    final firstLineIndent = firstLineTwips / 20.0;

    return DocParagraphStyle(
      headingLevel: headingLevel,
      listType: listType,
      listLevel: listLevel,
      listNumber: listNumber,
      listGlyph: listGlyph,
      alignment: alignment,
      spacingBeforePt: spacingBefore,
      spacingAfterPt: spacingAfter,
      leftIndentPt: leftIndent + (listLevel * 16.0),
      firstLineIndentPt: firstLineIndent,
      lineHeightMultiplier: base.lineHeightMultiplier,
    );
  }

  static DocRunStyle _parseRunProperties(
      XmlElement? rPr, DocParagraphStyle paraStyle) {
    if (rPr == null) {
      return DocRunStyle(fontSizePt: _headingFontSize(paraStyle.headingLevel));
    }

    final bold = rPr.findElements('w:b').isNotEmpty &&
            rPr.findElements('w:b').first.getAttribute('w:val') != 'false' ||
        paraStyle.headingLevel != DocHeadingLevel.none;
    final italic = rPr.findElements('w:i').isNotEmpty &&
        rPr.findElements('w:i').first.getAttribute('w:val') != 'false';
    final underline = rPr.findElements('w:u').isNotEmpty &&
        rPr.findElements('w:u').first.getAttribute('w:val') != 'none';
    final strikethrough = rPr.findElements('w:strike').isNotEmpty;

    final szEl = rPr.findElements('w:sz').firstOrNull;
    final szVal = int.tryParse(szEl?.getAttribute('w:val') ?? '0') ?? 0;
    final fontSizePt =
        szVal > 0 ? szVal / 2.0 : _headingFontSize(paraStyle.headingLevel);

    final fontEl = rPr.findElements('w:rFonts').firstOrNull;
    final fontFamily = fontEl?.getAttribute('w:ascii') ??
        fontEl?.getAttribute('w:hAnsi') ??
        'Roboto';

    final colorEl = rPr.findElements('w:color').firstOrNull;
    final colorHex = colorEl?.getAttribute('w:val') ?? '000000';
    Color color = const Color(0xDD000000);
    if (colorHex.length == 6) {
      color = Color(int.parse('FF$colorHex', radix: 16));
    }

    final highlight =
        rPr.findElements('w:highlight').firstOrNull?.getAttribute('w:val');
    Color? backgroundColor;
    if (highlight != null) {
      backgroundColor = _highlightColor(highlight);
    }

    final vertAlign =
        rPr.findElements('w:vertAlign').firstOrNull?.getAttribute('w:val');
    final superscript = vertAlign == 'superscript';
    final subscript = vertAlign == 'subscript';

    return DocRunStyle(
      bold: bold,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
      fontSizePt: fontSizePt,
      fontFamily: _mapFontFamily(fontFamily),
      color: color,
      backgroundColor: backgroundColor,
      superscript: superscript,
      subscript: subscript,
    );
  }

  static DocTable _parseTable(
    XmlElement tbl,
    Map<String, DocParagraphStyle> stylesMap,
    Map<String, _NumberingDef> numberingMap,
    Map<String, String> relsMap,
    Map<String, Uint8List> imageMap,
  ) {
    final rows = <List<DocTableCell>>[];

    for (final tr in tbl.findElements('w:tr')) {
      final cells = <DocTableCell>[];

      for (final tc in tr.findElements('w:tc')) {
        final cellContent = <DocBlock>[];

        // Parse all child elements in the cell
        for (final child in tc.children.whereType<XmlElement>()) {
          if (child.name.local == 'p') {
            final block = _parseParagraph(child, stylesMap, numberingMap, relsMap, imageMap);
            if (block != null) {
              cellContent.add(block);
            }
          } else if (child.name.local == 'tbl') {
            // Nested table
            cellContent.add(_parseTable(child, stylesMap, numberingMap, relsMap, imageMap));
          }
        }

        final tcPr = tc.findElements('w:tcPr').firstOrNull;
        final gridSpanVal = tcPr
          ?.findElements('w:gridSpan').firstOrNull
          ?.getAttribute('w:val');
        final colSpan = int.tryParse(gridSpanVal ?? '1') ?? 1;

        // Background color from cell shading
        final shdEl = tcPr?.findElements('w:shd').firstOrNull;
        Color? bgColor;
        final fillHex = shdEl?.getAttribute('w:fill');
        if (fillHex != null && fillHex != 'auto' && fillHex.length == 6) {
          bgColor = Color(int.parse('FF$fillHex', radix: 16));
        }

        cells.add(DocTableCell(
          content: cellContent,
          colSpan: colSpan,
          backgroundColor: bgColor,
        ));
      }

      if (cells.isNotEmpty) rows.add(cells);
    }

    // Parse column widths from <w:tblGrid>
    final tblGrid = tbl.findElements('w:tblGrid').firstOrNull;
    final colWidths = <double>[];
    if (tblGrid != null) {
      for (final col in tblGrid.findElements('w:gridCol')) {
        final w = int.tryParse(col.getAttribute('w:w') ?? '0') ?? 0;
        colWidths.add(w.toDouble());  // In twentieths of a point (twips)
      }
    }

    // Also check per-cell width from <w:tcW> as fallback:
    if (colWidths.isEmpty && rows.isNotEmpty) {
      for (final tc in tbl.findElements('w:tr').first.findElements('w:tc')) {
        final tcPr = tc.findElements('w:tcPr').firstOrNull;
        final tcW = tcPr?.findElements('w:tcW').firstOrNull;
        final w = int.tryParse(tcW?.getAttribute('w:w') ?? '0') ?? 0;
        colWidths.add(w.toDouble());
      }
    }

    // Convert absolute widths to percentages
    final total = colWidths.fold(0.0, (sum, w) => sum + w);
    final percentWidths = total > 0
      ? colWidths.map((w) => (w / total) * 100.0).toList()
      : <double>[];

    return DocTable(rows: rows, columnWidthsPercent: percentWidths);
  }

  static DocImage? _extractInlineImage(
    XmlElement element,
    Map<String, String> relsMap,
    Map<String, Uint8List> imageMap,
  ) {
    final blip = element.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'blip')
        .firstOrNull;
    if (blip == null) return null;
    final rId = blip.getAttribute('r:embed');
    if (rId == null) return null;

    final target = relsMap[rId];
    if (target == null) return null;

    final normalized = 'word/${target.replaceAll('../', '')}';
    final bytes = imageMap[normalized];
    if (bytes == null) return null;

    final ext = element.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == 'ext')
        .firstOrNull;
    double? width;
    double? height;
    if (ext != null) {
      final cx = int.tryParse(ext.getAttribute('cx') ?? '0') ?? 0;
      final cy = int.tryParse(ext.getAttribute('cy') ?? '0') ?? 0;
      if (cx > 0 && cy > 0) {
        width = cx / 12700.0;
        height = cy / 12700.0;
      }
    }

    return DocImage(bytes: bytes, widthPt: width, heightPt: height);
  }

  static Map<String, String> _parseRelationships(XmlDocument doc) {
    final map = <String, String>{};
    for (final rel in doc.findAllElements('Relationship')) {
      final id = rel.getAttribute('Id');
      final target = rel.getAttribute('Target');
      if (id != null && target != null) map[id] = target;
    }
    return map;
  }

  static Map<String, DocParagraphStyle> _parseStyles(XmlDocument doc) {
    final map = <String, DocParagraphStyle>{};
    for (final style in doc.findAllElements('w:style')) {
      final styleId = style.getAttribute('w:styleId') ?? '';
      if (styleId.isEmpty) continue;
      final pPr = style.findElements('w:pPr').firstOrNull;
      final rPr = style.findElements('w:rPr').firstOrNull;
      final baseStyle = _parseParagraphProperties(pPr, {}, {});

      // Parse heading color from rPr
      Color? headingColor;
      if (rPr != null) {
        final colorEl = rPr.findElements('w:color').firstOrNull;
        final colorHex = colorEl?.getAttribute('w:val');
        if (colorHex != null && colorHex != 'auto' && colorHex.length == 6) {
          headingColor = Color(int.parse('FF$colorHex', radix: 16));
        }
      }

      map[styleId] = baseStyle.copyWith(headingColor: headingColor);
    }
    return map;
  }

  static Map<String, _NumberingDef> _parseNumbering(XmlDocument doc) {
    final abstractMap = <String, Map<int, String>>{};
    for (final an in doc.findAllElements('w:abstractNum')) {
      final id = an.getAttribute('w:abstractNumId') ?? '';
      if (id.isEmpty) continue;

      final levelGlyphs = <int, String>{};
      for (final lvl in an.findElements('w:lvl')) {
        final ilvl = int.tryParse(lvl.getAttribute('w:ilvl') ?? '0') ?? 0;
        final lvlText = lvl.findElements('w:lvlText')
          .firstOrNull?.getAttribute('w:val') ?? '•';
        levelGlyphs[ilvl] = lvlText;
      }
      abstractMap[id] = levelGlyphs;
    }

    final map = <String, _NumberingDef>{};
    for (final num in doc.findAllElements('w:num')) {
      final numId = num.getAttribute('w:numId') ?? '';
      final abstractNumId = num.findElements('w:abstractNumId')
              .firstOrNull
              ?.getAttribute('w:val') ??
          '';
      if (numId.isEmpty) continue;

      final levelGlyphs = abstractMap[abstractNumId] ?? {0: '•'};
      map[numId] = _NumberingDef(
        isBullet: levelGlyphs.values.any((g) => g != '1' && !RegExp(r'^\d+$').hasMatch(g)),
        currentNumber: 1,
        levelGlyphs: levelGlyphs,
      );
    }
    return map;
  }

  static double _headingFontSize(DocHeadingLevel level) {
    switch (level) {
      case DocHeadingLevel.h1:
        return 26;
      case DocHeadingLevel.h2:
        return 22;
      case DocHeadingLevel.h3:
        return 18;
      case DocHeadingLevel.h4:
        return 16;
      case DocHeadingLevel.h5:
        return 14;
      case DocHeadingLevel.h6:
        return 13;
      default:
        return 11;
    }
  }

  static String _mapFontFamily(String font) {
    const map = {
      'Calibri': 'Roboto',
      'Arial': 'Roboto',
      'Times New Roman': 'serif',
      'Courier New': 'monospace',
      'Georgia': 'serif',
      'Verdana': 'Roboto',
      'Helvetica': 'Roboto',
    };
    return map[font] ?? 'Roboto';
  }

  static Color _highlightColor(String n) {
    switch (n) {
      case 'yellow':
        return const Color(0xFFFFFF00);
      case 'green':
        return const Color(0xFF00FF00);
      case 'cyan':
        return const Color(0xFF00FFFF);
      case 'red':
        return const Color(0xFFFF0000);
      case 'blue':
        return const Color(0xFF0000FF);
      default:
        return const Color(0xFFFFFFFF);
    }
  }
}

class _NumberingDef {
  final bool isBullet;
  final int currentNumber;
  final Map<int, String> levelGlyphs;

  _NumberingDef({
    required this.isBullet,
    this.currentNumber = 1,
    required this.levelGlyphs,
  });
}

extension XmlElementIteratorExtension on Iterable<XmlElement> {
  XmlElement? get firstOrNull => isEmpty ? null : first;
}
