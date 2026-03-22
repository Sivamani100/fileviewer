import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/doc_models.dart';

class OdtParser {
  static Future<DocDocument> parse(String filePath) async {
    return compute(_parseIsolate, filePath);
  }

  static DocDocument _parseIsolate(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    final contentFile = archive.findFile('content.xml');
    if (contentFile == null) {
      throw Exception('Invalid ODT: content.xml missing');
    }

    final docXml =
        XmlDocument.parse(utf8.decode(contentFile.content as List<int>));
    final body = docXml.findAllElements('office:body').firstOrNull;
    final textBody = body?.findElements('office:text').firstOrNull;
    if (textBody == null) {
      throw Exception('Invalid ODT: office:text not found');
    }

    final blocks = <DocBlock>[];
    for (final node in textBody.children.whereType<XmlElement>()) {
      switch (node.name.local) {
        case 'h':
          final level =
              int.tryParse(node.getAttribute('outline-level') ?? '1') ?? 1;
          final style = DocParagraphStyle(
              headingLevel: DocHeadingLevel.values[(level.clamp(1, 6))]);
          final runs = <DocRun>[
            DocRun(
                text: node.text,
                style: DocRunStyle(
                    fontSizePt: _headingSize(style.headingLevel), bold: true))
          ];
          blocks.add(DocParagraph(runs: runs, style: style));
          break;
        case 'p':
          final runs = <DocRun>[];
          if (node.text.trim().isEmpty) {
            blocks.add(DocParagraph(
                runs: [],
                style: const DocParagraphStyle(
                    spacingBeforePt: 8, spacingAfterPt: 8)));
          } else {
            runs.add(DocRun(text: node.text, style: const DocRunStyle()));
            blocks.add(
                DocParagraph(runs: runs, style: const DocParagraphStyle()));
          }
          break;
        case 'list':
          for (final li in node.findAllElements('text:list-item')) {
            final text = li.text.trim();
            final style = DocParagraphStyle(
                listType: DocListType.bullet, listLevel: 0, spacingAfterPt: 4);
            final run = DocRun(text: text, style: const DocRunStyle());
            blocks.add(DocParagraph(runs: [run], style: style));
          }
          break;
      }
    }

    return DocDocument(blocks: blocks, pageSetup: const DocPageSetup());
  }

  static double _headingSize(DocHeadingLevel level) {
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
}

extension _NullableXmlElement on Iterable<XmlElement> {
  XmlElement? get firstOrNull => isEmpty ? null : first;
}
