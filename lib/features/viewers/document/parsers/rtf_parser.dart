import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/doc_models.dart';

class RtfParser {
  static Future<DocDocument> parse(String filePath) async {
    return compute(_parseIsolate, filePath);
  }

  static DocDocument _parseIsolate(String filePath) {
    final text = File(filePath).readAsStringSync();

    // Simplified RTF parser: extract plain text and keep basic breaks
    final buffer = StringBuffer();
    final metadata = <String>[];

    // Convert simple control words to markers
    var cleaned = text.replaceAllMapped(RegExp(r'\\par[d]?'), (_) => '\\n');
    cleaned = cleaned.replaceAll(RegExp(r'\\line'), '\\n');
    cleaned = cleaned.replaceAll(RegExp(r'[{}]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+-?\d*\s?'), '');

    for (final line in cleaned.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        buffer.writeln();
      } else {
        buffer.write(trimmed);
        buffer.writeln();
      }
    }

    final paragraph = DocParagraph(
      runs: [
        DocRun(text: buffer.toString().trim(), style: const DocRunStyle())
      ],
      style: const DocParagraphStyle(),
    );

    return DocDocument(blocks: [paragraph], pageSetup: const DocPageSetup());
  }
}
